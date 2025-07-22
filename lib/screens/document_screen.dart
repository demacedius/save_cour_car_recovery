import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/theme/responsive_helper.dart';

class DocumentScreen extends StatelessWidget {
  const DocumentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = FigmaTextStyles();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header
            Container(
              height: ResponsiveHelper.isMobile(context) ? 140 : 162,
              width: double.infinity,
              decoration: const BoxDecoration(color: FigmaColors.neutral100),
              child: Stack(
                children: [
                  Positioned(
                    top: ResponsiveHelper.isMobile(context) ? 50 : 64,
                    left: ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Text(
                      "Documents",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 18, tablet: 20, desktop: 20),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: ResponsiveHelper.isMobile(context) ? -30 : -35,
                    right: ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
                    left: ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
                        ResponsiveHelper.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16),
                        ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
                        ResponsiveHelper.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16),
                      ),
                      child: Container(
                        height: ResponsiveHelper.isMobile(context) ? 44 : 48,
                        padding: EdgeInsets.symmetric(
                          horizontal: ResponsiveHelper.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16),
                        ),
                        decoration: BoxDecoration(
                          color: FigmaColors.neutral10,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12)),
                            Text(
                              "Chercher un document",
                              style: textStyle.textMRegular.copyWith(
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 20, tablet: 24, desktop: 24)),
            // Barre de recherche

            // Liste scrollable
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
                ),
                itemCount: 20,
                itemBuilder:
                    (context, index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: ResponsiveHelper.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16),
                      ),
                      child: const DocumentCard(),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DocumentCard extends StatelessWidget {
  const DocumentCard({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = FigmaTextStyles();

    return Container(
      padding: EdgeInsets.all(
        ResponsiveHelper.responsivePadding(context, mobile: 12, tablet: 16, desktop: 16),
      ),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: ResponsiveHelper.isMobile(context) ? 40 : 48,
            height: ResponsiveHelper.isMobile(context) ? 56 : 64,
            margin: EdgeInsets.only(
              right: ResponsiveHelper.responsiveSpacing(context, mobile: 12, tablet: 16, desktop: 16),
            ),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: AssetImage("assets/images/Document thumbnail.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date + Titre
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveHelper.responsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8),
                            vertical: ResponsiveHelper.responsiveSpacing(context, mobile: 3, tablet: 4, desktop: 4),
                          ),
                          decoration: BoxDecoration(
                            color: FigmaColors.primaryFocus,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "20/02/2025",
                            style: textStyle.captionSMedium.copyWith(
                              color: FigmaColors.primaryMain,
                            ),
                          ),
                        ),
                        SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8)),
                        Text(
                          "Révision 130 000 km",
                          style: textStyle.textLBold.copyWith(
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8)),
                Divider(indent: 0, thickness: 1, color: FigmaColors.neutral70),
                SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 6, tablet: 8, desktop: 8)),
                Text(
                  "Filtres à l'huiles · Filtres à air · Courroie de distribution",
                  style: textStyle.captionSMedium.copyWith(
                    color: FigmaColors.neutral70,
                    fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 11, tablet: 12, desktop: 12),
                  ),
                  maxLines: ResponsiveHelper.isMobile(context) ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
