// ignore_for_file: empty_catches

import 'package:flutter/material.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/screens/vehicle/klm_screen.dart';
import 'routes/app_router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
  debugShowCheckedModeBanner: false,
  initialRoute: '/',
  routes: appRoutes,
  onGenerateRoute: (settings) {
    if (settings.name == '/klm') {
      final arguments = settings.arguments;
      VehicleData? vehicle;
      
      if (arguments is VehicleData) {
        vehicle = arguments;
      } else if (arguments is Map<String, dynamic>) {
        try {
          vehicle = VehicleData.fromJson(arguments);
        } catch (e) {
        }
      }
      
      if (vehicle != null) {
        return MaterialPageRoute(
          builder: (_) => KlmScreen(vehicle: vehicle!),
        );
      } else {
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Erreur: Données véhicule invalides')),
          ),
        );
      }
    }
    return null;
  },
);
  }
}
