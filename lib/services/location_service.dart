import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  
  /// Vérifie et demande les permissions de localisation
  static Future<bool> requestLocationPermission() async {
    try {
      // Vérifier d'abord le statut actuel
      PermissionStatus status = await Permission.locationWhenInUse.status;
      print('🔍 Statut permission actuel: $status');
      
      // Si déjà accordée, retourner true
      if (status.isGranted) {
        print('✅ Permission déjà accordée');
        return true;
      }
      
      // Si refusée définitivement, ouvrir les paramètres
      if (status.isPermanentlyDenied) {
        print('⚠️ Permission définitivement refusée - ouverture paramètres');
        await openAppSettings();
        return false;
      }
      
      // Si refusée, essayer avec Geolocator
      if (status.isDenied) {
        print('🔄 Tentative avec Geolocator...');
        LocationPermission geoPermission = await Geolocator.checkPermission();
        print('📍 Permission Geolocator: $geoPermission');
        
        if (geoPermission == LocationPermission.denied) {
          geoPermission = await Geolocator.requestPermission();
          print('📍 Nouvelle permission Geolocator: $geoPermission');
          
          if (geoPermission == LocationPermission.whileInUse || 
              geoPermission == LocationPermission.always) {
            return true;
          }
        }
      }
      
      // Demander la permission avec permission_handler
      print('🔄 Demande permission avec permission_handler...');
      PermissionStatus permission = await Permission.locationWhenInUse.request();
      print('📱 Résultat permission_handler: $permission');
      
      if (permission.isPermanentlyDenied) {
        await openAppSettings();
        return false;
      }
      
      return permission.isGranted;
    } catch (e) {
      print('❌ Erreur demande permission: $e');
      return false;
    }
  }
  
  /// Vérifie si le service de localisation est activé
  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('Erreur vérification service localisation: $e');
      return false;
    }
  }
  
  /// Récupère la position actuelle de l'utilisateur
  static Future<Position?> getCurrentPosition() async {
    try {
      print('📍 Récupération de la position...');
      
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Service de localisation désactivé');
        throw Exception('Le service de localisation est désactivé. Activez-le dans les paramètres.');
      }
      
      // Vérifier les permissions
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('❌ Permission de localisation refusée');
        throw Exception('Permission de localisation refusée. Accordez les autorisations dans les paramètres.');
      }
      
      // Récupérer la position avec une configuration optimisée
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      
      print('✅ Position récupérée: ${position.latitude}, ${position.longitude}');
      return position;
      
    } catch (e) {
      print('❌ Erreur récupération position: $e');
      if (e.toString().contains('Permission') || e.toString().contains('location')) {
        throw Exception('Impossible de récupérer votre position. Vérifiez que les autorisations de localisation sont accordées pour l\'application.');
      }
      throw Exception('Erreur lors de la récupération de votre position: ${e.toString()}');
    }
  }
  
  /// Calcule la distance entre deux points en kilomètres
  static double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    try {
      double distanceInMeters = Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      );
      
      // Convertir en kilomètres et arrondir à 1 décimale
      return double.parse((distanceInMeters / 1000).toStringAsFixed(1));
    } catch (e) {
      print('Erreur calcul distance: $e');
      return 0.0;
    }
  }
  
  /// Formate la distance pour l'affichage
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    } else {
      return '${distanceKm.toStringAsFixed(1)} km';
    }
  }
  
  /// Vérifie si une position est dans un rayon donné (en km)
  static bool isWithinRadius(
    double centerLat,
    double centerLng,
    double targetLat,
    double targetLng,
    double radiusKm,
  ) {
    double distance = calculateDistance(centerLat, centerLng, targetLat, targetLng);
    return distance <= radiusKm;
  }
}