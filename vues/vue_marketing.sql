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

-- 2. Vue pour la Dimension Trajet (Dénormalisation massive Départ/Arrivée)
CREATE OR REPLACE VIEW Vue_Dim_Trajet AS
SELECT 
    vr.CodeVR,
    vr.Frequence,
    -- Branche Départ
    ad.CodeAP AS CodeAP_Dep,
    ad.NomAP AS NomAP_Dep,
    vd.NomV AS VilleDep,
    pd.NomP AS PaysDep,
    -- Branche Arrivée
    aa.CodeAP AS CodeAP_Arr,
    aa.NomAP AS NomAP_Arr,
    va.NomV AS VilleArr,
    pa.NomP AS PaysArr
FROM VolsReferences vr
JOIN Airports ad ON vr.CodeAP_Depart = ad.CodeAP
JOIN Villes vd ON ad.CodeV = vd.CodeV
JOIN Pays pd ON vd.CodeP = pd.CodeP
JOIN Airports aa ON vr.CodeAP_Arrivee = aa.CodeAP
JOIN Villes va ON aa.CodeV = va.CodeV
JOIN Pays pa ON va.CodeP = pa.CodeP;

-- 3. Vue pour la Table de Faits Marketing
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
