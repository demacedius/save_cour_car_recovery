class ArticleData {
  final String title;
  final String description;
  final String imageUrl;
  final String url;
  final String source;
  final DateTime publishedAt;
  final String? content; // Contenu complet de l'article

  ArticleData({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.url,
    required this.source,
    required this.publishedAt,
    this.content,
  });

  factory ArticleData.fromJson(Map<String, dynamic> json) {
    return ArticleData(
      title: json['title'] ?? 'Titre non disponible',
      description: json['description'] ?? 'Description non disponible',
      imageUrl: json['urlToImage'] ?? '',
      url: json['url'] ?? '',
      source: json['source']?['name'] ?? 'Source inconnue',
      publishedAt: DateTime.tryParse(json['publishedAt'] ?? '') ?? DateTime.now(),
      content: json['content'], // NewsAPI fournit parfois le contenu
    );
  }

  // Getter pour afficher la date de façon lisible
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(publishedAt);

    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    } else {
      return 'Maintenant';
    }
  }
}