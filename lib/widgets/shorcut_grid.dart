import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/theme/responsive_helper.dart';
import 'package:save_your_car/widgets/title_section.dart';
import 'package:save_your_car/screens/garage/garage_list_screen.dart';
import 'package:save_your_car/screens/progress_screen.dart';
import 'package:save_your_car/screens/conseils_screen.dart';

class ShortcutGrid extends StatefulWidget {
  const ShortcutGrid({super.key});

  @override
  State<ShortcutGrid> createState() => _ShortcutGridState();
}

class _ShortcutGridState extends State<ShortcutGrid> {
  final textStyles = FigmaTextStyles();

  @override
  Widget build(BuildContext context) {
    final shortcuts = [
      {"text": "Trouver un garage proche de chez moi", "icon": Icons.garage_outlined},
      {"text": "Nos Conseils", "icon": Icons.lightbulb_outline},
      {"text": "Ma progression", "icon": Icons.trending_up_outlined},
      {"text": "Pièces", "icon": Icons.build_outlined},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: "Catégorie"),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: ResponsiveHelper.isMobile(context) ? 12 : 16,
            crossAxisSpacing: ResponsiveHelper.isMobile(context) ? 12 : 16,
            childAspectRatio: ResponsiveHelper.isMobile(context) ? 0.9 : 0.8,
          ),
          itemCount: shortcuts.length,
          itemBuilder: (context, index) {
            final shortcut = shortcuts[index];
            final text = shortcut["text"] as String;
            final icon = shortcut["icon"] as IconData;
            final bool isDisable = text == "Pièces";
            
            return Opacity(
              opacity: isDisable ? 0.5 : 1,
              child: GestureDetector(
                onTap: isDisable ? null : () => _handleShortcutTap(context, text),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDisable ? FigmaColors.neutral30 : FigmaColors.neutral10,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isDisable ? null : [
                      BoxShadow(
                        color: FigmaColors.neutral20,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(ResponsiveHelper.responsivePadding(context, mobile: 12, tablet: 16, desktop: 20)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: ResponsiveHelper.isMobile(context) ? 40 : 48,
                        width: ResponsiveHelper.isMobile(context) ? 40 : 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          color: isDisable ? FigmaColors.neutral50 : FigmaColors.primaryMain,
                        ),
                        child: Icon(
                          icon,
                          size: ResponsiveHelper.isMobile(context) ? 20 : 24,
                          color: isDisable ? Colors.grey.shade600 : FigmaColors.neutral00,
                        ),
                      ),
                      SizedBox(height: ResponsiveHelper.isMobile(context) ? 8 : 12),
                      Text(
                        text,
                        textAlign: TextAlign.center,
                        style: textStyles.textLSemiBold.copyWith(
                          fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                          color: isDisable ? FigmaColors.neutral60 : FigmaColors.neutral90,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _handleShortcutTap(BuildContext context, String shortcutName) {
    switch (shortcutName) {
      case "Trouver un garage proche de chez moi":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const GarageListScreen(),
          ),
        );
        break;
      case "Nos Conseils":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ConseilsScreen(),
          ),
        );
        break;
      case "Ma progression":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProgressScreen(),
          ),
        );
        break;
      default:
        break;
    }
  }
}
