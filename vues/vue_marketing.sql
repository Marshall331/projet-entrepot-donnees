-- 1. Vue pour la Dimension Avion Marketing (Création de la Catégorie)
CREATE OR REPLACE VIEW Vue_Dim_Avion_Marketing AS
SELECT 
    CodeA,
    Modele,
    Constructeur,
    CASE 
        WHEN NbrSieges <= 150 THEN 'Avion Régional'
        ELSE 'Avion de Ligne'
    END AS CategorieAppareil
FROM Avions;

-- 2. Vue pour la Dimension Trajet (Simplifiée selon le DDL disponible)
CREATE OR REPLACE VIEW Vue_Dim_Trajet AS
SELECT 
    vr.CodeVR,
    vr.Frequence,
    -- Branche Départ
    ad.CodeAP AS CodeAP_Dep,
    ad.NomAP AS NomAP_Dep,
    -- Branche Arrivée
    aa.CodeAP AS CodeAP_Arr,
    aa.NomAP AS NomAP_Arr
FROM VolsReferences vr
JOIN Airports ad ON vr.CodeAP_Dep = ad.CodeAP
JOIN Airports aa ON vr.CodeAP_Arr = aa.CodeAP;

-- 3. Vue pour la Dimension Temps Marketing (Avec Saisonnalité)
CREATE OR REPLACE VIEW Vue_Dim_Temps_Marketing AS
SELECT DISTINCT
    DateV,
    EXTRACT(YEAR FROM DateV) AS Annee,
    EXTRACT(MONTH FROM DateV) AS Mois,
    EXTRACT(QUARTER FROM DateV) AS Trimestre,
    CASE 
        WHEN EXTRACT(MONTH FROM DateV) IN (12, 1, 2) THEN 'Hiver'
        WHEN EXTRACT(MONTH FROM DateV) IN (3, 4, 5) THEN 'Printemps'
        WHEN EXTRACT(MONTH FROM DateV) IN (6, 7, 8) THEN 'Eté'
        WHEN EXTRACT(MONTH FROM DateV) IN (9, 10, 11) THEN 'Automne'
    END AS Saison
FROM Vols;

-- 4. Vue pour la Table de Faits Marketing
CREATE OR REPLACE VIEW Vue_Fact_Marketing AS
SELECT 
    CodeA,
    CodeVR,
    DateV,
    NbrPassagersEco,
    NbrPassagersAffaire,
    NbrPassagersPremiere,
    (NbrPassagersEco + NbrPassagersAffaire + NbrPassagersPremiere) AS TotalPassagers,
    1 AS TotalVols  
FROM Vols;