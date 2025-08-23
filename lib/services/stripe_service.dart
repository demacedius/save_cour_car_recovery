import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:save_your_car/config/stripe_config.dart';
import 'package:save_your_car/services/auth_service.dart';

class StripeService {
  static bool _isInitialized = false;
  static const String _subscriptionCacheKey = 'subscription_cache';
  static const String _lastCheckKey = 'last_subscription_check';
  static Map<String, dynamic>? _cachedSubscription;

  /// Initialise Stripe avec la clé publique
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      Stripe.publishableKey = StripeConfig.publishableKey;
      await Stripe.instance.applySettings();
      _isInitialized = true;
      print('✅ Stripe initialisé avec succès');
    } catch (e) {
      print('❌ Erreur initialisation Stripe: $e');
      rethrow;
    }
  }

  /// Crée un abonnement mensuel avec essai gratuit
  static Future<Map<String, dynamic>> createMonthlySubscription() async {
    return _createSubscription(
      priceId: StripeConfig.monthlyPriceId,
      trialDays: StripeConfig.freeTrialDays,
    );
  }

  /// Crée un abonnement annuel
  static Future<Map<String, dynamic>> createYearlySubscription() async {
    return _createSubscription(
      priceId: StripeConfig.yearlyPriceId,
      trialDays: 0, // Pas d'essai pour l'annuel
    );
  }

  /// Crée un abonnement via le backend
  static Future<Map<String, dynamic>> _createSubscription({
    required String priceId,
    required int trialDays,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      // Étape 1: Créer l'intent d'abonnement via le backend
      final response = await http.post(
        Uri.parse('${StripeConfig.baseUrl}/create-subscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'price_id': priceId,
          'trial_period_days': trialDays,
        }),
      );

      print('📊 Status création abonnement: ${response.statusCode}');
      print('📄 Réponse backend: ${response.body}');

      if (response.statusCode == 409) {
        // L'utilisateur a déjà un abonnement
        final errorData = jsonDecode(response.body);
        throw Exception('Vous avez déjà un abonnement actif ! ${errorData['message'] ?? ''}');
      } else if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception('Erreur backend: ${errorData['message'] ?? response.body}');
      }

      final responseData = jsonDecode(response.body);
      final clientSecret = responseData['client_secret'];
      final setupRequired = responseData['setup_required'] ?? false;

      if (clientSecret == null) {
        throw Exception('Client secret manquant dans la réponse');
      }

      // Étape 2: Initialiser le Payment Sheet selon le type
      if (setupRequired) {
        // Pour les essais gratuits (setup intent)
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            setupIntentClientSecret: clientSecret,
            merchantDisplayName: 'Save Your Car',
            style: ThemeMode.system,
          ),
        );
      } else {
        // Pour les paiements immédiats (payment intent)
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'Save Your Car',
            style: ThemeMode.system,
          ),
        );
      }

      // Étape 3: Présenter le formulaire de carte et confirmer
      await Stripe.instance.presentPaymentSheet();

      print('✅ Abonnement créé avec succès');
      return responseData;

    } catch (e) {
      print('❌ Erreur création abonnement: $e');
      rethrow;
    }
  }

  /// Récupère les informations d'abonnement de l'utilisateur avec cache intelligent
  static Future<Map<String, dynamic>?> getSubscriptionStatus({bool forceRefresh = false}) async {
    try {
      // NETTOYAGE: Vider le cache pour éviter les anciennes simulations
      // TODO: Retirer ce nettoyage après quelques versions
      if (_cachedSubscription != null && _cachedSubscription!['id'] == 8) {
        print('🧹 Nettoyage des anciennes simulations d\'abonnement');
        await _clearSubscriptionCache();
      }
      
      // Si pas de force refresh, vérifier le cache mémoire
      if (!forceRefresh && _cachedSubscription != null) {
        return _cachedSubscription;
      }

      // Vérifier le cache local (SharedPreferences)
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_lastCheckKey);
      final cachedData = prefs.getString(_subscriptionCacheKey);

      // Si le cache est récent (moins de 3 minutes) et pas de force refresh
      if (!forceRefresh && lastCheck != null && cachedData != null) {
        final lastCheckTime = DateTime.parse(lastCheck);
        final now = DateTime.now();
        if (now.difference(lastCheckTime).inMinutes < 3) {
          _cachedSubscription = jsonDecode(cachedData);
          return _cachedSubscription;
        }
      }

      // Récupérer depuis l'API
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      // Utiliser l'endpoint spécifique pour les abonnements
      final response = await http.get(
        Uri.parse('${StripeConfig.baseUrl}/subscription-status'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📊 Status récupération abonnement: ${response.statusCode}');
      print('📄 Réponse abonnement: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('🔍 Données abonnement reçues: $responseData');
        
        // La réponse peut contenir directement les données d'abonnement
        if (responseData['subscription'] != null) {
          final subscription = responseData['subscription'];
          print('🔍 Abonnement trouvé: $subscription');
          await _updateSubscriptionCache(subscription);
          return subscription;
        } else if (responseData['status'] != null) {
          // Ou directement les données de statut
          print('🔍 Statut d\'abonnement direct: $responseData');
          await _updateSubscriptionCache(responseData);
          return responseData;
        } else {
          print('🔍 Aucun abonnement trouvé pour cet utilisateur');
          await _clearSubscriptionCache();
          return null;
        }
      } else if (response.statusCode == 404) {
        // Pas d'abonnement
        print('🔍 Aucun abonnement (404)');
        await _clearSubscriptionCache();
        return null;
      } else {
        throw Exception('Erreur récupération statut: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur statut abonnement: $e');
      // En cas d'erreur, retourner le cache local s'il existe
      return _cachedSubscription;
    }
  }

  /// Annule un abonnement
  static Future<bool> cancelSubscription() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      print('🔄 Tentative d\'annulation d\'abonnement...');

      final response = await http.post(
        Uri.parse('${StripeConfig.baseUrl}/cancel-subscription'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30)); // Timeout de 30 secondes

      print('📊 Status annulation: ${response.statusCode}');
      print('📄 Réponse annulation: ${response.body}');

      if (response.statusCode == 200) {
        // Vider le cache pour forcer la récupération depuis l'API
        await _clearSubscriptionCache();
        print('✅ Abonnement annulé avec succès');
        return true;
      } else if (response.statusCode == 404) {
        // Abonnement déjà annulé ou introuvable
        await _clearSubscriptionCache();
        throw Exception('Aucun abonnement actif trouvé à annuler');
      } else if (response.statusCode == 400) {
        // Erreur de validation
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Données invalides pour l\'annulation');
        } catch (e) {
          throw Exception('Erreur de validation lors de l\'annulation');
        }
      } else {
        // Autres erreurs
        try {
          final errorData = jsonDecode(response.body);
          throw Exception(errorData['message'] ?? 'Erreur lors de l\'annulation');
        } catch (e) {
          throw Exception('Erreur serveur lors de l\'annulation (Status: ${response.statusCode})');
        }
      }
    } catch (e) {
      print('❌ Erreur annulation abonnement: $e');
      return false;
    }
  }


  /// Formate un prix en euros
  static String formatPrice(int priceInCents) {
    final euros = priceInCents / 100;
    return '${euros.toStringAsFixed(2)}€';
  }

  /// Formate une date pour l'affichage
  static String _formatDate(DateTime date) {
    final months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 
                   'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Met à jour le cache d'abonnement
  static Future<void> _updateSubscriptionCache(Map<String, dynamic> subscription) async {
    try {
      _cachedSubscription = subscription;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_subscriptionCacheKey, jsonEncode(subscription));
      await prefs.setString(_lastCheckKey, DateTime.now().toIso8601String());
      
      print('✅ Cache abonnement mis à jour');
    } catch (e) {
      print('❌ Erreur mise à jour cache: $e');
    }
  }

  /// Vide le cache d'abonnement
  static Future<void> _clearSubscriptionCache() async {
    try {
      _cachedSubscription = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_subscriptionCacheKey);
      await prefs.remove(_lastCheckKey);
      
      print('✅ Cache abonnement vidé');
    } catch (e) {
      print('❌ Erreur vidage cache: $e');
    }
  }

  /// Force la mise à jour du statut après souscription
  static Future<Map<String, dynamic>?> refreshSubscriptionAfterPurchase() async {
    print('🔄 Rafraîchissement statut abonnement après achat...');
    
    // Attendre un peu pour que le backend traite l'abonnement
    await Future.delayed(const Duration(seconds: 2));
    
    // Forcer la récupération depuis l'API
    return await getSubscriptionStatus(forceRefresh: true);
  }

  /// Diagnostique et tente de résoudre les problèmes d'abonnement "incomplete"
  static Future<void> diagnosticIncompleteSubscription() async {
    print('🔧 Diagnostic abonnement incomplete...');
    
    try {
      final subscription = await getSubscriptionStatus(forceRefresh: true);
      
      if (subscription != null) {
        final status = subscription['status'];
        final createdAt = subscription['created_at'];
        final currentPeriodEnd = subscription['current_period_end'];
        
        if (status == 'incomplete') {
          print('⚠️ Abonnement incomplete détecté');
          print('   - created_at: $createdAt');
          print('   - current_period_end: $currentPeriodEnd');
          
          // Vérifier si c'est un abonnement récent et potentiellement valide
          bool shouldTreatAsActive = false;
          try {
            if (createdAt != null && currentPeriodEnd != null) {
              final startDate = DateTime.parse(createdAt.toString());
              final endDate = DateTime.parse(currentPeriodEnd.toString());
              final now = DateTime.now();
              
              final isRecent = now.difference(startDate).inHours < 24;
              final isStillValid = endDate.isAfter(now);
              shouldTreatAsActive = isRecent && isStillValid;
              
              print('   - Est récent (< 24h): $isRecent');
              print('   - Est encore valide: $isStillValid');
              print('   - Traiter comme actif: $shouldTreatAsActive');
            }
          } catch (e) {
            print('   - Erreur parsing dates: $e');
          }
          
          if (shouldTreatAsActive) {
            print('✅ Abonnement incomplete mais considéré comme valide');
          } else {
            print('🔄 Tentative de rafraîchissement...');
            
            // Attendre et rafraîchir plusieurs fois si nécessaire
            for (int i = 0; i < 3; i++) {
              await Future.delayed(const Duration(seconds: 3));
              final refreshed = await getSubscriptionStatus(forceRefresh: true);
              
              if (refreshed != null && refreshed['status'] != 'incomplete') {
                print('✅ Statut résolu après ${i + 1} tentatives: ${refreshed['status']}');
                break;
              }
              
              print('🔄 Tentative ${i + 1}/3 - statut toujours incomplete');
            }
          }
        }
      }
    } catch (e) {
      print('❌ Erreur diagnostic abonnement: $e');
    }
  }

  /// Récupère le type d'abonnement (monthly/yearly)
  static Future<String?> getSubscriptionType() async {
    try {
      final subscription = await getSubscriptionStatus();
      final priceId = subscription?['price_id'] as String?;
      
      if (priceId == null) return null;
      
      // Identifier le type selon le price_id
      if (priceId.contains('monthly') || priceId == 'price_1RY34DPcMvKX08WxVEcPQcGM') {
        return 'monthly';
      } else if (priceId.contains('yearly') || priceId == 'price_1RY37QPcMvKX08WxNHTKBpJe') {
        return 'yearly';
      }
      
      return 'unknown';
    } catch (e) {
      print('❌ Erreur récupération type abonnement: $e');
      return null;
    }
  }

  /// Vérifie si l'utilisateur a un abonnement actif
  static Future<bool> hasActiveSubscription() async {
    try {
      final status = await getSubscriptionStatus();
      if (status == null) {
        return false;
      }

      final bool isActive = status['is_active'] ?? false;
      final bool isTrialing = status['is_trialing'] ?? false;

      return isActive || isTrialing;
    } catch (e) {
      print('❌ Erreur vérification abonnement actif: $e');
      return false;
    }
  }

  /// Récupère les détails formatés de l'abonnement pour l'affichage
  static Future<Map<String, dynamic>> getSubscriptionDetails() async {
    final subscription = await getSubscriptionStatus();
    
    if (subscription == null) {
      return {
        'hasSubscription': false,
        'isActive': false,
        'isTrialing': false,
        'type': null,
        'statusText': 'Aucun abonnement',
        'statusColor': 'grey',
        'planText': '',
      };
    }

    var isActive = subscription['is_active'] == true;
    final isTrialing = subscription['is_trialing'] == true;
    final status = subscription['status'] as String? ?? '';
    final priceId = subscription['price_id'] as String? ?? '';
    
    String statusText = '';
    String statusColor = 'grey';
    
    if (isTrialing) {
      statusText = 'Essai gratuit actif';
      statusColor = 'green';
    } else if (status == 'canceled') {
      // Vérifier si l'abonnement annulé est encore dans sa période active
      final cancelAtPeriodEnd = subscription['cancel_at_period_end'] == true;
      final currentPeriodEnd = subscription['current_period_end'];
      
      if (cancelAtPeriodEnd && currentPeriodEnd != null) {
        try {
          final endDate = DateTime.parse(currentPeriodEnd.toString()).toUtc();
          final nowUtc = DateTime.now().toUtc();
          
          if (nowUtc.isBefore(endDate)) {
            // Abonnement annulé mais encore actif jusqu'à la fin de la période
            statusText = 'Abonnement annulé (actif jusqu\'au ${_formatDate(endDate)})';
            statusColor = 'orange';
            isActive = true; // Reste actif jusqu'à la fin
          } else {
            // Abonnement complètement expiré
            statusText = 'Abonnement expiré';
            statusColor = 'red';
            isActive = false;
          }
        } catch (e) {
          statusText = 'Abonnement annulé';
          statusColor = 'red';
        }
      } else {
        statusText = 'Abonnement annulé';
        statusColor = 'red';
      }
    } else if (isActive) {
      statusText = 'Abonnement actif';
      statusColor = 'green';
    } else if (status == 'past_due') {
      statusText = 'Paiement en retard';
      statusColor = 'orange';
    } else if (status == 'incomplete') {
      // Utiliser la même logique que hasActiveSubscription()
      final now = DateTime.now();
      final currentPeriodStart = subscription['current_period_start'];
      final currentPeriodEnd = subscription['current_period_end'];
      
      bool shouldTreatAsActive = false;
      
      // 1. Vérifier si nous sommes dans une période d'abonnement valide
      try {
        if (currentPeriodStart != null && currentPeriodEnd != null) {
          final startDate = DateTime.parse(currentPeriodStart.toString()).toUtc();
          final endDate = DateTime.parse(currentPeriodEnd.toString()).toUtc();
          final nowUtc = DateTime.now().toUtc();
          
          final isAfterStart = nowUtc.isAfter(startDate);
          final isBeforeEnd = nowUtc.isBefore(endDate);
          final isInValidPeriod = isAfterStart && isBeforeEnd;
          final createdRecently = nowUtc.difference(startDate).inDays < 7; // 7 jours de grâce
          
          print('🔍 DEBUG getSubscriptionDetails incomplete:');
          print('   - startDate (UTC): $startDate');
          print('   - endDate (UTC): $endDate');
          print('   - nowUtc: $nowUtc');
          print('   - nowUtc.isAfter(startDate): $isAfterStart');
          print('   - nowUtc.isBefore(endDate): $isBeforeEnd');
          print('   - isInValidPeriod: $isInValidPeriod');
          print('   - createdRecently: $createdRecently');
          
          // Si nous sommes dans la période valide ET créé récemment, traiter comme actif
          if (isInValidPeriod && createdRecently) {
            shouldTreatAsActive = true;
            print('🔍 ✅ getSubscriptionDetails: Abonnement incomplete mais période valide');
          }
        }
      } catch (e) {
        print('⚠️ Erreur parsing dates incomplete dans getSubscriptionDetails: $e');
      }
      
      // 2. Fallback sur l'ancienne logique pour compatibilité
      if (!shouldTreatAsActive) {
        final createdAt = subscription['created_at'];
        try {
          if (createdAt != null && currentPeriodEnd != null) {
            final startDate = DateTime.parse(createdAt.toString());
            final endDate = DateTime.parse(currentPeriodEnd.toString());
            
            final isRecent = now.difference(startDate).inHours < 24;
            final isStillValid = endDate.isAfter(now);
            shouldTreatAsActive = isRecent && isStillValid;
          }
        } catch (e) {
          print('⚠️ Erreur parsing dates incomplete fallback: $e');
        }
      }
      
      if (shouldTreatAsActive) {
        statusText = 'Abonnement actif';
        statusColor = 'green';
        isActive = true; // Traiter comme actif
      } else {
        statusText = 'Abonnement en cours de traitement';
        statusColor = 'orange';
      }
    } else {
      statusText = 'Abonnement inactif';
      statusColor = 'orange';
    }
    
    // Debug: afficher les détails calculés
    print('🔍 Debug getSubscriptionDetails:');
    print('   - statusText: $statusText');
    print('   - statusColor: $statusColor');
    print('   - isActive: $isActive');
    print('   - isTrialing: $isTrialing');
    
    String planText = '';
    String type = '';
    if (priceId.contains('monthly') || priceId == 'price_1RY34DPcMvKX08WxVEcPQcGM') {
      planText = 'Plan mensuel (9,99€/mois)';
      type = 'monthly';
    } else if (priceId.contains('yearly') || priceId == 'price_1RY37QPcMvKX08WxNHTKBpJe') {
      planText = 'Plan annuel (29,99€/an)';
      type = 'yearly';
    } else {
      planText = 'Plan inconnu ($priceId)';
      type = 'unknown';
    }

    return {
      'hasSubscription': true,
      'isActive': isActive,
      'isTrialing': isTrialing,
      'type': type,
      'statusText': statusText,
      'statusColor': statusColor,
      'planText': planText,
      'priceId': priceId,
      'status': status,
      'rawData': subscription,
    };
  }
}