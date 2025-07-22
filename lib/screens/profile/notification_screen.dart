import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';


class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool vehicleReminders = true;
  bool newsUpdates = true;
  bool maintenanceAlerts = true;
  bool documentExpiry = true;
  bool promotions = false;

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
          'Notifications',
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
                  Icons.notifications_active,
                  color: FigmaColors.primaryMain,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Gérez vos préférences de notification pour rester informé',
                    style: FigmaTextStyles().textMRegular.copyWith(
                      color: FigmaColors.primaryMain,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Types de notifications
          _buildSectionTitle('Types de notifications'),
          const SizedBox(height: 16),

          _buildNotificationTile(
            'Notifications push',
            'Recevoir des notifications sur votre appareil',
            Icons.phone_android,
            pushNotifications,
            (value) => setState(() => pushNotifications = value),
          ),

          _buildNotificationTile(
            'Notifications par email',
            'Recevoir des notifications par email',
            Icons.email_outlined,
            emailNotifications,
            (value) => setState(() => emailNotifications = value),
          ),

          const SizedBox(height: 24),

          // Rappels véhicule
          _buildSectionTitle('Rappels véhicule'),
          const SizedBox(height: 16),

          _buildNotificationTile(
            'Rappels généraux',
            'Contrôle technique, assurance, etc.',
            Icons.directions_car,
            vehicleReminders,
            (value) => setState(() => vehicleReminders = value),
          ),

          _buildNotificationTile(
            'Alertes maintenance',
            'Révisions, vidanges, entretien',
            Icons.build_outlined,
            maintenanceAlerts,
            (value) => setState(() => maintenanceAlerts = value),
          ),

          _buildNotificationTile(
            'Expiration documents',
            'Carte grise, assurance, contrôle technique',
            Icons.description_outlined,
            documentExpiry,
            (value) => setState(() => documentExpiry = value),
          ),

          const SizedBox(height: 24),

          // Actualités
          _buildSectionTitle('Actualités et promotions'),
          const SizedBox(height: 16),

          _buildNotificationTile(
            'Actualités automobile',
            'Nouveautés, tests, actualités du secteur',
            Icons.article_outlined,
            newsUpdates,
            (value) => setState(() => newsUpdates = value),
          ),

          _buildNotificationTile(
            'Offres promotionnelles',
            'Réductions, offres spéciales',
            Icons.local_offer_outlined,
            promotions,
            (value) => setState(() => promotions = value),
          ),

          const SizedBox(height: 32),

          // Bouton de sauvegarde
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: FigmaColors.primaryMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Sauvegarder les préférences',
              style: FigmaTextStyles().textMBold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: FigmaTextStyles().textLBold.copyWith(
        color: FigmaColors.neutral90,
      ),
    );
  }

  Widget _buildNotificationTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? FigmaColors.primaryMain : FigmaColors.neutral20,
          width: value ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? FigmaColors.primaryMain : FigmaColors.neutral60,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: FigmaTextStyles().textMSemiBold.copyWith(
                    color: value ? FigmaColors.neutral100 : FigmaColors.neutral80,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: FigmaTextStyles().captionSRegular.copyWith(
                    color: FigmaColors.neutral70,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: FigmaColors.primaryMain,
            activeTrackColor: FigmaColors.primaryFocus,
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // Ici vous pouvez ajouter la logique pour sauvegarder les préférences
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Préférences sauvegardées avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  }
}