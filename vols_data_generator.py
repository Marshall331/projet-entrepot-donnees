import pandas as pd
import random
from datetime import datetime, timedelta

# 1. Chargement des données de référence (vos fichiers existants)
try:
    avions_df = pd.read_csv('csvs/Avions.csv')
    vols_ref_df = pd.read_csv('csvs/VolsReferences.csv')
except FileNotFoundError:
    # Pour s'adapter si les fichiers sont dans le même dossier
    avions_df = pd.read_csv('Avions.csv')
    vols_ref_df = pd.read_csv('VolsReferences.csv')

# 2. Paramètres de génération
DATE_DEBUT = datetime(2024, 1, 1)
DATE_FIN = datetime(2025, 12, 31)
NB_JOURS = (DATE_FIN - DATE_DEBUT).days
PROBABILITE_VOL_PAR_JOUR = 0.3  # Un avion a 30% de chance de voler chaque jour

nouveaux_vols = []

# 3. Fonction pour générer une date aléatoire entre deux dates
def random_date(start, end):
    return start + timedelta(days=random.randint(0, (end - start).days))

# 4. Génération des vols
# On boucle sur chaque avion de la flotte
for _, avion in avions_df.iterrows():
    code_avion = avion['CodeA']
    compagnie = avion['CodeC']
    sieges_max = avion['NbrSieges']
    poids_vide = avion['PoidsAVide']
    charge_max = avion['ChargeMax']
    
    # On trouve les vols de référence possibles pour cette compagnie
    vols_possibles = vols_ref_df[vols_ref_df['CodeC'] == compagnie]['CodeVR'].tolist()
    
    # Si la compagnie n'a pas de vol de référence, on passe
    if not vols_possibles:
        continue

    # On simule l'activité de cet avion sur la période de 2 ans
    for jour in range(NB_JOURS):
        # L'avion ne vole pas tous les jours
        if random.random() > PROBABILITE_VOL_PAR_JOUR:
            continue
            
        date_vol = DATE_DEBUT + timedelta(days=jour)
        code_vr = random.choice(vols_possibles)
        
        # Répartition des passagers (Taux de remplissage aléatoire entre 50% et 100%)
        taux_remplissage = random.uniform(0.5, 1.0)
        passagers_total = int(sieges_max * taux_remplissage)
        
        # On divise les passagers dans les 3 classes
        nbr_eco = int(passagers_total * 0.8) # 80% en éco
        nbr_affaire = int(passagers_total * 0.15) # 15% en affaire
        nbr_premiere = passagers_total - nbr_eco - nbr_affaire # Le reste en première
        
        # Durée du vol aléatoire (entre 1h et 12h)
        duree_vol = round(random.uniform(1.0, 12.0), 2)
        
        # Charge de kérosène (dépend de la durée, grossièrement)
        charge_kerosene = round(duree_vol * random.uniform(2.5, 4.0), 2)
        
        # Charge Totale (passagers + bagages + fret)
        # On compte environ 100kg par passager (0.1 tonne) + fret aléatoire
        charge_totale = round((passagers_total * 0.1) + random.uniform(1.0, 10.0), 2)
        
        # Sécurité : on s'assure que le tout ne dépasse pas la ChargeMax de l'avion
        if (poids_vide + charge_kerosene + charge_totale) > charge_max:
            charge_totale = charge_max - poids_vide - charge_kerosene - 0.5 # Marge de sécurité
            charge_totale = round(max(1.0, charge_totale), 2) # Pour éviter un chiffre négatif
            
        nouveaux_vols.append({
            'CodeA': code_avion,
            'CodeVR': code_vr,
            'DateV': date_vol.strftime('%Y-%m-%d'),
            'DureeVol': duree_vol,
            'NbrPassagersEco': nbr_eco,
            'NbrPassagersAffaire': nbr_affaire,
            'NbrPassagersPremiere': nbr_premiere,
            'ChargeKerosene': charge_kerosene,
            'ChargeTotale': charge_totale
        })

# 5. Création du DataFrame et sauvegarde
df_vols_generes = pd.DataFrame(nouveaux_vols)

# On garde les clés primaires uniques (un avion ne peut pas faire le même vol de référence 2x le même jour)
df_vols_generes = df_vols_generes.drop_duplicates(subset=['CodeA', 'CodeVR', 'DateV'])

# On trie par date pour faire propre
df_vols_generes = df_vols_generes.sort_values(by=['DateV', 'CodeA'])

# Sauvegarde dans un nouveau fichier CSV
nom_fichier_sortie = 'Vols.csv'
df_vols_generes.to_csv(nom_fichier_sortie, index=False)

print(f"Génération terminée ! {len(df_vols_generes)} vols ont été créés et enregistrés dans '{nom_fichier_sortie}'.")