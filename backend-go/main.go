package main

import (
	"backend-go/database"
	"backend-go/handlers"
	"backend-go/middleware"
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	// Charger les variables d'environnement
	if err := godotenv.Load(); err != nil {
		log.Println("Fichier .env non trouvé, utilisation des variables d'environnement système")
	}

	// Connexion à la base de données
	database.Connect()

	// Initialiser Gin
	r := gin.Default()

	// Middleware CORS pour Flutter
	r.Use(func(c *gin.Context) {
		c.Header("Access-Control-Allow-Origin", "*")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Authorization")
		
		if c.Request.Method == "OPTIONS" {
			c.AbortWithStatus(204)
			return
		}
		
		c.Next()
	})

	// Routes publiques
	r.POST("/register", handlers.Register)
	r.POST("/login", handlers.Login)
	r.POST("/register-with-vehicle", handlers.RegisterWithVehicle)
	r.POST("/vehicles/from-plate", handlers.GetVehicleFromPlate)
	r.POST("/forgot-password", handlers.ForgotPassword)
	r.POST("/reset-password", handlers.ResetPassword)

	// Routes protégées
	protected := r.Group("/")
	protected.Use(middleware.AuthMiddleware())
	{
		// Routes véhicules
		protected.POST("/vehicles", handlers.CreateVehicle)
		protected.GET("/vehicles", handlers.GetUserVehicles)
		protected.PUT("/vehicles/update-brand-images", handlers.UpdateVehicleBrandImages)
		protected.PUT("/vehicles/:id", handlers.UpdateVehicle)
		protected.DELETE("/vehicles/:id", handlers.DeleteVehicle)
		protected.POST("/vehicles/:id/transfer", handlers.TransferVehicle)
		
		// Routes documents
		protected.POST("/documents", handlers.UploadDocument)
		protected.GET("/vehicles/:vehicle_id/documents", handlers.GetVehicleDocuments)
		protected.GET("/documents/:document_id/download", handlers.DownloadDocument)
		protected.DELETE("/documents/:document_id", handlers.DeleteDocument)
		
		// Routes profil utilisateur
		protected.GET("/api/user/profile", handlers.GetUserProfile)
		protected.PUT("/api/user/profile", handlers.UpdateUserProfile)
		protected.PUT("/api/user/password", handlers.UpdatePassword)
		protected.POST("/api/user/profile-picture", handlers.UploadProfilePicture)
		
		// Routes rendez-vous
		protected.POST("/appointments", handlers.CreateAppointment)
		protected.GET("/appointments", handlers.GetUserAppointments)
		protected.GET("/appointments/:id", handlers.GetAppointment)
		protected.PUT("/appointments/:id", handlers.UpdateAppointment)
		protected.PUT("/appointments/:id/validate", handlers.ValidateAppointment)
		protected.DELETE("/appointments/:id", handlers.DeleteAppointment)
		
		// Routes Stripe (abonnements)
		protected.POST("/create-subscription", handlers.CreateSubscription)
		protected.GET("/subscription-status", handlers.GetSubscriptionStatus)
		protected.POST("/cancel-subscription", handlers.CancelSubscription)
	}

	// Routes statiques pour les photos de profil
	r.Static("/uploads/profile_pictures", "./uploads/profile_pictures")

	// Route de santé
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "OK", "message": "Backend Go fonctionne"})
	})

	// Démarrer le serveur
	port := os.Getenv("PORT")
	if port == "" {
		port = "3334"  // Utiliser 3334 pour correspondre au frontend
	}

	log.Printf("Serveur démarré sur le port %s", port)
	r.Run(":" + port)
	//triger CI
}