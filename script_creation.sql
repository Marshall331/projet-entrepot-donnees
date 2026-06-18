-- 1. Nettoyage de la base de données
DROP TABLE IF EXISTS Vols CASCADE;
DROP TABLE IF EXISTS VolsReferences CASCADE;
DROP TABLE IF EXISTS Avions CASCADE;
DROP TABLE IF EXISTS Compagnies CASCADE;
DROP TABLE IF EXISTS Villes CASCADE;
DROP TABLE IF EXISTS Airports CASCADE;
DROP TABLE IF EXISTS Pays CASCADE;
DROP TABLE IF EXISTS Categories CASCADE;
DROP TABLE IF EXISTS Types CASCADE;

-- ==============================================================================
-- 2. Création des tables de niveau 0
-- ==============================================================================

CREATE TABLE Pays (
    CodeP CHAR(2) PRIMARY KEY,
    NomP VARCHAR(50) NOT NULL,
    PopulationP BIGINT CHECK (PopulationP > 0)
);

CREATE TABLE Categories (
    CodeCa SERIAL PRIMARY KEY,
    NomCa VARCHAR(30) NOT NULL
);

CREATE TABLE Types (
    CodeTy SERIAL PRIMARY KEY,
    NomTy VARCHAR(30) NOT NULL
);

CREATE TABLE Airports (
    CodeAP CHAR(3) PRIMARY KEY,
    NomAP VARCHAR(50) NOT NULL,
    TailleHub INTEGER CHECK (TailleHub > 0)
);

-- ==============================================================================
-- 3. Création des tables avec clés étrangères
-- ==============================================================================

CREATE TABLE Villes (
    CodeVi VARCHAR(5) PRIMARY KEY,
    NomVi VARCHAR(50) NOT NULL,
    PopulationVi BIGINT CHECK (PopulationVi > 0),
    CodeP CHAR(2) NOT NULL,
    FOREIGN KEY (CodeP) REFERENCES Pays(CodeP)
);

CREATE TABLE Compagnies (
    CodeC CHAR(2) PRIMARY KEY,
    NomC VARCHAR(50) NOT NULL,
    CodeP CHAR(2) NOT NULL,
    CodeAP CHAR(3) NOT NULL,
    FOREIGN KEY (CodeP) REFERENCES Pays(CodeP),
    FOREIGN KEY (CodeAP) REFERENCES Airports(CodeAP)
);

CREATE TABLE Avions (
    CodeA CHAR(6) PRIMARY KEY CHECK (CodeA ~ '^[A-Za-z]{2}[0-9]{4}$'),  
    Modele VARCHAR(8) NOT NULL,
    Constructeur VARCHAR(50) NOT NULL,
    NbrSieges INTEGER NOT NULL CHECK (NbrSieges >= 0),
    ChargeMax REAL NOT NULL CHECK (ChargeMax > 0),
    PoidsAVide REAL NOT NULL CHECK (PoidsAVide > 0),
    AnneeAchat INTEGER, 
    CodeTy INTEGER NOT NULL,
    CodeC CHAR(2) NOT NULL,
    FOREIGN KEY (CodeTy) REFERENCES Types(CodeTy),
    FOREIGN KEY (CodeC) REFERENCES Compagnies(CodeC),
    CHECK (PoidsAVide < ChargeMax) 
);

CREATE TABLE VolsReferences (
    CodeVR VARCHAR(8) PRIMARY KEY,
    Frequence VARCHAR(20) NOT NULL,
    Distance INTEGER NOT NULL CHECK (Distance > 0),
    HeureDepart TIME NOT NULL,
    HeureArrivee TIME NOT NULL,
    CodeAP_Dep CHAR(3) NOT NULL,
    CodeAP_Arr CHAR(3) NOT NULL,
    CodeCa INTEGER NOT NULL,
    CodeC CHAR(2) NOT NULL,
    FOREIGN KEY (CodeAP_Dep) REFERENCES Airports(CodeAP),
    FOREIGN KEY (CodeAP_Arr) REFERENCES Airports(CodeAP),
    FOREIGN KEY (CodeCa) REFERENCES Categories(CodeCa),
    FOREIGN KEY (CodeC) REFERENCES Compagnies(CodeC),
    CHECK (Frequence IN ('Quotidien', 'Quotidien semaine', 'Quotidien week end', 'Hebdomadaire', 'Mensuel', 'Spécifique'))
);

