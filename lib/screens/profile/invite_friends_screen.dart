import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';

import 'package:share_plus/share_plus.dart';

class InviteFriendsScreen extends StatelessWidget {
  const InviteFriendsScreen({super.key});

  final String referralCode = "SAVEYOURCAR2024";
  final String appStoreUrl = "https://apps.apple.com/app/save-your-car";
  final String playStoreUrl = "https://play.google.com/store/apps/details?id=com.saveyourcar.app";

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
          'Inviter des amis',
          style: FigmaTextStyles().headingSBold.copyWith(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Illustration et titre
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FigmaColors.primaryMain.withOpacity(0.1),
                    FigmaColors.primaryFocus,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.group_add,
                    size: 80,
                    color: FigmaColors.primaryMain,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Invitez vos amis et gagnez des récompenses !',
                    textAlign: TextAlign.center,
                    style: FigmaTextStyles().headingSBold.copyWith(
                      color: FigmaColors.primaryMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Partagez Save Your Car avec vos proches et débloquez des fonctionnalités premium',
                    textAlign: TextAlign.center,
                    style: FigmaTextStyles().textMRegular.copyWith(
                      color: FigmaColors.primaryMain,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Avantages
            _buildBenefitsSection(),

            const SizedBox(height: 32),

            // Code de parrainage
            _buildReferralCodeSection(context),

            const SizedBox(height: 24),

            // Boutons de partage
            _buildShareButtons(),

            const SizedBox(height: 32),

            // Statistiques
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vos avantages',
          style: FigmaTextStyles().textLBold.copyWith(
            color: FigmaColors.neutral90,
          ),
        ),
        const SizedBox(height: 16),
        _buildBenefitItem(
          Icons.star,
          'Premium gratuit',
          '1 mois de Save Your Car Plus+ pour chaque ami qui s\'inscrit',
        ),
        _buildBenefitItem(
          Icons.storage,
          'Stockage bonus',
          '+1 Go d\'espace de stockage pour vos documents',
        ),
        _buildBenefitItem(
          Icons.notification_important,
          'Notifications avancées',
          'Accès aux rappels et alertes premium',
        ),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FigmaColors.neutral20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: FigmaColors.primaryFocus,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: FigmaColors.primaryMain, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FigmaTextStyles().textMSemiBold,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: FigmaTextStyles().captionSRegular.copyWith(
                    color: FigmaColors.neutral70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Votre code de parrainage',
          style: FigmaTextStyles().textLBold.copyWith(
            color: FigmaColors.neutral90,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FigmaColors.neutral10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FigmaColors.primaryMain, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      referralCode,
                      style: FigmaTextStyles().headingSBold.copyWith(
                        color: FigmaColors.primaryMain,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Partagez ce code avec vos amis',
                      style: FigmaTextStyles().captionSRegular.copyWith(
                        color: FigmaColors.neutral70,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _copyCode(context),
                icon: const Icon(Icons.copy, color: FigmaColors.primaryMain),
                tooltip: 'Copier le code',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _shareApp,
            icon: const Icon(Icons.share),
            label: const Text('Partager l\'application'),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareToWhatsApp,
                icon: const Icon(Icons.message, color: Colors.green),
                label: const Text('WhatsApp'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shareToSMS,
                icon: const Icon(Icons.sms, color: FigmaColors.primaryMain),
                label: const Text('SMS'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'Vos statistiques',
            style: FigmaTextStyles().textLBold.copyWith(
              color: FigmaColors.neutral90,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('Amis invités', '3'),
              ),
              Container(
                height: 40,
                width: 1,
                color: FigmaColors.neutral30,
              ),
              Expanded(
                child: _buildStatItem('Bonus gagnés', '2 mois Premium'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: FigmaTextStyles().headingMBold.copyWith(
            color: FigmaColors.primaryMain,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: FigmaTextStyles().captionSRegular.copyWith(
            color: FigmaColors.neutral70,
          ),
        ),
      ],
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copié dans le presse-papier'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareApp() {
    final message = 'Découvre Save Your Car, l\'app qui t\'aide à gérer tes véhicules ! '
        'Utilise mon code $referralCode pour débloquer des bonus. '
        'Télécharge-la ici : $playStoreUrl';
    
    Share.share(message);
  }

  void _shareToWhatsApp() {
    final message = 'Salut ! Je t\'invite à essayer Save Your Car, une super app pour gérer tes véhicules 🚗\n\n'
        'Avec mon code de parrainage $referralCode, tu auras des bonus !\n\n'
        'Télécharge-la ici : $playStoreUrl';
    
    Share.share(message);
  }

  void _shareToSMS() {
    final message = 'Découvre Save Your Car ! Utilise mon code $referralCode pour des bonus. '
        'Télécharge : $playStoreUrl';
    
    Share.share(message);
  }
}