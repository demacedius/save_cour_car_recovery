# API Profil Utilisateur

## Endpoints de gestion du profil utilisateur

### 1. Récupérer le profil utilisateur

```http
GET /api/user/profile
Authorization: Bearer <token>
```

**Réponse réussie :**
```json
{
  "message": "Profil récupéré avec succès",
  "user": {
    "id": 1,
    "email": "jean.dupont@email.com",
    "full_name": "Jean Dupont",
    "first_name": "Jean",
    "last_name": "Dupont",
    "phone": "+33612345678",
    "profile_picture": "uploads/profile_pictures/user_1_1234567890.jpg"
  }
}
```

### 2. Mettre à jour le profil utilisateur

```http
PUT /api/user/profile
Authorization: Bearer <token>
Content-Type: application/json
```

**Corps de la requête :**
```json
{
  "first_name": "Jean",
  "last_name": "Dupont",
  "email": "jean.dupont@newemail.com",
  "phone": "+33612345678"
}
```

**Réponse réussie :**
```json
{
  "message": "Profil mis à jour avec succès"
}
```

### 3. Changer le mot de passe

```http
PUT /api/user/password
Authorization: Bearer <token>
Content-Type: application/json
```

**Corps de la requête :**
```json
{
  "current_password": "ancienMotDePasse",
  "new_password": "nouveauMotDePasse"
}
```

**Réponse réussie :**
```json
{
  "message": "Mot de passe changé avec succès"
}
```

### 4. Upload photo de profil

```http
POST /api/user/profile-picture
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Paramètres :**
- `profile_picture`: fichier image (JPEG, PNG, GIF)
- Taille max: 5MB

**Réponse réussie :**
```json
{
  "message": "Photo de profil uploadée avec succès",
  "profile_picture": "uploads/profile_pictures/user_1_1234567890.jpg"
}
```

### 5. Servir les photos de profil

```http
GET /uploads/profile_pictures/user_1_1234567890.jpg
```

## Codes d'erreur

- **400 Bad Request**: Données invalides ou manquantes
- **401 Unauthorized**: Token manquant ou invalide
- **409 Conflict**: Email déjà utilisé par un autre utilisateur
- **500 Internal Server Error**: Erreur serveur

## Validation des données

### Email
- Format valide requis
- Unique dans le système
- Exemple: `user@example.com`

### Téléphone (optionnel)
- Format français accepté
- Exemples: `0612345678`, `+33612345678`

### Mot de passe
- Minimum 6 caractères
- Hashé avec bcrypt

### Photo de profil
- Types acceptés: JPEG, PNG, GIF
- Taille maximum: 5MB
- Stockage: `uploads/profile_pictures/`

## Notes techniques

1. **Authentification**: Toutes les routes requièrent un token JWT valide
2. **CORS**: Configuré pour accepter les requêtes depuis le frontend Flutter
3. **Stockage**: Les photos sont stockées localement dans `uploads/profile_pictures/`
4. **Base de données**: Nouvelles colonnes ajoutées automatiquement à la table `users`
5. **Migration**: Script SQL disponible dans `migrations/add_user_profile_fields.sql`

## Structure de la table users mise à jour

```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    phone VARCHAR(20),
    profile_picture TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Exemples d'utilisation avec curl

### Récupérer le profil
```bash
curl -X GET http://localhost:3334/api/user/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

### Mettre à jour le profil
```bash
curl -X PUT http://localhost:3334/api/user/profile \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Jean",
    "last_name": "Dupont",
    "email": "jean.dupont@email.com",
    "phone": "+33612345678"
  }'
```

### Upload photo de profil
```bash
curl -X POST http://localhost:3334/api/user/profile-picture \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "profile_picture=@/path/to/photo.jpg"
```