-- 1. Nettoyage de la base de données (si les tables existent déjà)
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
-- 2. Création des tables de niveau 0 (sans clés étrangères)
-- ==============================================================================

CREATE TABLE Pays (
    CodeP CHAR(2) PRIMARY KEY,
    NomP VARCHAR(50) NOT NULL,
    PopulationP BIGINT CHECK (PopulationP > 0)
);

CREATE TABLE Categories (
    CodeCa SERIAL PRIMARY KEY, -- SERIAL permet un Numéro automatique
    NomCa VARCHAR(30) NOT NULL
);

CREATE TABLE Types (
    CodeTy SERIAL PRIMARY KEY, -- SERIAL permet un Numéro automatique
    NomTy VARCHAR(30) NOT NULL
);

CREATE TABLE Airports (
    CodeAP CHAR(3) PRIMARY KEY,
    NomAP VARCHAR(50) NOT NULL,
    TailleHub INTEGER CHECK (TailleHub > 0)
);

-- ==============================================================================
-- 3. Création des tables avec clés étrangères (respect des dépendances)
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
    CodeA CHAR(6) PRIMARY KEY CHECK (CodeA ~ '^[A-Za-z]{2}[0-9]{4}$'), -- 2 lettres et 4 chiffres
    Modele VARCHAR(8) NOT NULL,
    Constructeur VARCHAR(50) NOT NULL,
    NbrSieges INTEGER NOT NULL CHECK (NbrSieges >= 0),
    ChargeMax REAL NOT NULL CHECK (ChargeMax > 0),
    PoidsAVide REAL NOT NULL CHECK (PoidsAVide > 0),
    AnneeAchat INTEGER, -- Note: La contrainte "inférieur à l'année en cours" requiert un Trigger en PostgreSQL
    CodeTy INTEGER NOT NULL,
    CodeC CHAR(2) NOT NULL,
    FOREIGN KEY (CodeTy) REFERENCES Types(CodeTy),
    FOREIGN KEY (CodeC) REFERENCES Compagnies(CodeC),
    CHECK (PoidsAVide < ChargeMax) -- Règle métier implicite
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
    CHECK (Frequence IN ('Quotidien', 'Quotidien semaine', 'Quotidien week end', 'Hebdomadaire', 'Mensuel', 'Spécifique')),
    CHECK (HeureArrivee > HeureDepart)
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
    PRIMARY KEY (CodeA, CodeVR, DateV), -- Clé primaire composite
    FOREIGN KEY (CodeA) REFERENCES Avions(CodeA),
    FOREIGN KEY (CodeVR) REFERENCES VolsReferences(CodeVR)
    -- Note: La vérification que la somme des passagers <= NbrSieges de l'avion nécessite un Trigger en PostgreSQL
);