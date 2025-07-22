import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  
  /// Vérifie et demande les permissions de localisation
  static Future<bool> requestLocationPermission() async {
    try {
      // Vérifier le statut actuel de la permission
      PermissionStatus permission = await Permission.locationWhenInUse.status;
      
      if (permission.isDenied) {
        // Demander la permission
        permission = await Permission.locationWhenInUse.request();
      }
      
      if (permission.isPermanentlyDenied) {
        // Ouvrir les paramètres si la permission est définitivement refusée
        await openAppSettings();
        return false;
      }
      
      return permission.isGranted;
    } catch (e) {
      print('Erreur demande permission: $e');
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
      // Vérifier si le service de localisation est activé
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Service de localisation désactivé');
        return null;
      }
      
      // Vérifier les permissions
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        print('❌ Permission de localisation refusée');
        return null;
      }
      
      // Récupérer la position avec une configuration optimisée
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10), // Timeout de 10 secondes
      );
      
      print('✅ Position récupérée: ${position.latitude}, ${position.longitude}');
      return position;
      
    } catch (e) {
      print('❌ Erreur récupération position: $e');
      return null;
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