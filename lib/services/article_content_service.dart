// ignore_for_file: unused_import, avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

class ArticleContentService {
  static Future<String?> getArticleContent(String articleUrl) async {
    try {
      print('🔍 Récupération contenu article: $articleUrl');
      
      // Utiliser une API de scraping gratuite ou extraction simple
      final response = await http.get(
        Uri.parse(articleUrl),
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15',
        },
      );

      if (response.statusCode == 200) {
        final htmlContent = response.body;
        
        // Extraction simple du contenu principal
        final content = _extractMainContent(htmlContent);
        
        if (content.isNotEmpty) {
          print('✅ Contenu récupéré: ${content.length} caractères');
          return content;
        }
      }
      
      print('❌ Impossible de récupérer le contenu');
      return null;
    } catch (e) {
      print('Erreur récupération contenu: $e');
      return null;
    }
  }

  static String _extractMainContent(String html) {
    // Extraction simple du contenu textuel
    String content = html;
    
    // Supprimer les balises script et style
    content = content.replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true), '');
    content = content.replaceAll(RegExp(r'<style[^>]*>.*?</style>', dotAll: true), '');
    
    // Rechercher le contenu principal (patterns courants)
    final patterns = [
      RegExp(r'<article[^>]*>(.*?)</article>', dotAll: true),
      RegExp(r'<div[^>]*class="[^"]*content[^"]*"[^>]*>(.*?)</div>', dotAll: true),
      RegExp(r'<div[^>]*class="[^"]*article[^"]*"[^>]*>(.*?)</div>', dotAll: true),
      RegExp(r'<main[^>]*>(.*?)</main>', dotAll: true),
    ];
    
    for (final pattern in patterns) {
      final match = pattern.firstMatch(content);
      if (match != null) {
        content = match.group(1) ?? '';
        break;
      }
    }
    
    // Nettoyer les balises HTML
    content = content.replaceAll(RegExp(r'<[^>]*>'), ' ');
    
    // Nettoyer les espaces multiples
    content = content.replaceAll(RegExp(r'\s+'), ' ');
    
    // Décoder les entités HTML courantes
    content = content
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    
    return content.trim();
  }

  // Générer un contenu de demo réaliste si l'extraction échoue
  static String generateDemoContent(String title, String description) {
    final templates = [
      '''
$description

Dans le secteur automobile en constante évolution, cette actualité marque un tournant important pour l'industrie. Les constructeurs redoublent d'efforts pour répondre aux attentes des consommateurs en matière de performance, d'efficacité énergétique et de technologies embarquées.

## Points clés à retenir

• Innovation technologique au cœur de la stratégie
• Réponse aux enjeux environnementaux actuels  
• Positionnement concurrentiel renforcé
• Expérience utilisateur améliorée

## Impact sur le marché

Cette annonce s'inscrit dans une démarche plus large de transformation du secteur automobile. Les analystes prévoient que ces développements auront un impact significatif sur les ventes et la perception de la marque.

Les consommateurs bénéficieront directement de ces améliorations, notamment en termes de confort de conduite, de sécurité et d'efficacité énergétique.

## Perspectives d'avenir

L'industrie automobile continue sa mutation vers une mobilité plus durable et connectée. Cette actualité confirme les tendances observées ces derniers mois et annonce de nouveaux développements passionnants à venir.

Pour plus d'informations détaillées, consultez l'article complet sur le site de la source.
      ''',
    ];
    
    return templates[0];
  }
}