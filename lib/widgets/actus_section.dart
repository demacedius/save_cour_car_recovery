// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:save_your_car/models/article.dart';
import 'package:save_your_car/services/news_service.dart';
import 'package:save_your_car/screens/article_detail_screen.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';


class ActusSection extends StatefulWidget {
  const ActusSection({super.key});

  @override
  State<ActusSection> createState() => _ActusSectionState();
}

class _ActusSectionState extends State<ActusSection> {
  List<ArticleData> articles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final news = await NewsService.getAutomotiveNews();
      if (mounted) {
        setState(() {
          articles = news;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280, // Hauteur augmentée pour plus de contenu
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FigmaColors.primaryMain),
              ),
            )
          : articles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune actualité disponible',
                        style: FigmaTextStyles().textMRegular.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: articles.length,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    return GestureDetector(
                      onTap: () => _openArticleDetail(context, article),
                      child: Container(
                        width: 280,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: FigmaColors.neutral10,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image de l'article
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox(
                                height: 120,
                                width: double.infinity,
                                child: article.imageUrl.isNotEmpty
                                    ? Image.network(
                                        article.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Image.asset(
                                          "assets/images/actus.jpeg",
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Image.asset(
                                        "assets/images/actus.jpeg",
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Header avec source et temps
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    article.source,
                                    style: FigmaTextStyles().captionXSMedium.copyWith(
                                      color: FigmaColors.primaryMain,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  article.timeAgo,
                                  style: FigmaTextStyles().captionXSMedium.copyWith(
                                    color: FigmaColors.neutral70,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Titre
                            Text(
                              article.title,
                              style: FigmaTextStyles().textLBold,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            
                            // Description
                            Expanded(
                              child: Text(
                                article.description,
                                style: FigmaTextStyles().captionSRegular.copyWith(
                                  color: FigmaColors.neutral80,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _openArticleDetail(BuildContext context, ArticleData article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailScreen(article: article),
      ),
    );
  }

}