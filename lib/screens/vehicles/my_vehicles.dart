import 'package:flutter/material.dart';
import 'package:save_your_car/api_service/user_vehicles.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'package:save_your_car/services/stripe_service.dart';
import 'package:save_your_car/screens/paywallScreen.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/widgets/Main_scaffold.dart';
import 'package:save_your_car/widgets/home_header.dart';
import 'package:save_your_car/widgets/search_bar.dart' as searchBar;
import 'package:save_your_car/widgets/vehicle_card.dart';

class MyVehicles extends StatefulWidget {
  const MyVehicles({super.key});

  @override
  State<MyVehicles> createState() => _MyVehiclesState();
}

class _MyVehiclesState extends State<MyVehicles> {
  List<VehicleData> vehicles = [];
  bool isLoading = true;
  bool hasActiveSubscription = false;
  static const int maxFreeVehicles = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadVehicles(),
      _checkSubscriptionStatus(),
    ]);
  }

  Future<void> _loadVehicles() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ Aucun token trouvé');
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      final userVehicles = await getUserVehicles(token);
      setState(() {
        vehicles = userVehicles;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement véhicules: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _checkSubscriptionStatus() async {
    try {
      final hasActive = await StripeService.hasActiveSubscription();
      setState(() {
        hasActiveSubscription = hasActive;
      });
    } catch (e) {
      print('Erreur vérification abonnement: $e');
      setState(() {
        hasActiveSubscription = false;
      });
    }
  }

  Future<void> _handleAddVehicle() async {
    // Vérifier la limitation des véhicules
    if (!hasActiveSubscription && vehicles.length >= maxFreeVehicles) {
      _showSubscriptionRequired();
      return;
    }

    // Naviguer vers l'ajout de véhicule
    final result = await Navigator.pushNamed(context, '/matricule');
    
    // Recharger les véhicules si un véhicule a été ajouté
    if (result == true) {
      await _loadVehicles();
    }
  }

  

  void _showSubscriptionRequired() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limite atteinte'),
        content: Text(
          'Vous pouvez enregistrer jusqu\'à $maxFreeVehicles véhicules gratuitement.\n\n'
          'Abonnez-vous à Save Your Car Plus+ pour ajouter des véhicules illimités !',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PaywallScreen(),
                ),
              ).then((_) => _checkSubscriptionStatus()); // Recharger après retour
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FigmaColors.primaryMain,
            ),
            child: const Text(
              'S\'abonner',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canAddVehicle = hasActiveSubscription || vehicles.length < maxFreeVehicles;
    
    return MainScaffold(
      currentIndex: 1,
      child: Scaffold(
        
        body: Column(
          children: [
            // Header et search bar fixes
            Stack(
              clipBehavior: Clip.none,
              children: [
                const HomeHeader(),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: -28,
                  child: const searchBar.SearchBar(),
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Indicateur de limitation pour les utilisateurs gratuits
            if (!hasActiveSubscription && vehicles.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FigmaColors.primaryMain.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: FigmaColors.primaryMain.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: FigmaColors.primaryMain,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${vehicles.length}/$maxFreeVehicles véhicules gratuits utilisés',
                        style: TextStyle(
                          color: FigmaColors.primaryMain,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Liste scrollable uniquement
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vehicles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.directions_car_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Aucun véhicule enregistré',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Appuyez sur + pour ajouter votre premier véhicule',
                                style: TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: vehicles.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: VehicleCard(vehicle: vehicles[index]),
                          ),
                        ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _handleAddVehicle,
          backgroundColor: canAddVehicle 
              ? FigmaColors.primaryMain 
              : Colors.grey[400],
          child: Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
