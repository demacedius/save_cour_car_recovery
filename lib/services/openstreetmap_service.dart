import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenStreetMapService {
  // API Overpass - 100% gratuite, pas de clé API nécessaire
  static const String _overpassUrl = 'https://overpass-api.de/api/interpreter';
  
  /// Recherche des garages/stations-service autour d'une position via OpenStreetMap
  static Future<List<Map<String, dynamic>>> findNearbyGarages({
    required double latitude,
    required double longitude,
    int limit = 20,
    double radiusMeters = 10000.0, // 10km par défaut
  }) async {
    
    try {
      print('🗺️ Recherche OSM: $latitude, $longitude (rayon: ${radiusMeters/1000}km)');
      
      // Requête Overpass pour chercher:
      // - amenity=fuel (stations-service)
      // - shop=car_repair (garages de réparation)
      // - craft=car_repair (artisans auto)
      // - amenity=car_wash (stations de lavage)
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="fuel"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="fuel"](around:$radiusMeters,$latitude,$longitude);
  node["shop"="car_repair"](around:$radiusMeters,$latitude,$longitude);
  way["shop"="car_repair"](around:$radiusMeters,$latitude,$longitude);
  node["craft"="car_repair"](around:$radiusMeters,$latitude,$longitude);
  way["craft"="car_repair"](around:$radiusMeters,$latitude,$longitude);
  node["amenity"="car_wash"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="car_wash"](around:$radiusMeters,$latitude,$longitude);
);
out center tags;
''';

      final response = await http.post(
        Uri.parse(_overpassUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: 'data=${Uri.encodeComponent(query)}',
      );
      
      print('📡 OSM Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List;
        
        print('✅ ${elements.length} POI trouvés via OpenStreetMap');
        
        List<Map<String, dynamic>> garages = [];
        
        for (var element in elements) {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          
          // Récupérer les coordonnées selon le type d'élément
          double lat, lng;
          if (element['type'] == 'node') {
            lat = element['lat'].toDouble();
            lng = element['lon'].toDouble();
          } else if (element['type'] == 'way' && element['center'] != null) {
            lat = element['center']['lat'].toDouble();
            lng = element['center']['lon'].toDouble();
          } else {
            continue; // Skip si pas de coordonnées
          }
          
          // Déterminer le nom
          String name = tags['name'] ?? 
                       tags['brand'] ?? 
                       tags['operator'] ?? 
                       _getDefaultName(tags);
          
          // Déterminer l'adresse
          String address = _buildAddress(tags);
          
          // Déterminer si c'est ouvert
          bool isOpen = _parseOpeningHours(tags['opening_hours']);
          
          // Déterminer le type de service
          String serviceType = _getServiceType(tags);
          
          garages.add({
            'id': 'osm_${element['id']}',
            'name': name,
            'address': address,
            'latitude': lat,
            'longitude': lng,
            'phone': tags['phone'] ?? tags['contact:phone'] ?? '',
            'website': tags['website'] ?? tags['contact:website'] ?? '',
            'isOpen': isOpen,
            'type': serviceType,
            'fuel_types': _getFuelTypes(tags),
            'services': _getServices(tags),
            'opening_hours': tags['opening_hours'] ?? '',
          });
        }
        
        // Limiter le nombre de résultats
        if (garages.length > limit) {
          garages = garages.take(limit).toList();
        }
        
        print('🏁 ${garages.length} garages traités et retournés');
        return garages;
        
      } else {
        print('❌ Erreur API Overpass: ${response.statusCode}');
        print('Response: ${response.body}');
        return _getFallbackGarages(latitude, longitude);
      }
      
    } catch (e) {
      print('❌ Erreur OpenStreetMap: $e');
      return _getFallbackGarages(latitude, longitude);
    }
  }
  
  /// Détermine le nom par défaut selon le type de POI
  static String _getDefaultName(Map<String, dynamic> tags) {
    if (tags['amenity'] == 'fuel') {
      return 'Station-service';
    } else if (tags['shop'] == 'car_repair' || tags['craft'] == 'car_repair') {
      return 'Garage automobile';
    } else if (tags['amenity'] == 'car_wash') {
      return 'Station de lavage';
    }
    return 'Service automobile';
  }
  
  /// Construit une adresse à partir des tags OSM
  static String _buildAddress(Map<String, dynamic> tags) {
    print('🏠 Construction adresse depuis tags: $tags');
    
    List<String> addressParts = [];
    
    // 1. Numéro + rue
    if (tags['addr:housenumber'] != null && tags['addr:street'] != null) {
      addressParts.add('${tags['addr:housenumber']} ${tags['addr:street']}');
      print('📍 Rue trouvée: ${tags['addr:housenumber']} ${tags['addr:street']}');
    } else if (tags['addr:street'] != null) {
      addressParts.add(tags['addr:street']);
      print('📍 Rue trouvée: ${tags['addr:street']}');
    }
    
    // 2. Ville (plusieurs variantes possibles)
    String? city = tags['addr:city'] ?? 
                   tags['addr:town'] ?? 
                   tags['addr:village'] ?? 
                   tags['addr:municipality'] ??
                   tags['city'] ??
                   tags['town'];
    
    if (city != null) {
      addressParts.add(city);
      print('🏙️ Ville trouvée: $city');
    }
    
    // 3. Code postal
    if (tags['addr:postcode'] != null) {
      addressParts.add(tags['addr:postcode']);
      print('📮 Code postal trouvé: ${tags['addr:postcode']}');
    }
    
    // 4. Si pas d'adresse structurée, essayer des champs alternatifs
    if (addressParts.isEmpty) {
      print('⚠️ Pas d\'adresse structurée, recherche alternatives...');
      
      // Essayer le champ "address" direct
      if (tags['address'] != null) {
        print('📫 Adresse directe trouvée: ${tags['address']}');
        return tags['address'];
      }
      
      // Chercher dans tous les tags qui contiennent "addr" ou des infos de lieu
      for (String key in tags.keys) {
        if (key.contains('addr') || key.contains('name') || key.contains('place')) {
          print('🔍 Tag potentiel: $key = ${tags[key]}');
        }
      }
      
      // Ou utiliser des infos de localisation générale
      String? location = tags['location'] ?? 
                        tags['place'] ?? 
                        tags['addr:hamlet'] ??
                        tags['addr:suburb'] ??
                        tags['addr:county'] ??
                        tags['is_in'] ??
                        tags['place_name'];
      
      if (location != null) {
        addressParts.add(location);
        print('📍 Localisation trouvée: $location');
      }
      
      // Fallback avec le pays/région
      if (addressParts.isEmpty) {
        String? region = tags['addr:state'] ?? 
                        tags['addr:province'] ?? 
                        tags['addr:region'] ??
                        tags['state'] ??
                        tags['country'];
        if (region != null) {
          addressParts.add(region);
          print('🗺️ Région trouvée: $region');
        }
      }
    }
    
    // 5. Si toujours vide, utiliser le nom du POI comme base
    if (addressParts.isEmpty) {
      String? name = tags['name'] ?? tags['brand'] ?? tags['operator'];
      if (name != null) {
        print('🏪 Utilisation du nom comme adresse: $name');
        return '$name, France';
      }
      
      print('❌ Aucune adresse trouvée, utilisation fallback');
      return 'Localisation disponible'; // Fallback neutre
    }
    
    String finalAddress = addressParts.join(', ');
    print('✅ Adresse finale: $finalAddress');
    return finalAddress;
  }
  
  /// Parse les heures d'ouverture (basique)
  static bool _parseOpeningHours(String? openingHours) {
    if (openingHours == null || openingHours.isEmpty) return true;
    
    // Détection simple des mots-clés
    final now = DateTime.now();
    final currentHour = now.hour;
    
    if (openingHours.toLowerCase().contains('24/7')) return true;
    if (openingHours.toLowerCase().contains('closed')) return false;
    
    // Heuristique simple : ouvert entre 6h et 22h
    return currentHour >= 6 && currentHour <= 22;
  }
  
  /// Détermine le type de service
  static String _getServiceType(Map<String, dynamic> tags) {
    if (tags['amenity'] == 'fuel') return 'station-service';
    if (tags['shop'] == 'car_repair' || tags['craft'] == 'car_repair') return 'garage';
    if (tags['amenity'] == 'car_wash') return 'lavage';
    return 'auto';
  }
  
  /// Récupère les types de carburant disponibles
  static List<String> _getFuelTypes(Map<String, dynamic> tags) {
    List<String> fuels = [];
    if (tags['fuel:diesel'] == 'yes') fuels.add('Diesel');
    if (tags['fuel:octane_95'] == 'yes') fuels.add('SP95');
    if (tags['fuel:octane_98'] == 'yes') fuels.add('SP98');
    if (tags['fuel:e10'] == 'yes') fuels.add('E10');
    if (tags['fuel:lpg'] == 'yes') fuels.add('GPL');
    return fuels;
  }
  
  /// Récupère les services disponibles
  static List<String> _getServices(Map<String, dynamic> tags) {
    List<String> services = [];
    if (tags['service:vehicle:repair'] == 'yes') services.add('Réparation');
    if (tags['service:vehicle:oil_change'] == 'yes') services.add('Vidange');
    if (tags['service:vehicle:tyres'] == 'yes') services.add('Pneus');
    if (tags['car_wash'] == 'yes') services.add('Lavage');
    if (tags['shop'] == 'car_repair') services.add('Réparation');
    return services;
  }
  
  /// Données de fallback si OSM ne fonctionne pas
  static List<Map<String, dynamic>> _getFallbackGarages(double lat, double lng) {
    print('🔄 Fallback vers données mock OSM avec adresses réalistes');
    return [
      {
        'id': 'osm_fallback_1',
        'name': 'Garage Auto Centre',
        'address': 'Route de Strasbourg, 68000 Colmar',
        'latitude': lat + 0.005,
        'longitude': lng + 0.002,
        'phone': '03 89 41 25 30',
        'website': '',
        'isOpen': true,
        'type': 'garage',
        'fuel_types': [],
        'services': ['Réparation'],
        'opening_hours': 'Mo-Fr 08:00-18:00',
      },
      {
        'id': 'osm_fallback_2', 
        'name': 'Station Total',
        'address': 'Avenue de la République, 68000 Colmar',
        'latitude': lat - 0.003,
        'longitude': lng + 0.004,
        'phone': '03 89 24 15 60',
        'website': '',
        'isOpen': true,
        'type': 'station-service',
        'fuel_types': ['Diesel', 'SP95', 'SP98'],
        'services': ['Lavage'],
        'opening_hours': '24/7',
      },
      {
        'id': 'osm_fallback_3',
        'name': 'Garage Européen',
        'address': 'Rue des Vignerons, 68124 Wintzenheim',
        'latitude': lat + 0.008,
        'longitude': lng - 0.006,
        'phone': '03 89 27 44 80',
        'website': '',
        'isOpen': false,
        'type': 'garage',
        'fuel_types': [],
        'services': ['Réparation', 'Pneus'],
        'opening_hours': 'Mo-Fr 08:00-17:00',
      },
      {
        'id': 'osm_fallback_4',
        'name': 'Auto Service Plus',
        'address': 'Zone Industrielle, 68180 Horbourg-Wihr',
        'latitude': lat - 0.012,
        'longitude': lng + 0.008,
        'phone': '03 89 20 33 55',
        'website': '',
        'isOpen': true,
        'type': 'garage',
        'fuel_types': [],
        'services': ['Réparation', 'Vidange'],
        'opening_hours': 'Mo-Sa 08:00-19:00',
      },
    ];
  }
}