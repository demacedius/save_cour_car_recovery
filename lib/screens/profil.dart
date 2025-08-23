import 'package:flutter/material.dart';
import 'package:save_your_car/screens/paywallScreen.dart';
import 'package:save_your_car/screens/profile/edit_profile_screen.dart';
import 'package:save_your_car/screens/profile/notification_screen.dart';
import 'package:save_your_car/screens/profile/language_screen.dart';
import 'package:save_your_car/screens/profile/help_screen.dart';
import 'package:save_your_car/screens/profile/invite_friends_screen.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/widgets/Main_scaffold.dart';
import 'package:save_your_car/services/user_service.dart';
import 'package:save_your_car/screens/auth/welcome_screen.dart';
import 'package:save_your_car/services/premium_service.dart';
import 'package:save_your_car/services/stripe_service.dart';
import 'package:save_your_car/services/diagnostic_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? subscriptionDetails;
  bool isLoadingSubscription = true;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      // Diagnostic des abonnements incomplete si nécessaire
      await StripeService.diagnosticIncompleteSubscription();
      
      final details = await PremiumService.getSubscriptionDetails();
      setState(() {
        subscriptionDetails = details;
        isLoadingSubscription = false;
      });
    } catch (e) {
      print('Erreur chargement abonnement: $e');
      setState(() {
        isLoadingSubscription = false;
      });
    }
  }

  Widget _buildSubscriptionCard(FigmaTextStyles textStyle) {
    if (isLoadingSubscription) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: FigmaColors.neutral20,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Chargement du statut...'),
          ],
        ),
      );
    }

    final hasSubscription = subscriptionDetails?['hasSubscription'] ?? false;
    final isActive = subscriptionDetails?['isActive'] ?? false;
    final statusText = subscriptionDetails?['statusText'] ?? 'Statut inconnu';
    final planText = subscriptionDetails?['planText'] ?? '';

    if (hasSubscription && isActive) {
      // Utilisateur avec abonnement actif
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const PaywallScreen()),
          );
          
          if (result == true) {
            // Rafraîchir le statut si changement
            _loadSubscriptionStatus();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: textStyle.textMSemiBold.copyWith(color: Colors.white),
                    ),
                    if (planText.isNotEmpty)
                      Text(
                        planText,
                        style: textStyle.textMRegular.copyWith(color: Colors.white70),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.settings, color: Colors.white, size: 16),
            ],
          ),
        ),
      );
    } else {
      // Utilisateur sans abonnement
      return GestureDetector(
        onTap: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (context) => const PaywallScreen()),
          );
          
          if (result == true) {
            // Rafraîchir le statut si souscription
            _loadSubscriptionStatus();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: FigmaColors.primaryMain,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Essayer Save Your Car Plus+",
                  style: textStyle.textMSemiBold.copyWith(color: Colors.white),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _runDiagnostic() async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Diagnostic en cours...')),
          ],
        ),
      ),
    );

    try {
      // Exécuter le diagnostic
      final results = await DiagnosticService.runFullDiagnostic();
      
      // Fermer l'indicateur de chargement
      if (mounted) Navigator.pop(context);
      
      // Afficher les résultats
      final summary = DiagnosticService.formatDiagnosticSummary(results);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('📋 Rapport de Diagnostic'),
            content: SingleChildScrollView(
              child: Text(
                summary,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Rafraîchir les données après diagnostic
                  _loadSubscriptionStatus();
                },
                child: const Text('Rafraîchir'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Fermer l'indicateur de chargement
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du diagnostic: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = FigmaTextStyles();

    return MainScaffold(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: FigmaColors.neutral00,
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                color: FigmaColors.neutral100,
                padding: const EdgeInsets.only(left: 24, top: 68),
                width: double.infinity,
                height: 147,
                child: Text(
                  "Profile",
                  style: textStyle.headingMBold.copyWith(
                    color: FigmaColors.neutral00,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
      
              const SizedBox(height: 16),
      
              // Statut abonnement
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSubscriptionCard(textStyle),
              ),
      
              const SizedBox(height: 24),
      
              // Options
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _ProfileOption(
                      title: "Edit Profile", 
                      icon: Icons.person_outline,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                    ),
                    _ProfileOption(
                      title: "Notification", 
                      icon: Icons.notifications_none,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                    ),
                    _ProfileOption(
                      title: "Langage", 
                      icon: Icons.language,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageScreen())),
                    ),
                    _ProfileOption(
                      title: "Aide", 
                      icon: Icons.help_outline,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen())),
                    ),
                    _ProfileOption(
                      title: "Inviter des amis", 
                      icon: Icons.group_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteFriendsScreen())),
                    ),
                    _ProfileOption(
                      title: "Diagnostic & Réparation", 
                      icon: Icons.build,
                      onTap: () => _runDiagnostic(),
                    ),
                    const SizedBox(height: 12),
                    _ProfileOption(
                      title: "Supprimer le compte",
                      icon: Icons.delete_outline,
                      onTap: () => _showDeleteAccountDialog(context),
                    ),
                    const _LogoutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Supprimer le compte',
            style: FigmaTextStyles().textLBold,
          ),
          content: Text(
            'Êtes-vous sûr de vouloir supprimer votre compte ? Cette action est irréversible.',
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
              onPressed: () async {
                Navigator.pop(context);
                await UserService.deleteAccount();
                
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Supprimer',
                style: FigmaTextStyles().textMSemiBold,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _ProfileOption({
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: FigmaColors.neutral10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: FigmaColors.neutral90),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: FigmaTextStyles().textMSemiBold),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: FigmaColors.neutral60),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: FigmaColors.neutral10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout, size: 20, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Se déconnecter",
                style: FigmaTextStyles().textMSemiBold.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Déconnexion',
            style: FigmaTextStyles().textLBold,
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
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
              onPressed: () async {
                Navigator.pop(context);
                await UserService.logout();
                
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Se déconnecter',
                style: FigmaTextStyles().textMSemiBold,
              ),
            ),
          ],
        );
      },
    );
  }
}