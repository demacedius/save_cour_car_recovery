import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/services/stripe_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int selectedIndex = 0;
  bool isLoading = false;
  bool isLoadingSubscription = true;
  final textStyle = FigmaTextStyles();
  Map<String, dynamic>? currentSubscription;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionStatus();
  }

  Future<void> _loadSubscriptionStatus() async {
    try {
      final subscriptionDetails = await StripeService.getSubscriptionDetails();
      setState(() {
        currentSubscription = subscriptionDetails['hasSubscription'] ? subscriptionDetails : null;
        isLoadingSubscription = false;
      });
    } catch (e) {
      print('🔍 Erreur chargement abonnement: $e');
      setState(() {
        currentSubscription = null;
        isLoadingSubscription = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaColors.neutral00,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header noir
            Container(
              width: double.infinity,
              height: 246,
              color: FigmaColors.neutral100,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left:31),
                    child: Text(
                      "Ton Auto En Bonne Santé",
                      style: textStyle.headingMMedium.copyWith(
                        color: FigmaColors.neutral00,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left:31),
                    child: Text(
                      "Avec Save Your Car Plus+",
                      style: textStyle.headingSReguler.copyWith(
                        color: FigmaColors.neutral30,
                      ),
                    ),
                  ),
                  
                ],
              ),
            ),
        
            const SizedBox(height: 32),
        
            // Contenu conditionnel selon l'état de l'abonnement
            if (isLoadingSubscription)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (currentSubscription != null)
              _buildSubscriptionManagement()
            else
              _buildSubscriptionPlans(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlans() {
    return Expanded(
      child: Column(
        children: [
          // Plans d'abonnement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                _planTile(
                  title: "9,99€ / mois, annulable à tout moment",
                  badge: "Essai gratuit 3 jours",
                  selected: selectedIndex == 0,
                  onTap: () => setState(() => selectedIndex = 0),
                ),
                const SizedBox(height: 16),
                _planTile(
                  title: "2,50€ / mois (29,99€/an)",
                  selected: selectedIndex == 1,
                  onTap: () => setState(() => selectedIndex = 1),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Bouton d'abonnement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: FigmaColors.primaryMain,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: isLoading ? null : _handleSubscription,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        selectedIndex == 0 ? "Essayer gratuitement" : "S'abonner",
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Infos légales
          Center(
            child: Column(
              children: [
                Text(
                  "Sans engagement, annulable à tout moment",
                  style: textStyle.captionXSMedium.copyWith(
                    color: FigmaColors.neutral60,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    // TODO: lien vers conditions
                  },
                  child: Text(
                    "Déjà abonné ? – Conditions",
                    style: textStyle.captionXSMedium.copyWith(
                      decoration: TextDecoration.underline,
                      color: FigmaColors.neutral70,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubscriptionManagement() {
    final statusText = currentSubscription?['statusText'] ?? 'Statut inconnu';
    final statusColor = _getColorFromString(currentSubscription?['statusColor'] ?? 'grey');
    final planText = currentSubscription?['planText'] ?? '';
    final isActive = currentSubscription?['isActive'] ?? false;
    
    // Debug : afficher toutes les infos de l'abonnement
    print('🔍 Debug abonnement formaté: $currentSubscription');

    return Expanded(
      child: Column(
        children: [
          // Statut de l'abonnement
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    isActive ? Icons.check_circle : Icons.info_outline,
                    color: statusColor,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    statusText,
                    style: textStyle.textLBold.copyWith(
                      color: statusColor,
                    ),
                  ),
                  if (planText.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      planText,
                      style: textStyle.textMMedium.copyWith(
                        color: FigmaColors.neutral70,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // Bouton d'annulation
          if (isActive)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: isLoading ? null : _handleCancelSubscription,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Annuler l'abonnement",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Infos sur l'annulation
          Center(
            child: Text(
              isActive 
                ? "L'annulation prendra effet à la fin de la période en cours"
                : "Vous pouvez vous réabonner à tout moment",
              style: textStyle.captionXSMedium.copyWith(
                color: FigmaColors.neutral60,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Color _getColorFromString(String colorString) {
    switch (colorString.toLowerCase()) {
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _handleCancelSubscription() async {
    // Afficher une confirmation
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'abonnement'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler votre abonnement ?\n\n'
          'Vous conserverez l\'accès aux fonctionnalités premium jusqu\'à la fin de votre période de facturation.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Garder l\'abonnement'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler l\'abonnement', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      setState(() {
        isLoading = true;
      });

      try {
        final success = await StripeService.cancelSubscription();
        
        if (success) {
          // Forcer le rafraîchissement du statut depuis l'API
          await StripeService.getSubscriptionStatus(forceRefresh: true);
          await _loadSubscriptionStatus();
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Abonnement annulé avec succès'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          throw Exception('Échec de l\'annulation de l\'abonnement');
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          Color backgroundColor = Colors.red;
          
          // Gestion des cas spéciaux
          if (errorMessage.contains('Aucun abonnement actif')) {
            errorMessage = '⚠️ Aucun abonnement actif à annuler';
            backgroundColor = Colors.orange;
            // Rafraîchir le statut car il peut y avoir une incohérence
            await _loadSubscriptionStatus();
          } else if (errorMessage.contains('timeout')) {
            errorMessage = '⏱️ Délai d\'attente dépassé. Veuillez réessayer.';
          } else if (errorMessage.contains('network') || errorMessage.contains('connection')) {
            errorMessage = '🌐 Problème de connexion. Vérifiez votre réseau.';
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  Widget _planTile({
    required String title,
    required bool selected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEDEAFF) : FigmaColors.neutral00,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? FigmaColors.primaryMain : FigmaColors.neutral20,
            width: 2,
          ),
          boxShadow: [
            if (!selected)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (badge != null)
              Positioned(
                top: -24,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B4EFF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: textStyle.captionXSMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            Row(
              children: [
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? FigmaColors.primaryMain : FigmaColors.neutral50,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: textStyle.textMSemiBold,
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscription() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Créer l'abonnement selon le plan sélectionné
      Map<String, dynamic> result;
      
      if (selectedIndex == 0) {
        // Plan mensuel avec essai gratuit
        result = await StripeService.createMonthlySubscription();
      } else {
        // Plan annuel
        result = await StripeService.createYearlySubscription();
      }

      print('✅ Abonnement créé: $result');

      // Rafraîchir le statut d'abonnement
      final updatedSubscription = await StripeService.refreshSubscriptionAfterPurchase();
      print('🔄 Statut après rafraîchissement: $updatedSubscription');

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedIndex == 0 
                ? '🎉 Essai gratuit activé !' 
                : '🎉 Abonnement activé !',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Recharger les détails de l'abonnement
        await _loadSubscriptionStatus();

        // Retourner à l'écran précédent après un délai
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, true); // true indique le succès
      }

    } catch (e) {
      print('❌ Erreur abonnement: $e');
      
      if (mounted) {
        String message = e.toString();
        Color backgroundColor = Colors.red;
        
        // Cas spécial pour l'abonnement existant
        if (message.contains('déjà un abonnement')) {
          message = '✅ Vous avez déjà un abonnement actif !';
          backgroundColor = Colors.green;
          
          // Rafraîchir le statut d'abonnement
          await _loadSubscriptionStatus();
          
          // Retourner à l'écran précédent après 2 secondes
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) Navigator.pop(context, true);
          });
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: backgroundColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

}
