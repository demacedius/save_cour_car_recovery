#!/bin/bash

echo "🔧 Compilation du backend Go..."

# Télécharger les dépendances
go mod tidy

# Vérifier la syntaxe
echo "📝 Vérification de la syntaxe..."
go vet ./...

# Compiler le projet
echo "🏗️ Compilation..."
go build -o bin/server .

if [ $? -eq 0 ]; then
    echo "✅ Compilation réussie! Exécutable créé: bin/server"
else
    echo "❌ Erreur de compilation"
    exit 1
fi

echo ""
echo "🚀 Pour démarrer le serveur:"
echo "   ./bin/server"
echo ""
echo "📖 Pour voir la documentation des API:"
echo "   cat API_PROFILE.md"