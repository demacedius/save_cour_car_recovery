import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:url_launcher/url_launcher.dart';

class DemarchesScreen extends StatelessWidget {
  const DemarchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = FigmaTextStyles();

    return Scaffold(
      backgroundColor: FigmaColors.neutral00,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Header — même style que les autres écrans
            Container(
              height: 162,
              width: double.infinity,
              color: FigmaColors.neutral100,
              padding: const EdgeInsets.only(top: 68, left: 24, right: 24),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Démarches',
                    style: textStyle.headingSBold.copyWith(color: Colors.white),
                  ),
                  const Spacer(),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Changement de titulaire',
                      style: textStyle.headingMBold.copyWith(color: FigmaColors.neutral100),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Suivez les 3 étapes pour effectuer votre démarche carte grise.',
                      style: textStyle.textMRegular.copyWith(color: FigmaColors.neutral70),
                    ),
                    const SizedBox(height: 24),

                    // Étape 1
                    _StepCard(
                      stepNumber: 1,
                      title: 'Préparation de vos documents',
                      icon: Icons.folder_outlined,
                      color: FigmaColors.primaryMain,
                      children: [
                        _DocItem(label: 'Pièce d\'identité'),
                        _DocItem(label: 'Permis de conduire'),
                        _DocItem(label: 'Justificatif de domicile de moins de 6 mois'),
                        _DocItem(
                          label: 'Attestation d\'hébergement + carte d\'identité de l\'hébergeur',
                          isOptional: true,
                          optionalLabel: 'si location',
                        ),
                        _DocItem(label: 'Attestation d\'assurance du véhicule'),
                        _DocItem(label: 'Kbis', isOptional: true, optionalLabel: 'si société'),
                        _DocItem(
                          label: 'Pièce d\'identité du co-titulaire',
                          isOptional: true,
                          optionalLabel: 'si nécessaire',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Étape 2
                    _StepCard(
                      stepNumber: 2,
                      title: 'Documents de vente avec le vendeur',
                      icon: Icons.handshake_outlined,
                      color: Colors.orange,
                      children: [
                        _DocItem(label: 'Carte grise barrée, signée et datée par l\'ancien propriétaire'),
                        _DocItem(label: 'Certificat de cession rempli (Cerfa 15776) — signé par vendeur et acquéreur'),
                        _DocItem(
                          label: 'Contrôle technique de moins de 6 mois',
                          isOptional: true,
                          optionalLabel: 'si véhicule > 4 ans',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Étape 3
                    _StepCard(
                      stepNumber: 3,
                      title: 'Réception de la carte grise',
                      icon: Icons.local_shipping_outlined,
                      color: Colors.green,
                      children: [
                        _DocItem(
                          label: 'Votre carte grise définitive vous sera envoyée par courrier sécurisé à votre domicile sous quelques jours.',
                          isFreeText: true,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Bouton ANTS
                    _AntsButton(textStyle: textStyle),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FigmaColors.primaryFocus,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: FigmaColors.primaryMain.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: FigmaColors.primaryMain, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Vous avez 1 mois pour effectuer le changement de carte grise après la vente.',
                              style: textStyle.textMRegular.copyWith(color: FigmaColors.primaryMain),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = FigmaTextStyles();

    return Container(
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FigmaColors.neutral20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de l'étape
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(bottom: BorderSide(color: color.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: textStyle.textMSemiBold.copyWith(color: FigmaColors.neutral100),
                  ),
                ),
              ],
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _DocItem extends StatelessWidget {
  final String label;
  final bool isOptional;
  final String? optionalLabel;
  final bool isFreeText;

  const _DocItem({
    required this.label,
    this.isOptional = false,
    this.optionalLabel,
    this.isFreeText = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = FigmaTextStyles();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFreeText)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: FigmaColors.neutral60,
                  shape: BoxShape.circle,
                ),
              ),
            )
          else
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  label,
                  style: textStyle.textMRegular.copyWith(color: FigmaColors.neutral90),
                ),
                if (isOptional && optionalLabel != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: FigmaColors.neutral20,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      optionalLabel!,
                      style: textStyle.captionSMedium.copyWith(
                        color: FigmaColors.neutral70,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AntsButton extends StatelessWidget {
  final FigmaTextStyles textStyle;
  const _AntsButton({required this.textStyle});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () async {
          final url = Uri.parse('https://immatriculation.ants.gouv.fr');
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
        },
        icon: const Icon(Icons.open_in_new, color: Colors.white, size: 18),
        label: Text(
          'Faire ma démarche sur l\'ANTS',
          style: textStyle.textMSemiBold.copyWith(color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: FigmaColors.primaryMain,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
    );
  }
}
