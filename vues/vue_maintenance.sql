-- 1. Vue pour la Dimension Avion (Dénormalisation)
CREATE OR REPLACE VIEW Vue_Dim_Avion AS
SELECT 
    a.CodeA,
    a.Modele,
    a.Constructeur,
    a.NbrSieges,
    a.ChargeMax,
    a.PoidsAVide,
    a.AnneeAchat,
    t.NomTy AS TypeAvion,
    c.CodeC,
    c.NomC,
    p.NomP AS PaysSiege
FROM Avions a
JOIN Types t ON a.CodeTy = t.CodeTy
JOIN Compagnies c ON a.CodeC = c.CodeC
JOIN Pays p ON c.CodeP = p.CodeP;

-- 2. Vue pour la Dimension Vol de Référence
CREATE OR REPLACE VIEW Vue_Dim_VolReference AS
SELECT 
    CodeVR,
    Frequence,
    Distance AS DistanceBase,  
    HeureDepart,
    HeureArrivee,
    cat.NomCa AS CategorieVol 
FROM VolsReferences vr
JOIN Categories cat ON vr.CodeCa = cat.CodeCa;

-- 3. Vue pour la Dimension Temps (Générée à partir des dates de vols)
CREATE OR REPLACE VIEW Vue_Dim_Temps AS
SELECT DISTINCT
    DateV,
    EXTRACT(YEAR FROM DateV) AS Annee,
    EXTRACT(MONTH FROM DateV) AS Mois,
    EXTRACT(QUARTER FROM DateV) AS Trimestre
FROM Vols;

-- 4. Vue pour la Table de Faits Maintenance (Calculs des mesures)
CREATE OR REPLACE VIEW Vue_Fact_Maintenance AS
SELECT 
    v.CodeA,
    v.CodeVR,
    v.DateV,
    v.DureeVol AS DureeTotalVol,
    (v.ChargeTotale + v.ChargeKerosene) AS PoidsTotalVol, 
    vr.Distance AS DistanceTotal,  
    (a.NbrSieges - (v.NbrPassagersEco + v.NbrPassagersAffaire + v.NbrPassagersPremiere)) AS SiegesLibres
FROM Vols v
JOIN Avions a ON v.CodeA = a.CodeA
JOIN VolsReferences vr ON v.CodeVR = vr.CodeVR;