CREATE TABLE Vols (
    CodeA CHAR(6) NOT NULL,
    CodeVR VARCHAR(8) NOT NULL,
    DateV DATE NOT NULL,
    DureeVol REAL NOT NULL CHECK (DureeVol >= 0),
    NbrPassagersEco INTEGER NOT NULL DEFAULT 0 CHECK (NbrPassagersEco >= 0),
    NbrPassagersAffaire INTEGER NOT NULL DEFAULT 0 CHECK (NbrPassagersAffaire >= 0),
    NbrPassagersPremiere INTEGER NOT NULL DEFAULT 0 CHECK (NbrPassagersPremiere >= 0),
    ChargeKerosene REAL NOT NULL CHECK (ChargeKerosene > 0),
    ChargeTotale REAL NOT NULL CHECK (ChargeTotale > 0),
    PRIMARY KEY (CodeA, CodeVR, DateV), 
    FOREIGN KEY (CodeA) REFERENCES Avions(CodeA),
    FOREIGN KEY (CodeVR) REFERENCES VolsReferences(CodeVR)
);

-- ==============================================================================
-- 4. CRÉATION DES VUES POUR LE MAGASIN DE DONNÉES N°1 (MAINTENANCE)
-- ==============================================================================

-- 4.1. Vue pour la Dimension Avion (Dénormalisation)
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

-- 4.2. Vue pour la Dimension Vol de Référence
CREATE OR REPLACE VIEW Vue_Dim_VolReference AS
SELECT 
    vr.CodeVR,
    vr.Frequence,
    vr.Distance AS DistanceBase, 
    vr.HeureDepart,
    vr.HeureArrivee,
    cat.NomCa AS CategorieVol 
FROM VolsReferences vr
JOIN Categories cat ON vr.CodeCa = cat.CodeCa;

-- 4.3. Vue pour la Dimension Temps (Maintenance)
CREATE OR REPLACE VIEW Vue_Dim_Temps AS
SELECT DISTINCT
    DateV,
    EXTRACT(YEAR FROM DateV) AS Annee,
    EXTRACT(MONTH FROM DateV) AS Mois,
    EXTRACT(QUARTER FROM DateV) AS Trimestre
FROM Vols;

-- 4.4. Vue pour la Table de Faits Maintenance (Calculs des mesures)
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

-- ==============================================================================
-- 5. CRÉATION DES VUES POUR LE MAGASIN DE DONNÉES N°2 (MARKETING)
-- ==============================================================================

-- 5.1. Vue pour la Dimension Avion Marketing (Création de la Catégorie)
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

-- 5.2. Vue pour la Dimension Trajet 
CREATE OR REPLACE VIEW Vue_Dim_Trajet AS
SELECT 
    vr.CodeVR,
    vr.Frequence,
    ad.CodeAP AS CodeAP_Dep,
    ad.NomAP AS NomAP_Dep,
    aa.CodeAP AS CodeAP_Arr,
    aa.NomAP AS NomAP_Arr
FROM VolsReferences vr
JOIN Airports ad ON vr.CodeAP_Dep = ad.CodeAP
JOIN Airports aa ON vr.CodeAP_Arr = aa.CodeAP;

-- 5.3. Vue pour la Dimension Temps Marketing (Avec Saisonnalité)
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

-- 5.4. Vue pour la Table de Faits Marketing
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