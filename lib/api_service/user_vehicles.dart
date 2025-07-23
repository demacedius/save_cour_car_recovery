import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:intl/intl.dart';
import 'package:save_your_car/config/api_config.dart';
import 'package:save_your_car/models/vehicles.dart';

Future<List<VehicleData>> getUserVehicles(String token) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/vehicles');
  try {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );


    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> vehiclesList = data['vehicles'] ?? [];
      
      
      return vehiclesList.map((vehicleJson) {
        return VehicleData.fromJson(vehicleJson);
      }).toList();
    } else {
      return [];
    }
  } catch (e) {
    return [];
  }
}

Future<bool> createVehicle(VehicleData vehicle, String token) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/vehicles');
  try {
    print('🚗 Création véhicule - URL: $url');
    print('🚗 Données véhicule: ${jsonEncode({
      'plate': vehicle.plate,
      'model': vehicle.model,
      'brand': vehicle.brand,
      'year': vehicle.year,
      'mileage': vehicle.mileage,
      'technical_control_date': vehicle.technicalControlDate != null 
          ? '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(vehicle.technicalControlDate!.toUtc())}Z'
          : null,
      'image_url': vehicle.imageUrl,
      'brand_image_url': vehicle.brandImageUrl,
    })}');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'plate': vehicle.plate,
        'model': vehicle.model,
        'brand': vehicle.brand,
        'year': vehicle.year,
        'mileage': vehicle.mileage,
        'technical_control_date': vehicle.technicalControlDate != null 
            ? '${DateFormat('yyyy-MM-ddTHH:mm:ss').format(vehicle.technicalControlDate!.toUtc())}Z'
            : null,
        'image_url': vehicle.imageUrl,
        'brand_image_url': vehicle.brandImageUrl,
      }),
    );

    print('🚗 Réponse création véhicule - Status: ${response.statusCode}');
    print('🚗 Réponse création véhicule - Body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      print('❌ Erreur création véhicule - Status: ${response.statusCode}, Body: ${response.body}');
      return false;
    }
  } catch (e) {
    print('❌ Exception création véhicule: $e');
    return false;
  }
}

Future<Map<String, dynamic>?> updateVehicleBrandImages(String token) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/vehicles/update-brand-images');
  try {
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );


    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else {
      return null;
    }
  } catch (e) {
    return null;
  }
}