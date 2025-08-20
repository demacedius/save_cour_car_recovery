import 'package:flutter/material.dart';
import 'package:save_your_car/api_service/user_vehicles.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'vehicle_card.dart';

class VehicleListHorizontal extends StatefulWidget {
  const VehicleListHorizontal({super.key});

  @override
  State<VehicleListHorizontal> createState() => _VehicleListHorizontalState();
}

class _VehicleListHorizontalState extends State<VehicleListHorizontal> {
  List<VehicleData> vehicles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVehicles();
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (vehicles.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/matricule');
            },
            child: SizedBox(
              width: double.infinity,
              child: Card(
                color: FigmaColors.neutral10,
                child: const SizedBox(
                  height: 200,
                  child: Center(
                    child: Icon(
                      Icons.add,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: vehicles.length,
        itemBuilder: (context, index) => VehicleCard(vehicle: vehicles[index]),
      ),
    );
  }
}
