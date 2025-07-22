import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';


class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String selectedLanguage = 'fr';

  final List<Map<String, String>> languages = [
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'nl', 'name': 'Nederlands', 'flag': '🇳🇱'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaColors.neutral00,
      appBar: AppBar(
        backgroundColor: FigmaColors.neutral100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Langue',
          style: FigmaTextStyles().headingSBold.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _saveLanguage,
            child: Text(
              'Sauvegarder',
              style: FigmaTextStyles().textMSemiBold.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête informatif
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FigmaColors.primaryFocus,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.language,
                  color: FigmaColors.primaryMain,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choisissez votre langue',
                        style: FigmaTextStyles().textMBold.copyWith(
                          color: FigmaColors.primaryMain,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'L\'application sera redémarrée pour appliquer les changements',
                        style: FigmaTextStyles().captionSRegular.copyWith(
                          color: FigmaColors.primaryMain,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Liste des langues
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: languages.length,
              itemBuilder: (context, index) {
                final language = languages[index];
                final isSelected = selectedLanguage == language['code'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? FigmaColors.primaryFocus : FigmaColors.neutral10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? FigmaColors.primaryMain : FigmaColors.neutral20,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: ListTile(
                    leading: Text(
                      language['flag']!,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      language['name']!,
                      style: FigmaTextStyles().textMSemiBold.copyWith(
                        color: isSelected ? FigmaColors.primaryMain : FigmaColors.neutral90,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: FigmaColors.primaryMain,
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        selectedLanguage = language['code']!;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // Section informations
          Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FigmaColors.neutral10,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: FigmaColors.neutral20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: FigmaColors.neutral70,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Informations',
                      style: FigmaTextStyles().textMBold.copyWith(
                        color: FigmaColors.neutral90,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Les changements de langue nécessitent un redémarrage de l\'application\n'
                  '• Certaines fonctionnalités peuvent ne pas être entièrement traduites\n'
                  '• La langue par défaut est le français',
                  style: FigmaTextStyles().captionSRegular.copyWith(
                    color: FigmaColors.neutral70,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveLanguage() {
    // Ici vous pouvez ajouter la logique pour sauvegarder la langue
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Changer la langue',
            style: FigmaTextStyles().textLBold,
          ),
          content: Text(
            'L\'application va redémarrer pour appliquer la nouvelle langue. Voulez-vous continuer ?',
            style: FigmaTextStyles().textMRegular,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: FigmaTextStyles().textMSemiBold.copyWith(
                  color: FigmaColors.neutral70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Langue changée vers ${languages.firstWhere((l) => l['code'] == selectedLanguage)['name']}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: FigmaColors.primaryMain,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Confirmer',
                style: FigmaTextStyles().textMSemiBold,
              ),
            ),
          ],
        );
      },
    );
  }
}