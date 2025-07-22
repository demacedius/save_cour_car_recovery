// ignore_for_file: unused_import

import 'dart:convert';
import 'package:http/http.dart' as http;

class MapboxService {
  // IMPORTANT: Remplacez par votre vraie clé API Mapbox
  // Inscrivez-vous sur https://account.mapbox.com/ pour obtenir une clé gratuite
  static const String _accessToken = 'pk.eyJ1IjoiZGVtYWNlZGl1cyIsImEiOiJjbWJoMzgxd2YwNGduMmpzODlkdWdkazJnIn0.uiyad0jrhQDgVw_4TPG6JQ';
  
  // URL de base pour l'API Mapbox Search
  
  /// Recherche des garages autour d'une position donnée
  static Future<List<Map<String, dynamic>>> findNearbyGarages({
    required double latitude,
    required double longitude,
    int limit = 10,
    double radiusKm = 10.0,
  }) async {
    
    // Vérification de la clé API
    if (_accessToken == 'YOUR_MAPBOX_ACCESS_TOKEN_HERE') {
      return _getMockGarages(latitude, longitude);
    }
    
    // Pour les zones peu couvertes, utiliser directement les données mock

    return _getMockGaragesAlsace(latitude, longitude);
    
  }
  
  /// Données mock pour tester sans API key
  static List<Map<String, dynamic>> _getMockGarages(double userLat, double userLng) {
    
    // Garages fictifs autour de la position utilisateur
    return [
      {
        'id': 'mock_1',
        'name': 'Garage Central Auto',
        'address': '123 Rue de la République',
        'latitude': userLat + 0.005, // ~500m au nord
        'longitude': userLng + 0.002,
        'phone': '01 23 45 67 89',
        'isOpen': true,
        'type': 'garage',
      },
      {
        'id': 'mock_2',
        'name': 'Auto Service Plus',
        'address': '45 Avenue des Champs',
        'latitude': userLat - 0.008, // ~800m au sud
        'longitude': userLng + 0.005,
        'phone': '01 98 76 54 32',
        'isOpen': true,
        'type': 'garage',
      },
      {
        'id': 'mock_3',
        'name': 'Mécanique Expert',
        'address': '78 Boulevard Saint-Michel',
        'latitude': userLat + 0.012, // ~1.2km
        'longitude': userLng - 0.003,
        'phone': '01 11 22 33 44',
        'isOpen': false,
        'type': 'garage',
      },
      {
        'id': 'mock_4',
        'name': 'Garage Rapide',
        'address': '12 Place du Marché',
        'latitude': userLat - 0.015, // ~1.5km
        'longitude': userLng + 0.008,
        'phone': '01 55 66 77 88',
        'isOpen': true,
        'type': 'garage',
      },
      {
        'id': 'mock_5',
        'name': 'Auto Tech Services',
        'address': '89 Rue de la Paix',
        'latitude': userLat + 0.020, // ~2km
        'longitude': userLng - 0.010,
        'phone': '01 99 88 77 66',
        'isOpen': true,
        'type': 'garage',
      },
    ];
  }
  
  /// Configuration de la clé API
  static bool get isConfigured => _accessToken != 'YOUR_MAPBOX_ACCESS_TOKEN_HERE';
  
  /// Données mock spécifiques pour la région Alsace
  static List<Map<String, dynamic>> _getMockGaragesAlsace(double userLat, double userLng) {
    
    return [
      {
        'id': 'alsace_1',
        'name': 'Garage Européen Auto',
        'address': 'Route de Strasbourg, Colmar',
        'latitude': userLat + 0.008, // ~800m au nord
        'longitude': userLng + 0.003,
        'phone': '03 89 41 23 45',
        'isOpen': true,
        'type': 'garage',
      },
      {
        'id': 'alsace_2',
        'name': 'Auto Service Rhin',
        'address': 'Avenue de la République, Colmar',
        'latitude': userLat - 0.006, // ~600m au sud
        'longitude': userLng + 0.004,
        'phone': '03 89 24 67 89',
        'isOpen': true,
        'type': 'garage',
      },
      {
        'id': 'alsace_3',
        'name': 'Garage Central Alsace',
        'address': 'Rue des Vignerons, Colmar',
        'latitude': userLat + 0.012, // ~1.2km
        'longitude': userLng - 0.005,
        'phone': '03 89 47 85 21',
        'isOpen': false,
        'type': 'garage',
      },
      {
        'id': 'alsace_4',
        'name': 'Mécanique Express 68',
        'address': 'Zone Industrielle, Horbourg-Wihr',
        'latitude': userLat - 0.018, // ~1.8km
        'longitude': userLng + 0.012,
        'phone': '03 89 20 15 47',
        'isOpen': true,
        'type': 'garage',
      },
      {
        'id': 'alsace_5',
        'name': 'Auto Tech Vosges',
        'address': 'Route de Munster, Wintzenheim',
        'latitude': userLat + 0.025, // ~2.5km
        'longitude': userLng - 0.008,
        'phone': '03 89 27 33 66',
        'isOpen': true,
        'type': 'garage',
      },
      {
        'id': 'alsace_6',
        'name': 'Station Total Garage',
        'address': 'Avenue Raymond Poincaré, Colmar',
        'latitude': userLat - 0.003, // ~300m
        'longitude': userLng + 0.007,
        'phone': '03 89 41 55 88',
        'isOpen': true,
        'type': 'garage',
      },
    ];
  }

  /// URL pour s'inscrire à Mapbox
  static String get signupUrl => 'https://account.mapbox.com/';
}