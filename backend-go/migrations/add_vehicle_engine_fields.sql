-- Migration pour ajouter engine_type et displacement à la table vehicles
-- Date: 2026-01-24

ALTER TABLE vehicles
ADD COLUMN IF NOT EXISTS engine_type VARCHAR(50),
ADD COLUMN IF NOT EXISTS displacement VARCHAR(20);

-- Index pour améliorer les recherches par type de moteur
CREATE INDEX IF NOT EXISTS idx_vehicles_engine_type ON vehicles(engine_type);

-- Commentaires
COMMENT ON COLUMN vehicles.engine_type IS 'Type de moteur (Essence, Diesel, Électrique, Hybride)';
COMMENT ON COLUMN vehicles.displacement IS 'Cylindrée du moteur (ex: 1.6L, 2.0L)';
