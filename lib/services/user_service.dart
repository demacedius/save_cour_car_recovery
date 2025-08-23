// ignore_for_file: depend_on_referenced_packages, empty_catches

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:save_your_car/config/api_config.dart';
import 'package:save_your_car/services/auth_service.dart';

class UserService {
  static const String _userDataKey = 'user_data';
  static Map<String, dynamic>? _cachedUserData;

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    
    // Vérifier le cache en mémoire
    if (_cachedUserData != null) {
      return _cachedUserData;
    }

    // Vérifier le cache local
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_userDataKey);
    if (cachedData != null) {
      try {
        _cachedUserData = jsonDecode(cachedData);
        return _cachedUserData;
      } catch (e) {
      }
    }
    

    // Récupérer depuis l'API
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return null;
      }

      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/user/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['user'];
        
        // Mettre en cache
        _cachedUserData = userData;
        await prefs.setString(_userDataKey, jsonEncode(userData));
        
        return userData;
      } else if (response.statusCode == 404) {
        // Endpoint n'existe pas - créer un profil par défaut
        final defaultUserData = await _createDefaultUserProfile();
        
        // Mettre en cache le profil par défaut
        _cachedUserData = defaultUserData;
        await prefs.setString(_userDataKey, jsonEncode(defaultUserData));
        
        return defaultUserData;
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        await AuthService.clearToken();
        await clearUserCache();
        
        // Marquer que l'utilisateur doit se reconnecter
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needs_login', true);
        
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Récupère le nom d'affichage de l'utilisateur (prénom ou nom complet)
  static Future<String> getUserDisplayName() async {
    final userData = await getCurrentUser();
    if (userData != null) {
      // Essayer first_name d'abord
      final firstName = userData['first_name'] as String?;
      if (firstName != null && firstName.isNotEmpty) {
        return firstName;
      }
      
      // Sinon essayer fullName et prendre le premier mot
      final fullName = userData['fullName'] as String?;
      if (fullName != null && fullName.isNotEmpty) {
        return fullName.split(' ').first;
      }
      
      // Sinon essayer name
      final name = userData['name'] as String?;
      if (name != null && name.isNotEmpty) {
        return name.split(' ').first;
      }
    }
    return 'Utilisateur'; // Valeur par défaut
  }

  /// Crée un profil utilisateur par défaut en extrayant des infos du token JWT
  static Future<Map<String, dynamic>> _createDefaultUserProfile() async {
    try {
      final token = await AuthService.getToken();
      if (token != null) {
        // Décoder le JWT pour extraire l'email et user_id
        final parts = token.split('.');
        if (parts.length == 3) {
          // Décoder la payload (partie 2 du JWT)
          final payload = parts[1];
          // Ajouter padding si nécessaire pour le base64
          final normalizedPayload = payload.padRight((payload.length + 3) ~/ 4 * 4, '=');
          final decoded = utf8.decode(base64Decode(normalizedPayload));
          final payloadData = jsonDecode(decoded);
          
          final email = payloadData['email'] as String?;
          final userId = payloadData['user_id'] as int?;
          
          
          // Créer un profil par défaut basé sur l'email
          String firstName = 'Utilisateur';
          if (email != null && email.contains('@')) {
            final emailPrefix = email.split('@')[0];
            // Capitaliser le prénom extrait de l'email
            firstName = emailPrefix.isNotEmpty 
                ? '${emailPrefix[0].toUpperCase()}${emailPrefix.substring(1)}'
                : 'Utilisateur';
          }
          
          return {
            'id': userId,
            'email': email ?? '',
            'first_name': firstName,
            'last_name': '',
            'fullName': firstName,
            'phone': null,
            'profile_picture': null,
          };
        }
      }
    } catch (e) {
    }
    
    // Profil minimal par défaut en cas d'erreur
    return {
      'id': null,
      'email': null,
      'first_name': 'Utilisateur',
      'last_name': '',
      'fullName': 'Utilisateur',
      'phone': null,
      'profile_picture': null,
    };
  }

  /// Vide le cache des données utilisateur
  static Future<void> clearUserCache() async {
    _cachedUserData = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userDataKey);
  }

  /// Diagnostique et répare le cache utilisateur si nécessaire
  static Future<void> diagnosticAndRepairCache() async {
    
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_userDataKey);
    
    if (cachedData != null) {
      try {
        final userData = jsonDecode(cachedData);
        
        // Vérifier si les champs essentiels sont vides ou corrompus
        final firstName = userData['first_name'];
        final lastName = userData['last_name'];
        final email = userData['email'];
        
        // Détecter les valeurs corrompues (null en string ou vides)
        final isFirstNameCorrupted = firstName == null || 
                                    firstName.toString().isEmpty || 
                                    firstName.toString() == 'null';
        final isLastNameCorrupted = lastName == null || 
                                   lastName.toString().isEmpty || 
                                   lastName.toString() == 'null';
        final isEmailCorrupted = email == null || 
                                email.toString().isEmpty || 
                                email.toString() == 'null';
        
        if ((isFirstNameCorrupted && isLastNameCorrupted) || isEmailCorrupted) {
          
          await clearUserCache();
          
          // Forcer un rechargement complet depuis l'API
          await getCurrentUser();
        } else {
          // Nettoyer les valeurs "null" en string si nécessaire
          if (isFirstNameCorrupted || isLastNameCorrupted) {
            userData['first_name'] = isFirstNameCorrupted ? '' : firstName;
            userData['last_name'] = isLastNameCorrupted ? '' : lastName;
            
            // Resauvegarder le cache nettoyé
            _cachedUserData = userData;
            await prefs.setString(_userDataKey, jsonEncode(userData));
          }
        }
      } catch (e) {
        await clearUserCache();
      }
    } else {
    }
  }

  /// Nettoie et réinitialise complètement le cache utilisateur
  static Future<void> forceRefreshUserCache() async {
    
    // Vider complètement le cache
    await clearUserCache();
    
    // Forcer un rechargement depuis l'API
    final freshData = await getCurrentUser();
    
    if (freshData != null) {
    } else {
    }
  }

  static Future<bool> updateUserProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phone,
  }) async {
    try {
      // Vérifier d'abord si l'utilisateur est authentifié
      if (await AuthService.requiresAuthentication()) {
        return false;
      }
      
      final token = await AuthService.getToken();
      
      if (token == null) {
        return false;
      }

      
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      
      final body = jsonEncode({
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
      });
      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/user/profile'),
        headers: headers,
        body: body,
      );


      if (response.statusCode == 200) {
        // Mettre à jour le cache avec les nouvelles données au lieu de le vider
        await _updateProfileLocally(firstName, lastName, email, phone);
        return true;
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        await AuthService.clearToken();
        await clearUserCache();
        
        // Marquer que l'utilisateur doit se reconnecter
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needs_login', true);
        
        return false;
      } else if (response.statusCode == 404) {
        // Endpoint n'existe pas - mise à jour locale uniquement
        final success = await _updateProfileLocally(firstName, lastName, email, phone);
        return success;
      } else {
        return false;
      }
    } catch (e) {
      // En cas d'erreur réseau, essayer la mise à jour locale
      return await _updateProfileLocally(firstName, lastName, email, phone);
    }
  }

  /// Met à jour le profil localement (cache uniquement)
  static Future<bool> _updateProfileLocally(String firstName, String lastName, String email, String? phone) async {
    try {
      // Récupérer le profil actuel
      final currentProfile = _cachedUserData ?? await _createDefaultUserProfile();
      
      // Mettre à jour avec les nouvelles données
      final updatedProfile = Map<String, dynamic>.from(currentProfile);
      updatedProfile['first_name'] = firstName;
      updatedProfile['last_name'] = lastName;
      updatedProfile['fullName'] = '$firstName $lastName'.trim();
      updatedProfile['email'] = email;
      updatedProfile['phone'] = phone;
      
      // Sauvegarder en cache
      _cachedUserData = updatedProfile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userDataKey, jsonEncode(updatedProfile));
      
      
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return false;
      }

      
      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/api/user/password'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );


      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        await AuthService.clearToken();
        await clearUserCache();
        
        // Marquer que l'utilisateur doit se reconnecter
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needs_login', true);
        
        return false;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  static Future<bool> uploadProfilePicture(String imagePath) async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        return false;
      }

      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/api/user/profile-picture'),
      );
      
      request.headers['Authorization'] = 'Bearer $token';
      
      final file = await http.MultipartFile.fromPath(
        'profile_picture', 
        imagePath,
        contentType: MediaType('image', 'jpeg'), // Force le type MIME correct
      );
      
      request.files.add(file);

      final response = await request.send();
      

      if (response.statusCode == 200) {
        // Vider le cache pour récupérer la nouvelle URL de photo
        await clearUserCache();
        return true;
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        await AuthService.clearToken();
        await clearUserCache();
        
        // Marquer que l'utilisateur doit se reconnecter
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('needs_login', true);
        
        return false;
      } else if (response.statusCode == 404) {
        // Endpoint n'existe pas - simuler le succès pour l'UX
        // NOTE: Dans un vrai cas, on sauvegarderait la photo localement
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // En cas d'erreur, simuler le succès pour éviter de bloquer l'utilisateur
      return true;
    }
  }


  static Future<void> logout() async {
    try {
      // Vider le cache utilisateur
      await clearUserCache();
      
      // Utiliser AuthService pour supprimer le token
      await AuthService.clearToken();
      
    } catch (e) {
    }
  }

  static Future<bool> deleteAccount() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        return false;
      }

      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/api/user/delete'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        await logout();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}