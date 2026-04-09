import psycopg2
import os

# 1. Configuration de la connexion à la base de données 
DB_CONFIG = {
    "dbname": "aviation_db",
    "user": "admin",
    "password": "password123",
    "host": "localhost",
    "port": "5432"
}

# 2. Ordre d'insertion pour respecter les clés étrangères
# Format : ("Nom_de_la_table", "Nom_du_fichier.csv")
TABLES_ORDER = [
    # Niveau 0
    ("Pays", "csvs/Pays.csv"),
    ("Categories", "csvs/Categories.csv"),
    ("Types", "csvs/Types.csv"),
    ("Airports", "csvs/Airports.csv"),
    
    # Niveau 1
    ("Villes", "csvs/Villes.csv"),
    ("Compagnies", "csvs/Compagnies.csv"),
    
    # Niveau 2
    ("Avions", "csvs/Avions.csv"),
    ("VolsReferences", "csvs/VolsReferences.csv"),
    
    # Niveau 3
    ("Vols", "csvs/Vols.csv")
]

def import_csv_to_postgres():
    conn = None
    try:
        # Connexion à la base de données
        print("Connexion à la base de données PostgreSQL...")
        conn = psycopg2.connect(**DB_CONFIG)
        cur = conn.cursor()

        for table_name, csv_file in TABLES_ORDER:
            # Vérification de l'existence du fichier
            if not os.path.exists(csv_file):
                print(f"ERREUR : Le fichier {csv_file} est introuvable. Importation annulée pour cette table.")
                continue

            print(f"Importation en cours pour la table '{table_name}' depuis {csv_file}...")
            
            # Ouverture du fichier CSV et exécution de la commande COPY
            with open(csv_file, 'r', encoding='utf-8') as f:
                # COPY pour insérer des CSV
                # HEADER précise que la première ligne contient le nom des colonnes
                sql_copy_query = f"COPY {table_name} FROM STDIN WITH CSV HEADER DELIMITER ','"
                
                try:
                    cur.copy_expert(sql_copy_query, f)
                    conn.commit() # On valide la transaction pour cette table
                    print(f"Succès : Données insérées dans '{table_name}'.")
                except Exception as table_error:
                    conn.rollback() # En cas d'erreur, on annule l'insertion pour cette table
                    print(f"ERREUR SQL lors de l'insertion dans '{table_name}': {table_error}")

        # Fermeture du curseur
        cur.close()
        print("\nProcessus d'importation terminé !")

    except psycopg2.OperationalError as e:
        print(f"\nErreur de connexion à la base de données : \n{e}")
    except Exception as e:
        print(f"\nErreur inattendue : \n{e}")
    finally:
        # Fermeture propre de la connexion quoi qu'il arrive
        if conn is not None:
            conn.close()
            print("Déconnexion de la base de données.")

if __name__ == "__main__":
    import_csv_to_postgres()