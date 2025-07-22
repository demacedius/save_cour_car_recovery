class StripeConfig {
  // Clés de test Stripe
  static const String publishableKey = 'pk_test_51RXTcPPcMvKX08Wx0PhvZ6dFbwpogOfNXAzapkkRbXgFDxy29Yb2SVNklHlXm3ktlyKNjCWgIoyEqOvVUYmctds600573lehqN';
  
  // La clé secrète ne doit JAMAIS être dans le code client
  // Elle sera uniquement utilisée côté backend
  
  // URLs du backend
  static const String baseUrl = 'http://192.168.1.231:3334'; // À adapter selon votre configuration
  
  // Prix des abonnements (en centimes)
  static const int monthlyPriceInCents = 999; // 9,99€
  static const int yearlyPriceInCents = 2999; // 29,99€
  
  // IDs des prix Stripe (remplacez par les vrais IDs de votre dashboard)
  static const String monthlyPriceId = 'price_1RY34DPcMvKX08WxVEcPQcGM'; // Remplacer par l'ID réel du prix mensuel
  static const String yearlyPriceId = 'price_1RY37QPcMvKX08WxNHTKBpJe';   // Remplacer par l'ID réel du prix annuel
  
  // Configuration de l'essai gratuit
  static const int freeTrialDays = 3;
}