import 'package:flutter/material.dart';
import 'package:save_your_car/services/stripe_service.dart';
import 'package:save_your_car/screens/paywallScreen.dart';

class PremiumService {
  /// Vérifie si l'utilisateur a un abonnement actif
  static Future<bool> hasActiveSubscription() async {
    return await StripeService.hasActiveSubscription();
  }

  /// Vérifie l'accès à une fonctionnalité premium et affiche le paywall si nécessaire
  static Future<bool> checkPremiumAccess(BuildContext context, {
    required String featureName,
    bool showPaywall = true,
  }) async {
    try {
      final hasSubscription = await hasActiveSubscription();
      
      if (hasSubscription) {
        print('✅ Accès premium autorisé pour: $featureName');
        return true;
      }

      print('❌ Accès premium refusé pour: $featureName');
      
      if (showPaywall && context.mounted) {
        // Afficher un message d'information d'abord
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$featureName nécessite un abonnement Save Your Car Plus+'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'S\'abonner',
              textColor: Colors.white,
              onPressed: () => _showPaywall(context),
            ),
          ),
        );
        
        // Petite pause avant d'afficher le paywall
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (context.mounted) {
          await _showPaywall(context);
        }
      }
      
      return false;
    } catch (e) {
      print('❌ Erreur vérification premium: $e');
      return false;
    }
  }

  /// Affiche l'écran de paywall
  static Future<bool> _showPaywall(BuildContext context) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PaywallScreen(),
        fullscreenDialog: true,
      ),
    );
    
    // Retourne true si l'utilisateur s'est abonné
    return result == true;
  }

  /// Vérifie l'abonnement pour le scanner de documents
  static Future<bool> checkDocumentScannerAccess(BuildContext context) async {
    return await checkPremiumAccess(
      context,
      featureName: 'Le scanner de documents',
      showPaywall: true,
    );
  }

  /// Vérifie l'abonnement pour l'upload de documents
  static Future<bool> checkDocumentUploadAccess(BuildContext context) async {
    return await checkPremiumAccess(
      context,
      featureName: 'L\'upload de documents',
      showPaywall: true,
    );
  }

  /// Vérifie l'abonnement pour les fonctionnalités avancées de profil
  static Future<bool> checkAdvancedProfileAccess(BuildContext context) async {
    return await checkPremiumAccess(
      context,
      featureName: 'Les fonctionnalités avancées du profil',
      showPaywall: true,
    );
  }

  /// Récupère les détails de l'abonnement pour l'affichage
  static Future<Map<String, dynamic>> getSubscriptionDetails() async {
    return await StripeService.getSubscriptionDetails();
  }

  /// Force le rafraîchissement du statut d'abonnement
  static Future<void> refreshSubscriptionStatus() async {
    await StripeService.getSubscriptionStatus(forceRefresh: true);
  }
}