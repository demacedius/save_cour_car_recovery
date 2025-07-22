import 'package:save_your_car/services/user_service.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'package:save_your_car/api_service/user_vehicles.dart' as UserVehicles;

class ProgressService {
  static const List<Map<String, dynamic>> _progressItems = [
    {
      'id': 'profile',
      'title': 'Remplir mon profil',
      'description': 'Ajouter prénom, nom et informations personnelles',
      'icon': 'profile',
    },
    {
      'id': 'vehicle',
      'title': 'Ajouter un véhicule',
      'description': 'Enregistrer votre première voiture',
      'icon': 'vehicle',
    },
    {
      'id': 'document',
      'title': 'Ajouter un document',
      'description': 'Scanner votre premier document automobile',
      'icon': 'document',
    },
    {
      'id': 'appointment',
      'title': 'Prendre mon premier rendez-vous',
      'description': 'Planifier un service ou un contrôle',
      'icon': 'appointment',
    },
  ];

  /// Calcule la progression globale (0-100%)
  static Future<Map<String, dynamic>> calculateProgress() async {
    final results = <String, bool>{};
    
    try {
      // 1. Vérifier le profil (prénom + nom remplis)
      final userData = await UserService.getCurrentUser();
      final hasProfile = userData != null && 
                        userData['first_name'] != null && 
                        userData['first_name'].toString().isNotEmpty &&
                        userData['first_name'].toString() != 'null' &&
                        userData['last_name'] != null && 
                        userData['last_name'].toString().isNotEmpty &&
                        userData['last_name'].toString() != 'null';
      results['profile'] = hasProfile;
      
      // 2. Vérifier les véhicules
      try {
        final token = await AuthService.getToken();
        if (token != null) {
          final vehicles = await UserVehicles.getUserVehicles(token);
          final hasVehicle = vehicles.isNotEmpty;
          results['vehicle'] = hasVehicle;
        } else {
          results['vehicle'] = false;
        }
      } catch (e) {
        print('❌ Erreur vérification véhicules: $e');
        results['vehicle'] = false;
      }
      
      // 3. Vérifier les documents (simulé pour l'instant)
      // TODO: Remplacer par un vrai service de documents
      final hasDocument = false; // await DocumentService.hasDocuments();
      results['document'] = hasDocument;
      
      // 4. Vérifier les rendez-vous (simulé pour l'instant) 
      // TODO: Remplacer par un vrai service de rendez-vous
      final hasAppointment = false; // await AppointmentService.hasAppointments();
      results['appointment'] = hasAppointment;
      
    } catch (e) {
      print('❌ Erreur calcul progression: $e');
      // En cas d'erreur, tout marquer comme non fait
      for (final item in _progressItems) {
        results[item['id']] = false;
      }
    }
    
    // Calculer le pourcentage
    final completedCount = results.values.where((completed) => completed).length;
    final totalCount = _progressItems.length;
    final percentage = (completedCount / totalCount * 100).round();
    
    print('🎯 Progression calculée: $completedCount/$totalCount = $percentage%');
    
    return {
      'percentage': percentage,
      'completedCount': completedCount,
      'totalCount': totalCount,
      'results': results,
      'items': _progressItems.map((item) {
        return {
          ...item,
          'completed': results[item['id']] ?? false,
        };
      }).toList(),
    };
  }

  /// Obtient la couleur de la jauge selon le pourcentage
  static String getProgressColor(int percentage) {
    if (percentage >= 100) return 'green';
    if (percentage >= 75) return 'lightGreen';
    if (percentage >= 50) return 'orange';
    if (percentage >= 25) return 'yellow';
    return 'red';
  }

  /// Obtient le message de motivation selon le pourcentage
  static String getMotivationMessage(int percentage) {
    if (percentage >= 100) return '🎉 Félicitations ! Votre profil est complet !';
    if (percentage >= 75) return '🚀 Excellent ! Plus que quelques étapes !';
    if (percentage >= 50) return '💪 Très bien ! Vous êtes à mi-parcours !';
    if (percentage >= 25) return '👍 Bon début ! Continuez comme ça !';
    return '🌟 Commencez votre progression !';
  }
}