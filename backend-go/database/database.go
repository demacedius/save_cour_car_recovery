package database

import (
	"database/sql"
	"fmt"
	"log"
	"os"

	_ "github.com/lib/pq"
)

var DB *sql.DB

func Connect() {
	host := os.Getenv("DB_HOST")
	port := os.Getenv("DB_PORT")
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")

	log.Printf("Config DB: host=%s port=%s user=%s dbname=%s", host, port, user, dbname)

	psqlInfo := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	var err error
	DB, err = sql.Open("postgres", psqlInfo)
	if err != nil {
		log.Fatal("Erreur connexion DB:", err)
	}

	if err = DB.Ping(); err != nil {
		log.Fatal("Erreur ping DB:", err)
	}

	log.Println("Connexion à la base de données réussie")
	createTables()
}

func createTables() {
	userTable := `
	CREATE TABLE IF NOT EXISTS users (
		id SERIAL PRIMARY KEY,
		email VARCHAR(255) UNIQUE NOT NULL,
		password VARCHAR(255) NOT NULL,
		full_name VARCHAR(255) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	vehicleTable := `
	CREATE TABLE IF NOT EXISTS vehicles (
		id SERIAL PRIMARY KEY,
		user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
		plate VARCHAR(50) NOT NULL,
		model VARCHAR(100) NOT NULL,
		brand VARCHAR(100) NOT NULL,
		year INTEGER,
		mileage INTEGER,
		technical_control_date TIMESTAMP,
		image_url TEXT,
		brand_image_url TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	documentTable := `
	CREATE TABLE IF NOT EXISTS documents (
		id SERIAL PRIMARY KEY,
		vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE CASCADE,
		user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
		name VARCHAR(255) NOT NULL,
		type VARCHAR(50) NOT NULL,
		description TEXT,
		file_path TEXT NOT NULL,
		file_name VARCHAR(255) NOT NULL,
		file_size BIGINT NOT NULL,
		mime_type VARCHAR(100) NOT NULL,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	appointmentTable := `
	CREATE TABLE IF NOT EXISTS appointments (
		id SERIAL PRIMARY KEY,
		user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
		vehicle_id INTEGER REFERENCES vehicles(id) ON DELETE SET NULL,
		garage_name VARCHAR(255) NOT NULL,
		garage_id VARCHAR(255),
		date TIMESTAMP NOT NULL,
		time VARCHAR(10) NOT NULL,
		service VARCHAR(255) NOT NULL,
		description TEXT,
		status VARCHAR(50) DEFAULT 'pending',
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	if _, err := DB.Exec(userTable); err != nil {
		log.Fatal("Erreur création table users:", err)
	}

	if _, err := DB.Exec(vehicleTable); err != nil {
		log.Fatal("Erreur création table vehicles:", err)
	}

	if _, err := DB.Exec(documentTable); err != nil {
		log.Fatal("Erreur création table documents:", err)
	}

	if _, err := DB.Exec(appointmentTable); err != nil {
		log.Fatal("Erreur création table appointments:", err)
	}

	// Table des abonnements Stripe
	subscriptionTable := `
	CREATE TABLE IF NOT EXISTS subscriptions (
		id SERIAL PRIMARY KEY,
		user_id INTEGER UNIQUE REFERENCES users(id) ON DELETE CASCADE,
		stripe_customer_id VARCHAR(255) NOT NULL,
		stripe_subscription_id VARCHAR(255) UNIQUE NOT NULL,
		stripe_price_id VARCHAR(255) NOT NULL,
		status VARCHAR(50) NOT NULL,
		current_period_start TIMESTAMP NOT NULL,
		current_period_end TIMESTAMP NOT NULL,
		trial_start TIMESTAMP,
		trial_end TIMESTAMP,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	)`

	if _, err := DB.Exec(subscriptionTable); err != nil {
		log.Fatal("Erreur création table subscriptions:", err)
	}

	// Ajouter la colonne brand_image_url si elle n'existe pas
	alterVehicleTable := `
	ALTER TABLE vehicles 
	ADD COLUMN IF NOT EXISTS brand_image_url TEXT;`
	
	if _, err := DB.Exec(alterVehicleTable); err != nil {
		log.Printf("Info: Colonne brand_image_url déjà existante ou erreur: %v", err)
	}

	// Ajouter les nouvelles colonnes de profil utilisateur
	alterUserTable := `
	ALTER TABLE users 
	ADD COLUMN IF NOT EXISTS first_name VARCHAR(255),
	ADD COLUMN IF NOT EXISTS last_name VARCHAR(255),
	ADD COLUMN IF NOT EXISTS phone VARCHAR(20),
	ADD COLUMN IF NOT EXISTS profile_picture TEXT;`
	
	if _, err := DB.Exec(alterUserTable); err != nil {
		log.Printf("Info: Colonnes profil utilisateur déjà existantes ou erreur: %v", err)
	}

	log.Println("Tables créées avec succès")
}