import psycopg2
import os
import pandas as pd
import random
from datetime import datetime, timedelta
import io

# 1. Configuration de la connexion
DB_CONFIG = {
    "dbname": "aviation_db",
    "user": "admin",
    "password": "password123",
    "host": "localhost",
    "port": "5432"
}

# 2. Fichiers statiques (Dimensions)
TABLES_STATIQUES = [
    ("Pays", "csvs/Pays.csv"),
    ("Categories", "csvs/Categories.csv"),
    ("Types", "csvs/Types.csv"),
    ("Airports", "csvs/Airports.csv"),
    ("Villes", "csvs/Villes.csv"),
    ("Compagnies", "csvs/Compagnies.csv"),
    ("Avions", "csvs/Avions.csv"),
    ("VolsReferences", "csvs/VolsReferences.csv")
]

def executer_script_sql(conn, chemin_fichier):
    print(f"\n--- Réinitialisation de la base avec {chemin_fichier} ---")
    with open(chemin_fichier, 'r', encoding='utf-8') as f:
        sql = f.read()
    cur = conn.cursor()
    cur.execute(sql)
    conn.commit()
    cur.close()
    print("Base de données réinitialisée avec succès.")

def importer_csv_statiques(conn):
    print("\n--- Importation des tables de dimensions ---")
    cur = conn.cursor()
    for table_name, csv_file in TABLES_STATIQUES:
        if not os.path.exists(csv_file):
            print(f"ATTENTION: Fichier {csv_file} introuvable.")
            continue
        
        with open(csv_file, 'r', encoding='utf-8') as f:
            sql_copy = f"COPY {table_name} FROM STDIN WITH CSV HEADER DELIMITER ','"
            cur.copy_expert(sql_copy, f)
            conn.commit()
            print(f"Succès: {table_name} chargée.")
    cur.close()

def generer_et_importer_vols(conn):
    print("\n--- Génération dynamique des vols (2024-2025) ---")
    
    # Lecture des sources pour la cohérence
    avions_df = pd.read_csv('csvs/Avions.csv')
    vols_ref_df = pd.read_csv('csvs/VolsReferences.csv')
    
    DATE_DEBUT = datetime(2024, 1, 1)
    NB_JOURS = 730 # 2 ans
    nouveaux_vols = []

    for _, avion in avions_df.iterrows():
        vols_possibles = vols_ref_df[vols_ref_df['CodeC'] == avion['CodeC']]['CodeVR'].tolist()
        if not vols_possibles: continue

        for jour in range(NB_JOURS):
            if random.random() > 0.3: # 30% de chance de voler par jour
                continue
                
            passagers_total = int(avion['NbrSieges'] * random.uniform(0.5, 1.0))
            nbr_eco = int(passagers_total * 0.8)
            nbr_aff = int(passagers_total * 0.15)
            nbr_prem = passagers_total - nbr_eco - nbr_aff
            
            duree = round(random.uniform(1.0, 12.0), 2)
            kerosene = round(duree * random.uniform(2.5, 4.0), 2)
            charge_tot = round((passagers_total * 0.1) + random.uniform(1.0, 10.0), 2)
            
            # Sécurité poids
            if (avion['PoidsAVide'] + kerosene + charge_tot) > avion['ChargeMax']:
                charge_tot = max(1.0, avion['ChargeMax'] - avion['PoidsAVide'] - kerosene - 0.5)

            nouveaux_vols.append([
                avion['CodeA'], random.choice(vols_possibles), 
                (DATE_DEBUT + timedelta(days=jour)).strftime('%Y-%m-%d'),
                duree, nbr_eco, nbr_aff, nbr_prem, kerosene, round(charge_tot, 2)
            ])

    # Création d'un buffer en mémoire (comme un faux fichier CSV)
    df_vols = pd.DataFrame(nouveaux_vols, columns=[
        'CodeA', 'CodeVR', 'DateV', 'DureeVol', 'NbrPassagersEco', 
        'NbrPassagersAffaire', 'NbrPassagersPremiere', 'ChargeKerosene', 'ChargeTotale'
    ])
    df_vols = df_vols.drop_duplicates(subset=['CodeA', 'CodeVR', 'DateV'])
    
    buffer = io.StringIO()
    df_vols.to_csv(buffer, index=False, header=True)
    buffer.seek(0)
    
    # Importation massive
    cur = conn.cursor()
    cur.copy_expert("COPY Vols FROM STDIN WITH CSV HEADER DELIMITER ','", buffer)
    conn.commit()
    cur.close()
    print(f"Succès: {len(df_vols)} vols générés et insérés avec succès dans la table des faits !")

def main():
    conn = None
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        executer_script_sql(conn, 'script_creation.sql')
        importer_csv_statiques(conn)
        generer_et_importer_vols(conn)
        print("\nPipeline ETL terminé avec succès !")
    except Exception as e:
        print(f"Erreur : {e}")
        if conn: conn.rollback()
    finally:
        if conn: conn.close()

if __name__ == "__main__":
    main()