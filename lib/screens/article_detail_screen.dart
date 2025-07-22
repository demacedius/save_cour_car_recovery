import 'package:flutter/material.dart';
import 'package:save_your_car/models/article.dart';
import 'package:save_your_car/services/article_content_service.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

class ArticleDetailScreen extends StatefulWidget {
  final ArticleData article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  String? fullContent;
  bool isLoadingContent = false;

  @override
  void initState() {
    super.initState();
    _loadFullContent();
  }

  Future<void> _loadFullContent() async {
    if (widget.article.content != null && widget.article.content!.isNotEmpty) {
      setState(() {
        fullContent = widget.article.content;
      });
      return;
    }

    setState(() {
      isLoadingContent = true;
    });

    try {
      // Essayer de récupérer le contenu complet
      final content = await ArticleContentService.getArticleContent(widget.article.url);
      
      if (content != null && content.length > 200) {
        setState(() {
          fullContent = content;
          isLoadingContent = false;
        });
      } else {
        // Utiliser un contenu de demo si l'extraction échoue
        setState(() {
          fullContent = ArticleContentService.generateDemoContent(
            widget.article.title, 
            widget.article.description
          );
          isLoadingContent = false;
        });
      }
    } catch (e) {
      setState(() {
        fullContent = ArticleContentService.generateDemoContent(
          widget.article.title, 
          widget.article.description
        );
        isLoadingContent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // App Bar avec image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: FigmaColors.primaryMain,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.article.imageUrl.isNotEmpty
                      ? Image.network(
                          widget.article.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: FigmaColors.neutral30,
                            child: const Icon(
                              Icons.article,
                              size: 64,
                              color: FigmaColors.neutral70,
                            ),
                          ),
                        )
                      : Container(
                          color: FigmaColors.neutral30,
                          child: const Icon(
                            Icons.article,
                            size: 64,
                            color: FigmaColors.neutral70,
                          ),
                        ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.open_in_browser, color: Colors.white),
                  onPressed: () => _openInBrowser(context),
                ),
              ),
            ],
          ),
          
          // Contenu de l'article
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec source et date
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: FigmaColors.primaryFocus,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.article.source,
                          style: FigmaTextStyles().captionSMedium.copyWith(
                            color: FigmaColors.primaryMain,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(widget.article.publishedAt),
                        style: FigmaTextStyles().captionSRegular.copyWith(
                          color: FigmaColors.neutral70,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Titre
                  Text(
                    widget.article.title,
                    style: FigmaTextStyles().headingLBold.copyWith(
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description/Résumé
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FigmaColors.neutral10,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: FigmaColors.primaryFocus,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.article_outlined,
                              size: 20,
                              color: FigmaColors.primaryMain,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Résumé de l\'article',
                              style: FigmaTextStyles().textMBold.copyWith(
                                color: FigmaColors.primaryMain,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.article.description,
                          style: FigmaTextStyles().textMRegular.copyWith(
                            height: 1.5,
                            color: FigmaColors.neutral90,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Contenu complet de l'article
                  _buildArticleContent(),
                  
                  const SizedBox(height: 24),
                  
                  // Informations supplémentaires
                  _buildInfoSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations',
            style: FigmaTextStyles().textMBold,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Source', widget.article.source),
          _buildInfoRow('Publié le', _formatFullDate(widget.article.publishedAt)),
          _buildInfoRow('Temps de lecture', '2-3 minutes'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: FigmaTextStyles().textMSemiBold.copyWith(
                color: FigmaColors.neutral70,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: FigmaTextStyles().textMSemiBold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  String _formatFullDate(DateTime date) {
    // Formatage simple sans locale pour éviter l'erreur
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  Widget _buildArticleContent() {
    if (isLoadingContent) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: FigmaColors.neutral10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(FigmaColors.primaryMain),
              ),
              SizedBox(height: 16),
              Text(
                'Chargement du contenu complet...',
                style: TextStyle(
                  color: FigmaColors.neutral70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (fullContent != null && fullContent!.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: FigmaColors.neutral20,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.article,
                  size: 24,
                  color: FigmaColors.primaryMain,
                ),
                const SizedBox(width: 12),
                Text(
                  'Article complet',
                  style: FigmaTextStyles().textLBold.copyWith(
                    color: FigmaColors.primaryMain,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _openInBrowser(context),
                  icon: const Icon(
                    Icons.open_in_browser,
                    color: FigmaColors.primaryMain,
                  ),
                  tooltip: 'Ouvrir sur ${widget.article.source}',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              fullContent!,
              style: FigmaTextStyles().textMRegular.copyWith(
                height: 1.6,
                color: FigmaColors.neutral90,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FigmaColors.primaryFocus,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: FigmaColors.primaryMain,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Source: ${widget.article.source}',
                      style: FigmaTextStyles().captionSMedium.copyWith(
                        color: FigmaColors.primaryMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Fallback si pas de contenu
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            FigmaColors.primaryMain.withOpacity(0.1),
            FigmaColors.primaryFocus,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.open_in_browser,
            size: 48,
            color: FigmaColors.primaryMain,
          ),
          const SizedBox(height: 16),
          Text(
            'Contenu non disponible',
            style: FigmaTextStyles().textLBold.copyWith(
              color: FigmaColors.primaryMain,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le contenu complet n\'est pas disponible. Cliquez pour ouvrir l\'article sur ${widget.article.source}',
            textAlign: TextAlign.center,
            style: FigmaTextStyles().textMSemiBold.copyWith(
              color: FigmaColors.neutral80,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openInBrowser(context),
              icon: const Icon(Icons.launch),
              label: const Text('Ouvrir l\'article'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FigmaColors.primaryMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInBrowser(BuildContext context) async {
    if (widget.article.url.isNotEmpty) {
      try {
        final uri = Uri.parse(widget.article.url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Impossible d\'ouvrir l\'article')),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erreur lors de l\'ouverture')),
          );
        }
      }
    }
  }
}