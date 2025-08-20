class StripeConfig {
  // Clés de test Stripe
  static const String publishableKey = 'pk_live_51RXTbdBO0KsxxPgtHxNFTFVnlTg5Nt9QyvWxneDeZI9bFYG0MU6xK11UdyfEBG2pm998fSJUKImbRXBbpJ4qZ43m00im0wiDTH';
  
  // La clé secrète ne doit JAMAIS être dans le code client
  // Elle sera uniquement utilisée côté backend
  
  // URLs du backend
  static const String baseUrl = 'http://83.228.205.107:3334'; // À adapter selon votre configuration
  
  // Prix des abonnements (en centimes)
  static const int monthlyPriceInCents = 999; // 9,99€
  static const int yearlyPriceInCents = 2999; // 29,99€
  
  // IDs des prix Stripe (remplacez par les vrais IDs de votre dashboard)
  static const String monthlyPriceId = 'price_1RY34DPcMvKX08WxVEcPQcGM'; // Remplacer par l'ID réel du prix mensuel
  static const String yearlyPriceId = 'price_1RY37QPcMvKX08WxNHTKBpJe';   // Remplacer par l'ID réel du prix annuel
  
  // Configuration de l'essai gratuit
  static const int freeTrialDays = 3;
}