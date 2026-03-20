import 'package:flutter/material.dart';
import 'package:save_your_car/api_service/user_vehicles.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/services/auth_service.dart';
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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        setState(() => isLoading = false);
        return;
      }
      final userVehicles = await getUserVehicles(token);
      setState(() {
        vehicles = userVehicles;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleAddVehicle() async {
    await Navigator.pushNamed(context, '/matricule');
    await _loadVehicles();
  }

  List<VehicleData> get filteredVehicles {
    if (_searchQuery.isEmpty) return vehicles;
    final query = _searchQuery.toLowerCase();
    return vehicles.where((v) =>
      v.plate.toLowerCase().contains(query) ||
      v.model.toLowerCase().contains(query) ||
      v.brand.toLowerCase().contains(query),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final displayVehicles = filteredVehicles;

    return MainScaffold(
      currentIndex: 1,
      child: Scaffold(
        body: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const HomeHeader(),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: -28,
                  child: searchBar.SearchBar(
                    onSearchChanged: (query) => setState(() => _searchQuery = query),
                    onClear: () => setState(() => _searchQuery = ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : vehicles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text('Aucun véhicule enregistré', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              const SizedBox(height: 8),
                              const Text('Appuyez sur + pour ajouter votre premier véhicule', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            ],
                          ),
                        )
                      : displayVehicles.isEmpty
                          ? Center(child: Text('Aucun véhicule trouvé pour "$_searchQuery"', style: const TextStyle(fontSize: 16, color: Colors.grey)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: displayVehicles.length,
                              itemBuilder: (context, index) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: VehicleCard(vehicle: displayVehicles[index]),
                              ),
                            ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _handleAddVehicle,
          backgroundColor: FigmaColors.primaryMain,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
