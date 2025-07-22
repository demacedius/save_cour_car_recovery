import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';

import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
          'Aide',
          style: FigmaTextStyles().headingSBold.copyWith(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FigmaColors.primaryFocus,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.help_outline,
                  color: FigmaColors.primaryMain,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Besoin d\'aide ? Consultez notre FAQ ou contactez-nous',
                    style: FigmaTextStyles().textMRegular.copyWith(
                      color: FigmaColors.primaryMain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAQ Section
          _buildSectionTitle('Questions fréquentes'),
          const SizedBox(height: 16),

          _buildFAQItem(
            'Comment ajouter un véhicule ?',
            'Rendez-vous dans l\'onglet "Mes véhicules" puis cliquez sur le bouton "+" pour ajouter un nouveau véhicule en saisissant sa plaque d\'immatriculation.',
          ),

          _buildFAQItem(
            'Comment scanner un document ?',
            'Dans la fiche d\'un véhicule, cliquez sur "Documents" puis sur "Ajouter un document". Vous pourrez alors prendre une photo ou sélectionner un fichier depuis votre galerie.',
          ),

          _buildFAQItem(
            'Mes données sont-elles sécurisées ?',
            'Oui, toutes vos données sont chiffrées et stockées de manière sécurisée. Nous ne partageons jamais vos informations personnelles avec des tiers.',
          ),

          _buildFAQItem(
            'Comment modifier les informations d\'un véhicule ?',
            'Ouvrez la fiche du véhicule concerné et cliquez sur l\'icône de modification (crayon) pour éditer les informations.',
          ),

          _buildFAQItem(
            'Puis-je utiliser l\'app hors ligne ?',
            'Vous pouvez consulter vos véhicules et documents hors ligne. Cependant, l\'ajout de nouveaux véhicules nécessite une connexion internet.',
          ),

          const SizedBox(height: 32),

          // Contact Section
          _buildSectionTitle('Nous contacter'),
          const SizedBox(height: 16),

          _buildContactOption(
            'Support par email',
            'Envoyez-nous un email et nous vous répondrons dans les 24h',
            Icons.email_outlined,
            () => _launchEmail(),
          ),

          _buildContactOption(
            'Centre d\'aide en ligne',
            'Consultez notre documentation complète',
            Icons.help_center_outlined,
            () => _launchHelpCenter(),
          ),

          _buildContactOption(
            'Signaler un bug',
            'Aidez-nous à améliorer l\'application',
            Icons.bug_report_outlined,
            () => _reportBug(),
          ),

          const SizedBox(height: 32),

          // Informations app
          _buildSectionTitle('À propos'),
          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: FigmaColors.neutral10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('Version de l\'application', '1.0.0'),
                const Divider(),
                _buildInfoRow('Dernière mise à jour', '15 janvier 2024'),
                const Divider(),
                _buildInfoRow('Développé par', 'Save Your Car Team'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Conditions et confidentialité
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => _launchTerms(),
                child: Text(
                  'Conditions d\'utilisation',
                  style: FigmaTextStyles().captionSMedium.copyWith(
                    color: FigmaColors.primaryMain,
                  ),
                ),
              ),
              Container(
                height: 16,
                width: 1,
                color: FigmaColors.neutral30,
              ),
              TextButton(
                onPressed: () => _launchPrivacy(),
                child: Text(
                  'Politique de confidentialité',
                  style: FigmaTextStyles().captionSMedium.copyWith(
                    color: FigmaColors.primaryMain,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: FigmaTextStyles().textLBold.copyWith(
          color: FigmaColors.neutral90,
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          backgroundColor: FigmaColors.neutral10,
          collapsedBackgroundColor: FigmaColors.neutral10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            question,
            style: FigmaTextStyles().textMSemiBold,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                answer,
                style: FigmaTextStyles().textMRegular.copyWith(
                  color: FigmaColors.neutral80,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: FigmaColors.primaryFocus,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: FigmaColors.primaryMain),
        ),
        title: Text(
          title,
          style: FigmaTextStyles().textMSemiBold,
        ),
        subtitle: Text(
          subtitle,
          style: FigmaTextStyles().captionSRegular.copyWith(
            color: FigmaColors.neutral70,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: FigmaColors.neutral10,
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: FigmaTextStyles().textMRegular.copyWith(
              color: FigmaColors.neutral70,
            ),
          ),
          Text(
            value,
            style: FigmaTextStyles().textMSemiBold,
          ),
        ],
      ),
    );
  }

  void _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@saveyourcar.fr',
      query: 'subject=Demande de support&body=Bonjour,\n\nJ\'ai besoin d\'aide concernant...',
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  void _launchHelpCenter() async {
    const url = 'https://saveyourcar.fr/aide';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _reportBug() {
    // Ici vous pouvez implémenter un système de rapport de bug
    // Par exemple, ouvrir un formulaire ou envoyer vers un système de tickets
  }

  void _launchTerms() async {
    const url = 'https://saveyourcar.fr/conditions';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _launchPrivacy() async {
    const url = 'https://saveyourcar.fr/confidentialite';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}