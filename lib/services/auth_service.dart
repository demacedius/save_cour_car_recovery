// ignore_for_file: unused_import, avoid_print

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:save_your_car/config/api_config.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

// Service d'authentification avec persistance
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static String? _currentToken;
  static Map<String, dynamic>? _currentUser;

  // Sauvegarde le token en mémoire ET dans SharedPreferences
  static Future<void> setToken(String token) async {
    _currentToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    print('🔐 Token sauvegardé: ${token.substring(0, 20)}...');
  }

  // Récupère le token depuis la mémoire ou SharedPreferences
  static Future<String?> getToken() async {
    // Si en mémoire, retourner directement
    if (_currentToken != null) {
      print('🔐 Token depuis mémoire: ${_currentToken!.substring(0, 20)}... (${_currentToken!.length} chars)');
      return _currentToken;
    }
    
    // Sinon, récupérer depuis SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _currentToken = prefs.getString(_tokenKey);
    
    if (_currentToken != null) {
      print('🔐 Token depuis SharedPrefs: ${_currentToken!.substring(0, 20)}... (${_currentToken!.length} chars)');
      
      // Vérifier la structure du token JWT
      final parts = _currentToken!.split('.');
      print('🔍 JWT Parts: ${parts.length} (header.payload.signature)');
      if (parts.length == 3) {
        print('✅ Token JWT valide en structure');
      } else {
        print('❌ Token JWT invalide en structure');
      }
    } else {
      print('❌ Aucun token trouvé dans SharedPrefs');
      
      // Debug: Lister toutes les clés pour voir s'il y a d'autres tokens
      final allKeys = prefs.getKeys();
      final tokenKeys = allKeys.where((key) => key.toLowerCase().contains('token')).toList();
      print('🔍 Autres clés token trouvées: $tokenKeys');
    }
    
    return _currentToken;
  }

  // Supprime le token de la mémoire ET de SharedPreferences
  static Future<void> clearToken() async {
    _currentToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    print('🔐 Token supprimé');
  }

  // Sauvegarde les données utilisateur
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    _currentUser = userData;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
    print('👤 Données utilisateur sauvegardées');
  }

  // Récupère les données utilisateur
  static Future<Map<String, dynamic>?> getUserData() async {
    if (_currentUser != null) {
      return _currentUser;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    
    if (userDataString != null) {
      _currentUser = jsonDecode(userDataString);
      return _currentUser;
    }
    
    return null;
  }

  // Supprime les données utilisateur
  static Future<void> clearUserData() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
    print('👤 Données utilisateur supprimées');
  }

  // Vérifie si l'utilisateur est connecté
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    
    if (token == null || token.isEmpty) {
      // Pas de token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('needs_login', true);
      print('🚨 Aucun token - Marquage needs_login=true');
      return false;
    }
    
    // Vérifier si le token est expiré
    if (isTokenExpired(token)) {
      print('🚨 Token expiré - Nettoyage automatique');
      await clearToken();
      await clearUserData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('needs_login', true);
      return false;
    }
    
    return true;
  }

  // Vérifie si l'authentification est requise et redirige si nécessaire
  static Future<bool> requiresAuthentication() async {
    final isAuthenticated = await isLoggedIn();
    if (!isAuthenticated) {
      print('🚨 Authentification requise - Utilisateur non connecté');
      return true;
    }
    return false;
  }

  // Debug: Affiche les informations du token
  static Future<void> debugTokenInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final tokenFromPrefs = prefs.getString(_tokenKey);
    final tokenFromMemory = _currentToken;
    
    print('🔍 Debug Token Info:');
    print('  - Token en mémoire: ${tokenFromMemory != null ? "${tokenFromMemory.substring(0, 20)}..." : "null"}');
    print('  - Token SharedPrefs: ${tokenFromPrefs != null ? "${tokenFromPrefs.substring(0, 20)}..." : "null"}');
    print('  - Clé utilisée: $_tokenKey');
    
    // Vérifier s'il y a d'autres clés de token
    final allKeys = prefs.getKeys();
    final tokenKeys = allKeys.where((key) => key.toLowerCase().contains('token')).toList();
    print('  - Autres clés token trouvées: $tokenKeys');
  }

  // Migration: Récupère le token depuis l'ancienne clé 'token' et migre vers 'auth_token'
  static Future<void> migrateOldToken() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Vérifier s'il y a un token sous l'ancienne clé
    final oldToken = prefs.getString('token');
    final newToken = prefs.getString(_tokenKey);
    
    if (oldToken != null && newToken == null) {
      print('🔄 Migration token: ancienne clé vers nouvelle clé');
      await setToken(oldToken);
      await prefs.remove('token'); // Supprimer l'ancienne clé
      print('✅ Migration token terminée');
    }
  }

  // Utilitaire: Nettoie toutes les données d'authentification (en cas de problème)
  static Future<void> fullAuthCleanup() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Nettoyer tous les tokens possibles
    await prefs.remove('token');
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove('needs_login');
    _currentToken = null;
    _currentUser = null;
    
    print('🧹 Nettoyage complet des données d\'authentification effectué');
  }

  // Vérifie si l'utilisateur doit se reconnecter (après expiration du token)
  static Future<bool> needsLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('needs_login') ?? false;
  }

  // Marque que l'utilisateur s'est reconnecté avec succès
  static Future<void> markLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('needs_login', false);
  }

  // Test la validité du token avec un appel API simple
  static Future<bool> validateToken() async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('🧪 Test token - Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        // Sauvegarder les données utilisateur si la validation réussit
        final userData = jsonDecode(response.body);
        await setUserData(userData);
        return true;
      } else if (response.statusCode == 401) {
        // Token invalide/expiré - nettoyer les données
        await clearToken();
        await clearUserData();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needs_login', true);
        print('🔄 Token expiré - Données nettoyées, reconnexion requise');
      }
      return false;
    } catch (e) {
      print('❌ Erreur test token: $e');
      return false;
    }
  }

  // Décode un token JWT pour en extraire le payload (sans vérification de signature)
  static Map<String, dynamic>? decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalizedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
      final decoded = utf8.decode(base64Decode(normalizedPayload));
      return jsonDecode(decoded);
    } catch (e) {
      print('❌ Erreur décodage JWT: $e');
      return null;
    }
  }

  // Vérifie si le token JWT est expiré
  static bool isTokenExpired(String token) {
    try {
      final payload = decodeJWT(token);
      if (payload == null) return true;
      
      final exp = payload['exp'] as int?;
      if (exp == null) return true;
      
      final expirationDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final now = DateTime.now();
      final nowUtc = DateTime.now().toUtc();
      final expirationUtc = expirationDate.toUtc();
      
      print('🕐 Token expire le: $expirationDate (local) / $expirationUtc (UTC)');
      print('🕐 Heure actuelle: $now (local) / $nowUtc (UTC)');
      print('🕐 Différence: ${now.difference(expirationDate).inMinutes} minutes');
      print('🕐 Token expiré (local): ${now.isAfter(expirationDate)}');
      print('🕐 Token expiré (UTC): ${nowUtc.isAfter(expirationUtc)}');
      print('📱 Plateforme: ${Platform.isAndroid ? "Android" : Platform.isIOS ? "iOS" : "Autre"}');
      print('📱 Est émulateur: Probablement ${Platform.isAndroid ? "oui" : "non"}');
      
      return now.isAfter(expirationDate);
    } catch (e) {
      print('❌ Erreur vérification expiration: $e');
      return true;
    }
  }

  // Connexion utilisateur
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('🔄 Tentative de connexion...');
      ApiConfig.printCurrentConfig();
      
      // Test pour voir quelle IP le téléphone utilise vraiment
      print('🌐 Test: Tentative vers http://httpbin.org/ip');
      try {
        final ipResponse = await http.get(Uri.parse('http://httpbin.org/ip'));
        print('📱 IP publique du téléphone: ${ipResponse.body}');
      } catch (e) {
        print('❌ Impossible de récupérer IP publique: $e');
      }
      
      // Test de connectivité avant la connexion
      final isServerAccessible = await ApiConfig.testConnectivity();
      if (!isServerAccessible) {
        return {
          'success': false,
          'message': 'Serveur inaccessible. Vérifiez que le serveur est démarré et accessible sur votre réseau.',
        };
      }
      
      final loginUrl = '${ApiConfig.baseUrl}/login';
      print('🌐 URL de connexion: $loginUrl');
      
      final response = await http.post(
        Uri.parse(loginUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('📱 Status de connexion: ${response.statusCode}');
      print('📱 Réponse brute: ${response.body}');
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = responseData['token'];
        final userData = responseData['user'];
        
        await setToken(token);
        await setUserData(userData);
        await markLoggedIn();
        
        return {
          'success': true,
          'message': 'Connexion réussie',
          'user': userData,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur de connexion',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: $e',
      };
    }
  }

  // Inscription utilisateur
  static Future<Map<String, dynamic>> register(String email, String password, {Map<String, dynamic>? vehicleData}) async {
    try {
      final body = <String, dynamic>{
        'email': email,
        'password': password,
      };
      
      // Ajouter les données du véhicule si fournies
      if (vehicleData != null) {
        body.addAll(vehicleData);
      }

      final endpoint = vehicleData != null ? '/register-with-vehicle' : '/register';
      
      // Debug : Afficher le payload complet
      print('🔄 Inscription avec endpoint: $endpoint');
      print('📦 Payload complet: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      print('📱 Réponse inscription - Status: ${response.statusCode}');
      print('📱 Réponse inscription - Body: ${response.body}');
      
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Si l'inscription inclut un token (connexion automatique)
        if (responseData['token'] != null) {
          await setToken(responseData['token']);
          if (responseData['user'] != null) {
            await setUserData(responseData['user']);
          }
          await markLoggedIn();
        }
        
        return {
          'success': true,
          'message': 'Inscription réussie',
          'autoLogin': responseData['token'] != null,
          'user': responseData['user'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de l\'inscription',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Erreur réseau: $e',
      };
    }
  }

  // Déconnexion
  static Future<void> logout() async {
    await clearToken();
    await clearUserData();
    print('🚪 Déconnexion effectuée');
  }

  // Mot de passe oublié
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      print('🔄 Demande de réinitialisation pour: $email');
      
      ApiConfig.printCurrentConfig();
      
      final forgotPasswordUrl = '${ApiConfig.baseUrl}/forgot-password';
      print('🌐 URL reset: $forgotPasswordUrl');
      
      final response = await http.post(
        Uri.parse(forgotPasswordUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('📱 Status reset: ${response.statusCode}');
      print('📱 Réponse reset: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Demande de réinitialisation envoyée');
        return {'success': true, 'message': responseData['message']};
      } else {
        print('❌ Erreur reset: ${responseData['message']}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erreur lors de la demande',
        };
      }
    } catch (e) {
      print('❌ Exception reset: $e');
      return {
        'success': false,
        'message': 'Erreur de réseau',
      };
    }
  }

  // Utilitaire: Crée les headers d'authentification
  static Future<Map<String, String>?> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) {
      return null;
    }
    
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Vérifie la réponse HTTP et gère les erreurs d'authentification
  static Future<bool> handleAuthResponse(http.Response response) async {
    if (response.statusCode == 401) {
      print('❌ Token expiré - Nettoyage automatique des données');
      await clearToken();
      await clearUserData();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('needs_login', true);
      
      return false;
    }
    return true;
  }
}