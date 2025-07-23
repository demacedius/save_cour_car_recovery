-- Migration pour ajouter les champs de profil utilisateur
-- À exécuter si les colonnes n'existent pas déjà

-- Ajouter les nouvelles colonnes
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS first_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS last_name VARCHAR(255),
ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
ADD COLUMN IF NOT EXISTS profile_picture TEXT;

-- Optionnel: Mettre à jour les données existantes en divisant full_name
-- Ceci est un exemple, à adapter selon vos besoins
UPDATE users 
SET 
    first_name = SPLIT_PART(full_name, ' ', 1),
    last_name = CASE 
        WHEN ARRAY_LENGTH(STRING_TO_ARRAY(full_name, ' '), 1) > 1 
        THEN SUBSTRING(full_name FROM LENGTH(SPLIT_PART(full_name, ' ', 1)) + 2)
        ELSE NULL 
    END
WHERE first_name IS NULL AND full_name IS NOT NULL AND full_name != '';

-- Créer un index sur l'email pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Créer un index sur phone pour les recherches futures
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);

-- Ajouter une contrainte pour valider le format email
ALTER TABLE users 
ADD CONSTRAINT IF NOT EXISTS check_email_format 
CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$');

-- Ajouter une contrainte pour valider le format téléphone (optionnel)
ALTER TABLE users 
ADD CONSTRAINT IF NOT EXISTS check_phone_format 
CHECK (phone IS NULL OR phone ~* '^(\+33|0)[1-9][0-9]{8}$');