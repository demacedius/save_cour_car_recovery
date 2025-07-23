# Backend Go - Save Your Car

## Installation

1. **Installer Go** (version 1.21+)
2. **Cloner et naviguer vers le dossier**
   ```bash
   cd backend-go
   ```

3. **Installer les dépendances**
   ```bash
   go mod tidy
   ```

4. **Configurer la base de données**
   - Modifier le fichier `.env` avec vos paramètres PostgreSQL
   - La base de données `save_your_car` doit exister

5. **Démarrer le serveur**
   ```bash
   go run main.go
   ```

## Configuration

Modifier le fichier `.env` :
```
DB_HOST=localhost
DB_PORT=5432
DB_USER=postgres
DB_PASSWORD=votre_mot_de_passe
DB_NAME=save_your_car
JWT_SECRET=votre-clé-secrète-très-longue
PORT=3333
```

## API Endpoints

### Authentification
- `POST /register` - Créer un compte
- `POST /login` - Se connecter
- `POST /register-with-vehicle` - Créer un compte avec véhicule

### Véhicules
- `POST /vehicles/from-plate` - Récupérer infos véhicule par plaque
- `GET /vehicles` - Lister les véhicules de l'utilisateur (protégé)
- `POST /vehicles` - Créer un véhicule (protégé)
- `PUT /vehicles/:id` - Modifier un véhicule (protégé)
- `DELETE /vehicles/:id` - Supprimer un véhicule (protégé)

### Santé
- `GET /health` - Vérifier l'état du serveur

## Avantages par rapport à AdonisJS

✅ **Hash bcrypt fiable** - Pas de problème de vérification  
✅ **Performance** - Plus rapide et moins de mémoire  
✅ **Simplicité** - Code plus direct et lisible  
✅ **Stabilité** - Moins de dépendances, moins de bugs  
✅ **Compilation** - Détection d'erreurs à la compilation