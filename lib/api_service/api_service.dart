import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:save_your_car/config/api_config.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/services/auth_service.dart';


Future<VehicleData?> fetchVehicleInfo(String plate) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/vehicles/from-plate');
  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'plate': plate}),
    );

    print('Status code reçu: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Données reçues de l\'API: $data');
      return VehicleData.fromJson(data);
    } else {
      print('❌ Erreur ${response.statusCode}: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Erreur lors de l\'appel API: $e');
    return null;
  }
}

Future<Map<String, dynamic>?> registerUserWithVehicle({
  required String fullName,
  required String email,
  required String password,
  required VehicleData vehicle,
}) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/register-with-vehicle');
  final data = {
  'fullName': fullName,
  'email': email,
  'password': password,
  'plate': vehicle.plate,
  'model': vehicle.model,
  'brand': vehicle.brand,
  'year': vehicle.year,
  'mileage': vehicle.mileage,
  'technicalControlDate': vehicle.technicalControlDate?.toIso8601String() ?? "",
  'imageUrl': vehicle.imageUrl,
  'brandImageUrl': vehicle.brandImageUrl,
};
  try {
    print('📤 Données envoyées : $data');
    print('📤 Vehicle object: ${vehicle.toJson()}');
    print('📤 JSON envoyé: ${jsonEncode(data)}');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      print('✅ Inscription réussie : ${response.body}');
      return jsonDecode(response.body);
    } else {
      print('Erreur ${response.statusCode}: ${response.body}');
      return null;
    }
  } catch (e) {
    print('Erreur lors de l\'appel API: $e');
    return null;
  }
}

Future<Map<String, dynamic>?> transferVehicle(int vehicleId, String newOwnerEmail) async {
  try {
    final token = await AuthService.getToken();
    print('🔍 Debug transfer - Token récupéré: ${token != null ? "✅ Présent" : "❌ Absent"}');
    if (token == null) {
      print('❌ Token non trouvé - Utilisateur non connecté');
      return {'error': 'Utilisateur non connecté. Veuillez vous reconnecter.'};
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/vehicles/$vehicleId/transfer');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'newOwnerEmail': newOwnerEmail,
      }),
    );

    print('Status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Véhicule transféré avec succès');
      return data;
    } else {
      print('❌ Erreur transfert véhicule: ${response.body}');
      return {'error': response.body};
    }
  } catch (e) {
    print('❌ Erreur lors du transfert: $e');
    return {'error': e.toString()};
  }
}