import 'dart:io';
import 'package:http/http.dart' as http;

class ApiConfig {
  // Utiliser l'IP alternative du Mac
  static String get baseUrl {
    // IP alternative qui fonctionnait
    return 'http://83.228.205.107:3334';
  }
  
  // Tentative de détection d'émulateur (approximative)
  static bool _isEmulator() {
    // Pour l'instant, forcer l'utilisation de 10.0.2.2 pour tous les Android
    // car il semble que vous testiez sur émulateur
    // TODO: Affiner cette détection ou utiliser un flag de configuration
    return Platform.isAndroid;
  }
  
  // URL alternative si le réseau principal ne fonctionne pas
  static String get alternativeBaseUrl {
    return 'http://192.168.0.164:3334';
  }
  
  // Pour le debugging
  static void printCurrentConfig() {
    print('🌐 API Config:');
    print('Platform: ${Platform.operatingSystem}');
    print('Is Android: ${Platform.isAndroid}');
    print('Is iOS: ${Platform.isIOS}');
    print('Is Emulator: ${_isEmulator()}');
    print('Base URL: $baseUrl');
    print('Alternative URL: $alternativeBaseUrl');
  }
  
  // Test de connectivité au serveur
  static Future<bool> testConnectivity() async {
    try {
      print('🔍 Test de connectivité vers: $baseUrl');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      print('✅ Serveur accessible - Status: ${response.statusCode}');
      return response.statusCode < 500;
    } catch (e) {
      print('❌ Serveur inaccessible: $e');
      return false;
    }
  }
}