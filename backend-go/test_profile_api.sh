#!/bin/bash

# Script de test pour les API de profil utilisateur
# Usage: ./test_profile_api.sh [token]

BASE_URL="http://localhost:3334"
TOKEN=${1:-"YOUR_JWT_TOKEN_HERE"}

echo "🧪 Test des API de profil utilisateur"
echo "Base URL: $BASE_URL"
echo "Token: ${TOKEN:0:20}..."
echo ""

# Test 1: Récupérer le profil
echo "📋 Test 1: Récupération du profil utilisateur"
curl -s -X GET "$BASE_URL/api/user/profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq '.'
echo ""

# Test 2: Mettre à jour le profil
echo "✏️ Test 2: Mise à jour du profil utilisateur"
curl -s -X PUT "$BASE_URL/api/user/profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "first_name": "Jean",
    "last_name": "Dupont",
    "email": "jean.dupont@test.com",
    "phone": "+33612345678"
  }' | jq '.'
echo ""

# Test 3: Vérifier la mise à jour
echo "🔍 Test 3: Vérification de la mise à jour"
curl -s -X GET "$BASE_URL/api/user/profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | jq '.'
echo ""

# Test 4: Changement de mot de passe (optionnel - nécessite le mot de passe actuel)
echo "🔐 Test 4: Changement de mot de passe (test avec faux mot de passe)"
curl -s -X PUT "$BASE_URL/api/user/password" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "current_password": "wrongpassword",
    "new_password": "newpassword123"
  }' | jq '.'
echo ""

# Test 5: Test de santé du serveur
echo "❤️ Test 5: Santé du serveur"
curl -s -X GET "$BASE_URL/health" | jq '.'
echo ""

echo "✅ Tests terminés!"
echo ""
echo "💡 Pour tester l'upload de photo de profil:"
echo "curl -X POST $BASE_URL/api/user/profile-picture \\"
echo "  -H \"Authorization: Bearer $TOKEN\" \\"
echo "  -F \"profile_picture=@/path/to/your/photo.jpg\""