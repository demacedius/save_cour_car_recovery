class ApiKeys {
  // 🔑 INSTRUCTIONS pour NewsAPI :
  // 1. Allez sur https://newsapi.org/register
  // 2. Créez un compte gratuit (1000 requêtes/jour)
  // 3. Copiez votre API key ici
  // 4. Remplacez 'YOUR_NEWS_API_KEY_HERE' par votre vraie clé
  
  static const String newsApiKey = '30457d0b9f114ef18d02a2e76f5eb674';
  
  // Exemple de vraie clé (ne pas utiliser celle-ci) :
  // static const String newsApiKey = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
  
  // Vérifier si la clé API est configurée
  static bool get isNewsApiConfigured => 
      newsApiKey != 'YOUR_NEWS_API_KEY_HERE' && newsApiKey.isNotEmpty;
}