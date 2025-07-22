import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:save_your_car/models/article.dart';
import 'package:save_your_car/config/api_keys.dart';

class NewsService {
  static const String baseUrl = 'https://newsapi.org/v2';

  static Future<List<ArticleData>> getAutomotiveNews() async {
    // Si pas de clé API configurée, retourner des articles de démonstration
    if (!ApiKeys.isNewsApiConfigured) {
      print('📰 Clé API NewsAPI non configurée, utilisation des articles de démo');
      return _getMockArticles();
    }

    final url = Uri.parse(
      '$baseUrl/everything?'
      'q=(automobile OR voiture OR auto) AND (tesla OR bmw OR mercedes OR peugeot OR renault OR citroën OR audi OR volkswagen OR ford OR "voiture électrique" OR "salon auto" OR "essai auto")&'
      'language=fr&'
      'sortBy=publishedAt&'
      'pageSize=15&'
      'domains=largus.fr,caradisiac.com,auto-moto.com,autoplus.fr,automobile-magazine.fr&'
      'apiKey=${ApiKeys.newsApiKey}'
    );

    try {
      print('📰 Récupération actualités automobile...');
      final response = await http.get(url);
      
      print('📰 Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List articles = data['articles'] ?? [];
        
        print('📰 Articles trouvés: ${articles.length}');
        
        return articles
            .map((article) => ArticleData.fromJson(article))
            .where((article) => article.imageUrl.isNotEmpty) // Filtrer les articles avec images
            .take(8) // Limiter à 8 articles
            .toList();
      } else {
        print('❌ Erreur API NewsAPI: ${response.statusCode}');
        print('Response: ${response.body}');
        return _getMockArticles();
      }
    } catch (e) {
      print('Erreur récupération actualités: $e');
      return _getMockArticles();
    }
  }

  // Articles de démonstration si l'API ne fonctionne pas
  static List<ArticleData> _getMockArticles() {
    return [
      ArticleData(
        title: 'Tesla Model Y : la version Performance mise à jour avec 514 km d\'autonomie',
        description: 'Tesla améliore son SUV électrique phare avec de nouvelles batteries plus efficaces et des performances rehaussées. Le 0 à 100 km/h s\'effectue désormais en 3,7 secondes, soit 0,3 seconde de mieux que la précédente génération.',
        imageUrl: '',
        url: 'https://www.largus.fr/actualite-automobile/tesla-model-y-performance-2024',
        source: 'L\'Argus',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ArticleData(
        title: 'Peugeot e-3008 : le SUV électrique qui veut détrôner le Tesla Model Y',
        description: 'Avec ses 700 km d\'autonomie annoncée et son prix attractif, le nouveau e-3008 de Peugeot ambitionne de bousculer la hiérarchie des SUV électriques. Découverte de ce modèle prometteur basé sur la plateforme STLA Medium.',
        imageUrl: '',
        url: 'https://www.caradisiac.com/peugeot-e-3008-essai-2024',
        source: 'Caradisiac',
        publishedAt: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      ArticleData(
        title: 'BMW iX2 vs Mercedes EQA : duel de SUV électriques compacts',
        description: 'Comparatif détaillé entre les deux SUV électriques premium. Autonomie, performances, équipements, prix : nous avons testé ces deux rivaux allemands sur tous les terrains pour déterminer le meilleur choix.',
        imageUrl: '',
        url: 'https://www.auto-moto.com/comparatif/bmw-ix2-mercedes-eqa-2024',
        source: 'Auto Moto',
        publishedAt: DateTime.now().subtract(const Duration(hours: 8)),
      ),
      ArticleData(
        title: 'Renault Rafale Hybride : l\'essai du nouveau SUV coupé français',
        description: 'Renault dévoile sa nouvelle arme de séduction avec le Rafale, un SUV coupé hybride de 300 ch. Notre essai complet révèle un véhicule abouti qui pourrait bien redorer le blason de la marque au losange.',
        imageUrl: '',
        url: 'https://www.autoplus.fr/renault/rafale/essai-renault-rafale-2024',
        source: 'Auto Plus',
        publishedAt: DateTime.now().subtract(const Duration(hours: 12)),
      ),
      ArticleData(
        title: 'Salon de Genève 2024 : toutes les nouveautés automobiles dévoilées',
        description: 'Retour sur les temps forts du Salon de l\'automobile de Genève avec les principales nouveautés : concept-cars futuristes, lancements de production et innovations technologiques qui dessinent l\'avenir de la mobilité.',
        imageUrl: '',
        url: 'https://www.automobile-magazine.fr/salon-geneve-2024-nouveautes',
        source: 'Automobile Magazine',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ArticleData(
        title: 'Voitures électriques : recharge ultra-rapide 350 kW, le tournant arrive',
        description: 'L\'infrastructure de recharge s\'accélère avec l\'arrivée des bornes 350 kW sur les autoroutes françaises. Ionity, Fastned et Total Energies déploient massivement cette technologie qui permet de récupérer 300 km d\'autonomie en 10 minutes.',
        imageUrl: '',
        url: 'https://www.largus.fr/actualite-automobile/recharge-rapide-350kw-2024',
        source: 'L\'Argus',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }
}