import 'package:flutter/material.dart';
import 'package:save_your_car/config/api_config.dart';
import 'package:save_your_car/services/stripe_service.dart';
import 'package:save_your_car/services/notification_service.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'app.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  
  // Debug: Afficher la configuration API au démarrage
  ApiConfig.printCurrentConfig();
  
  // Initialiser Stripe
  try {
    await StripeService.initialize();
    print('💳 Stripe initialisé avec succès');
  } catch (e) {
    print('❌ Erreur initialisation Stripe: $e');
  }
  
  // Migrer les anciens tokens si nécessaire
  try {
    await AuthService.migrateOldToken();
  } catch (e) {
    print('❌ Erreur migration token: $e');
  }

  // Initialiser les notifications
  try {
    await NotificationService.initialize();
    // await NotificationService.requestPermissions();
    // await NotificationService.requestPreciseAlarmsPermission();
    print('🔔 Notifications initialisées avec succès');
  } catch (e) {
    print('❌ Erreur initialisation notifications: $e');
  }
  
  runApp(const App());
}
