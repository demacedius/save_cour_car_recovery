# Étape 1: Build de l'application Go
FROM golang:1.22-alpine AS builder

# Définir le répertoire de travail
WORKDIR /app

# Copier les fichiers de gestion des dépendances
COPY go.mod go.sum ./

# Télécharger les dépendances
RUN go mod download

# Copier le reste du code source de l'application
COPY . .

# Compiler l'application pour une exécution statique
# CGO_ENABLED=0 pour désactiver CGO et créer un binaire statique
# -o /app/main pour spécifier le chemin de sortie du binaire
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o /app/main .

# Étape 2: Création de l'image finale légère
FROM alpine:latest

# Définir le répertoire de travail
WORKDIR /app

# Copier le binaire compilé depuis l'étape de build
COPY --from=builder /app/main .

# Copier les migrations pour qu'elles soient accessibles par le binaire
COPY ./migrations ./migrations

# Exposer le port sur lequel l'application écoute
EXPOSE 3334

# Commande pour lancer l'application
CMD ["/app/main"]
