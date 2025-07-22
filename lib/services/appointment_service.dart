// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
// ignore: unused_import
import 'package:shared_preferences/shared_preferences.dart';
import '../api_service/user_vehicles.dart';
import '../config/api_config.dart';
import 'auth_service.dart';

class AppointmentService {

  /// Récupère le token JWT stocké
  static Future<String?> _getToken() async {
    return await AuthService.getToken();
  }

  /// Crée un nouveau rendez-vous
  static Future<Map<String, dynamic>> createAppointment({
    required String garageName,
    required String date,
    required String time,
    required String service,
    String? description,
    int? vehicleId,
    String? garageId,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    try {
      final url = '${ApiConfig.baseUrl}/appointments';
      print('🌐 URL utilisée: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'garage_name': garageName,
          'date': date,
          'time': time,
          'service': service,
          'description': description ?? '',
          'vehicle_id': vehicleId,
          'garage_id': garageId ?? '',
        }),
      );

      print('📅 Création RDV - Status: ${response.statusCode}');
      print('📅 Réponse: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur création rendez-vous');
      }
    } catch (e) {
      print('❌ Erreur création RDV: $e');
      print('🌐 Configuration API: ${ApiConfig.baseUrl}');
      print('🔧 Vérifiez que votre serveur backend est démarré sur le port 3334');
      print('📱 Vérifiez que votre téléphone et ordinateur sont sur le même réseau Wi-Fi');
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Récupère tous les rendez-vous de l'utilisateur
  static Future<List<Map<String, dynamic>>> getUserAppointments() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📅 Récupération RDV - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['appointments'] ?? []);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur récupération rendez-vous');
      }
    } catch (e) {
      print('❌ Erreur récupération RDV: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Récupère un rendez-vous spécifique
  static Future<Map<String, dynamic>> getAppointment(int appointmentId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['appointment'];
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Rendez-vous non trouvé');
      }
    } catch (e) {
      print('❌ Erreur récupération RDV: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Met à jour un rendez-vous
  static Future<Map<String, dynamic>> updateAppointment({
    required int appointmentId,
    String? date,
    String? time,
    String? service,
    String? description,
    String? status,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    try {
      Map<String, dynamic> updateData = {};
      if (date != null) updateData['date'] = date;
      if (time != null) updateData['time'] = time;
      if (service != null) updateData['service'] = service;
      if (description != null) updateData['description'] = description;
      if (status != null) updateData['status'] = status;

      final response = await http.put(
        Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur mise à jour rendez-vous');
      }
    } catch (e) {
      print('❌ Erreur mise à jour RDV: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Supprime un rendez-vous
  static Future<Map<String, dynamic>> deleteAppointment(int appointmentId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Token d\'authentification manquant');
    }

    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/appointments/$appointmentId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Erreur suppression rendez-vous');
      }
    } catch (e) {
      print('❌ Erreur suppression RDV: $e');
      throw Exception('Erreur réseau: $e');
    }
  }

  /// Formate une date pour l'API (YYYY-MM-DD)
  static String formatDateForApi(DateTime date) {
    return "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Parse une date de l'API
  static DateTime parseDateFromApi(String dateStr) {
    return DateTime.parse(dateStr);
  }

  /// Formate une date pour l'affichage
  static String formatDateForDisplay(DateTime date) {
    const months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return "${date.day} ${months[date.month]} ${date.year}";
  }

  /// Vérifie si une date est dans le futur
  static bool isDateInFuture(DateTime date) {
    final today = DateTime.now();
    final dateWithoutTime = DateTime(date.year, date.month, date.day);
    final todayWithoutTime = DateTime(today.year, today.month, today.day);
    return dateWithoutTime.isAfter(todayWithoutTime) || dateWithoutTime.isAtSameMomentAs(todayWithoutTime);
  }

  /// Récupère les créneaux horaires disponibles
  static List<String> getAvailableTimeSlots() {
    return [
      '08:00', '08:30', '09:00', '09:30', '10:00', '10:30',
      '11:00', '11:30', '14:00', '14:30', '15:00', '15:30',
      '16:00', '16:30', '17:00', '17:30', '18:00'
    ];
  }

  /// Types de services disponibles
  static List<String> getServiceTypes() {
    return [
      'Révision générale',
      'Vidange',
      'Changement pneus',
      'Contrôle technique',
      'Réparation freins',
      'Diagnostic électronique',
      'Carrosserie',
      'Climatisation',
      'Autre'
    ];
  }

  /// Valide ou rejette un rendez-vous (pour interface admin/garage)
  static Future<Map<String, dynamic>> validateAppointment({
    required int appointmentId,
    required String action, // "validate" ou "reject"
    String? reason,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final url = '${ApiConfig.baseUrl}/appointments/$appointmentId/validate';
      print('🔄 Validation RDV avec URL: $url');
      
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'action': action,
          if (reason != null) 'reason': reason,
        }),
      );

      print('📊 Status validation: ${response.statusCode}');
      print('📄 Réponse: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Erreur validation RDV: $e');
      rethrow;
    }
  }

  /// Récupère les véhicules de l'utilisateur (wrapper pour appointment screen)
  static Future<List<Map<String, dynamic>>> getUserVehiclesForAppointment() async {
    try {
      final token = await AuthService.getToken();
      
      if (token == null) {
        throw Exception('Token d\'authentification manquant');
      }

      final vehicles = await getUserVehicles(token);
      
      // Convertir en Map pour compatibilité UI
      return vehicles.map((vehicle) => {
        'id': vehicle.id,
        'plate': vehicle.plate,
        'model': vehicle.model,
        'brand': vehicle.brand,
        'year': vehicle.year,
        'mileage': vehicle.mileage,
      }).toList();
    } catch (e) {
      print('❌ Erreur récupération véhicules: $e');
      return [];
    }
  }
}