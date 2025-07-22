import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:save_your_car/services/location_service.dart';
import 'package:save_your_car/services/openstreetmap_service.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:url_launcher/url_launcher.dart';

class GarageListScreen extends StatefulWidget {
  const GarageListScreen({super.key});

  @override
  State<GarageListScreen> createState() => _GarageListScreenState();
}

class _GarageListScreenState extends State<GarageListScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> garages = [];
  String? errorMessage;
  Position? userPosition;

  @override
  void initState() {
    super.initState();
    _loadGarages();
  }

  Future<void> _loadGarages() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. Récupérer la position de l'utilisateur
      print('📍 Récupération de la position...');
      Position? position = await LocationService.getCurrentPosition();
      
      if (position == null) {
        throw Exception('Impossible de récupérer votre position. Vérifiez que la localisation est activée.');
      }
      
      userPosition = position;
      print('✅ Position récupérée: ${position.latitude}, ${position.longitude}');
      
      // 2. Rechercher les garages à proximité
      print('🔍 Recherche des garages...');
      List<Map<String, dynamic>> nearbyGarages = await OpenStreetMapService.findNearbyGarages(
        latitude: position.latitude,
        longitude: position.longitude,
        limit: 20,
        radiusMeters: 15000.0, // Rayon élargi à 15km
      );
      
      // Si aucun garage trouvé, ajouter des données mock pour éviter un écran vide
      if (nearbyGarages.isEmpty) {
        print('⚠️ Aucun garage trouvé via API, ajout de données mock');
        nearbyGarages = await OpenStreetMapService.findNearbyGarages(
          latitude: position.latitude,
          longitude: position.longitude,
          limit: 5,
          radiusMeters: 10000.0,
        );
      }
      
      // 3. Calculer les distances et trier par proximité
      for (var garage in nearbyGarages) {
        double distance = LocationService.calculateDistance(
          position.latitude,
          position.longitude,
          garage['latitude'],
          garage['longitude'],
        );
        garage['distance'] = distance;
        garage['distanceFormatted'] = LocationService.formatDistance(distance);
      }
      
      // Trier par distance croissante
      nearbyGarages.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      
      if (mounted) {
        setState(() {
          garages = nearbyGarages;
          isLoading = false;
        });
      }
      
      print('✅ ${garages.length} garages trouvés et triés par distance');
      
    } catch (e) {
      print('❌ Erreur lors du chargement des garages: $e');
      if (mounted) {
        setState(() {
          errorMessage = e.toString();
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaColors.neutral00,
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bouton back
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: FigmaColors.neutral10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: FigmaColors.neutral90),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Garages à proximité',
                      style: FigmaTextStyles().headingLBold,
                    ),
                  ),
                ],
              ),
            ),

            // Contenu principal
            Expanded(
              child: isLoading 
                ? _buildLoadingState()
                : errorMessage != null
                    ? _buildErrorState()
                    : garages.isEmpty
                        ? _buildEmptyState()
                        : _buildGaragesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(FigmaColors.primaryMain),
          ),
          const SizedBox(height: 24),
          Text(
            'Recherche des garages à proximité...',
            style: FigmaTextStyles().textMSemiBold.copyWith(
              color: FigmaColors.neutral80,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Localisation en cours...',
            style: FigmaTextStyles().textMRegular.copyWith(
              color: FigmaColors.neutral70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de localisation',
              style: FigmaTextStyles().textLBold.copyWith(
                color: FigmaColors.neutral80,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Une erreur est survenue',
              textAlign: TextAlign.center,
              style: FigmaTextStyles().textMRegular.copyWith(
                color: FigmaColors.neutral70,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadGarages,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FigmaColors.primaryMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.location_off,
            size: 64,
            color: FigmaColors.neutral60,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun garage trouvé',
            style: FigmaTextStyles().textLBold.copyWith(
              color: FigmaColors.neutral80,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez d\'élargir votre zone de recherche',
            style: FigmaTextStyles().textMRegular.copyWith(
              color: FigmaColors.neutral70,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadGarages,
            icon: const Icon(Icons.refresh),
            label: const Text('Rechercher à nouveau'),
            style: ElevatedButton.styleFrom(
              backgroundColor: FigmaColors.primaryMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaragesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: garages.length,
      itemBuilder: (context, index) {
        final garage = garages[index];
        return _buildGarageCard(garage);
      },
    );
  }

  Widget _buildGarageCard(Map<String, dynamic> garage) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: FigmaColors.neutral20,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec nom et statut
          Row(
            children: [
              Expanded(
                child: Text(
                  garage['name'],
                  style: FigmaTextStyles().textLBold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: garage['isOpen'] 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  garage['isOpen'] ? 'Ouvert' : 'Fermé',
                  style: FigmaTextStyles().captionSMedium.copyWith(
                    color: garage['isOpen'] ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Adresse
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: FigmaColors.neutral70),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  garage['address'],
                  style: FigmaTextStyles().textMRegular.copyWith(
                    color: FigmaColors.neutral70,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Distance et téléphone
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FigmaColors.primaryFocus,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  garage['distanceFormatted'] ?? '-- km',
                  style: FigmaTextStyles().captionSMedium.copyWith(
                    color: FigmaColors.primaryMain,
                  ),
                ),
              ),
              const Spacer(),
              // Bouton téléphone
              Container(
                decoration: BoxDecoration(
                  color: FigmaColors.neutral20,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.info_outline, color: FigmaColors.primaryMain),
                  onPressed: () => _openGarageInfo(
                    garage['latitude'],
                    garage['longitude'],
                    garage['name'],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Bouton itinéraire
              Container(
                decoration: BoxDecoration(
                  color: FigmaColors.primaryMain,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(Icons.directions, color: Colors.white),
                  onPressed: () => _openDirections(
                    garage['latitude'],
                    garage['longitude'],
                    garage['name'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Ouvre la page web du garage avec toutes les infos
  Future<void> _openGarageInfo(double latitude, double longitude, String name) async {
    print('🌐 Ouverture page garage: $name');

    try {
      // Créer une recherche Google du garage avec sa position
      final query = Uri.encodeComponent('$name garage $latitude,$longitude');
      final searchUrl = 'https://www.google.com/search?q=$query';
      
      print('🔗 URL: $searchUrl');
      
      await launchUrl(
        Uri.parse(searchUrl),
        mode: LaunchMode.externalApplication,
      );
      
    } catch (e) {
      print('❌ Erreur ouverture page: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recherchez "$name" dans votre navigateur'),
            duration: const Duration(seconds: 4),
            backgroundColor: FigmaColors.primaryMain,
          ),
        );
      }
    }
  }

  /// Ouvre Google Maps avec navigation vers le garage
  Future<void> _openDirections(double latitude, double longitude, String name) async {
    print('🗺️ Ouverture navigation vers: $latitude, $longitude ($name)');
    
    try {
      // URL Google Maps avec navigation directe
      final mapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_id=$name';
      print('🔗 URL Maps: $mapsUrl');
      
      await launchUrl(
        Uri.parse(mapsUrl),
        mode: LaunchMode.externalApplication,
      );
      
    } catch (e) {
      print('❌ Erreur navigation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cherchez "$name" dans Google Maps'),
            duration: const Duration(seconds: 4),
            backgroundColor: FigmaColors.primaryMain,
          ),
        );
      }
    }
  }
}