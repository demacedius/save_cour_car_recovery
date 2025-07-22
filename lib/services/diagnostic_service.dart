import 'package:save_your_car/services/user_service.dart';
import 'package:save_your_car/services/stripe_service.dart';

class DiagnosticService {
  /// Effectue un diagnostic complet et tente de résoudre les problèmes courants
  static Future<Map<String, dynamic>> runFullDiagnostic() async {
    print('🏥 === DIAGNOSTIC COMPLET EN COURS ===');
    
    final results = <String, dynamic>{
      'userProfile': {'status': 'pending', 'message': ''},
      'subscription': {'status': 'pending', 'message': ''},
      'issues': <String>[],
      'resolved': <String>[],
    };

    // 1. Diagnostic du profil utilisateur
    try {
      print('🔍 1. Diagnostic profil utilisateur...');
      await UserService.diagnosticAndRepairCache();
      
      final user = await UserService.getCurrentUser();
      if (user != null) {
        final firstName = user['first_name']?.toString() ?? '';
        final lastName = user['last_name']?.toString() ?? '';
        final email = user['email']?.toString() ?? '';
        
        // Vérifier les valeurs corrompues (null en string)
        final isFirstNameCorrupted = firstName.isEmpty || firstName == 'null';
        final isLastNameCorrupted = lastName.isEmpty || lastName == 'null';
        final isEmailCorrupted = email.isEmpty || email == 'null';
        
        if (isFirstNameCorrupted && isLastNameCorrupted) {
          results['userProfile']['status'] = 'warning';
          results['userProfile']['message'] = 'Nom/prénom corrompus, tentative de réparation...';
          results['issues'].add('Profil utilisateur corrompu (nom/prénom)');
          
          // Tentative de réparation forcée
          await UserService.forceRefreshUserCache();
          results['resolved'].add('Cache utilisateur rafraîchi');
        } else if (isEmailCorrupted) {
          results['userProfile']['status'] = 'error';
          results['userProfile']['message'] = 'Email corrompu';
          results['issues'].add('Email utilisateur corrompu');
        } else {
          results['userProfile']['status'] = 'success';
          results['userProfile']['message'] = 'Profil OK: $firstName $lastName ($email)';
        }
      } else {
        results['userProfile']['status'] = 'error';
        results['userProfile']['message'] = 'Aucune donnée utilisateur trouvée';
        results['issues'].add('Profil utilisateur introuvable');
        
        // Tentative de réparation
        await UserService.forceRefreshUserCache();
        results['resolved'].add('Tentative de rechargement du profil');
      }
    } catch (e) {
      results['userProfile']['status'] = 'error';
      results['userProfile']['message'] = 'Erreur: $e';
      results['issues'].add('Erreur chargement profil');
    }

    // 2. Diagnostic de l'abonnement
    try {
      print('🔍 2. Diagnostic abonnement...');
      await StripeService.diagnosticIncompleteSubscription();
      
      final subscription = await StripeService.getSubscriptionStatus(forceRefresh: true);
      if (subscription != null) {
        final status = subscription['status'];
        final isActive = subscription['is_active'];
        final isTrialing = subscription['is_trialing'];
        
        if (status == 'incomplete') {
          results['subscription']['status'] = 'warning';
          results['subscription']['message'] = 'Abonnement en cours de traitement';
          results['issues'].add('Abonnement incomplete');
        } else if (isActive == true || isTrialing == true) {
          results['subscription']['status'] = 'success';
          results['subscription']['message'] = 'Abonnement actif ($status)';
        } else {
          results['subscription']['status'] = 'info';
          results['subscription']['message'] = 'Pas d\'abonnement actif';
        }
      } else {
        results['subscription']['status'] = 'info';
        results['subscription']['message'] = 'Aucun abonnement trouvé';
      }
    } catch (e) {
      results['subscription']['status'] = 'error';
      results['subscription']['message'] = 'Erreur: $e';
      results['issues'].add('Erreur vérification abonnement');
    }

    // 3. Résumé
    final totalIssues = results['issues'].length;
    print('🏥 === DIAGNOSTIC TERMINÉ ===');
    print('📊 Problèmes détectés: $totalIssues');
    if (totalIssues == 0) {
      print('✅ Aucun problème majeur détecté');
    } else {
      print('⚠️ Problèmes: ${results['issues']}');
    }

    return results;
  }

  /// Affiche un résumé lisible du diagnostic
  static String formatDiagnosticSummary(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('📋 RAPPORT DE DIAGNOSTIC');
    buffer.writeln('');
    
    // Profil
    final userStatus = results['userProfile']['status'];
    final userMessage = results['userProfile']['message'];
    final userIcon = _getStatusIcon(userStatus);
    buffer.writeln('👤 Profil: $userIcon $userMessage');
    
    // Abonnement
    final subStatus = results['subscription']['status'];
    final subMessage = results['subscription']['message'];
    final subIcon = _getStatusIcon(subStatus);
    buffer.writeln('💳 Abonnement: $subIcon $subMessage');
    
    // Actions résolues
    final resolved = results['resolved'] as List;
    if (resolved.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('✅ ACTIONS RÉSOLUES:');
      for (final action in resolved) {
        buffer.writeln('  • $action');
      }
    }
    
    // Problèmes
    final issues = results['issues'] as List;
    if (issues.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('⚠️ PROBLÈMES DÉTECTÉS:');
      for (final issue in issues) {
        buffer.writeln('  • $issue');
      }
    }
    
    // Solutions
    if (issues.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('🔧 SOLUTIONS RECOMMANDÉES:');
      if (issues.any((issue) => issue.contains('Profil utilisateur'))) {
        buffer.writeln('  • Aller dans Profil → Edit Profile et vérifier vos informations');
        buffer.writeln('  • Redémarrer l\'app si le problème persiste');
      }
      if (issues.contains('Abonnement incomplete')) {
        buffer.writeln('  • Attendre quelques minutes ou redémarrer l\'app');
        buffer.writeln('  • Contacter le support si le problème persiste');
      }
    } else if (resolved.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('🎉 Tous les problèmes ont été résolus automatiquement !');
    }
    
    return buffer.toString();
  }

  static String _getStatusIcon(String status) {
    switch (status) {
      case 'success':
        return '✅';
      case 'warning':
        return '⚠️';
      case 'error':
        return '❌';
      case 'info':
        return 'ℹ️';
      default:
        return '❓';
    }
  }
}