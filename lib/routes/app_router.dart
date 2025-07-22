import 'package:flutter/material.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/screens/appointment_screen.dart';
import 'package:save_your_car/screens/auth/login_screen.dart';
import 'package:save_your_car/screens/auth/sign_up_screen.dart';
import 'package:save_your_car/screens/auth/welcome_screen.dart';
import 'package:save_your_car/screens/auth/forgot_password_screen.dart';
import 'package:save_your_car/screens/cameraDocumentScreen.dart';
import 'package:save_your_car/screens/home/home_screen.dart';
import 'package:save_your_car/screens/profil.dart';
import 'package:save_your_car/screens/simple_document_scanner.dart';
import 'package:save_your_car/screens/vehicle/matricule_screen.dart';
import 'package:save_your_car/screens/vehicles/my_vehicles.dart';

import '../screens/splash/splash_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const SplashScreen(),
  '/welcome': (context) => const WelcomeScreen(),
  '/login': (context) => const LoginScreen(),
  '/forgot_password': (context) => const ForgotPasswordScreen(),
  '/sign_up': (context) =>  SignUpScreen(vehicle: null,),
  
  '/matricule': (context) => MatriculeScreen(),
  
  '/home': (context) => const HomeScreen(),
  '/vehicles':(context) => const MyVehicles(),
  '/scanner': (context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    VehicleData vehicle;
    
    if (arguments is VehicleData) {
      vehicle = arguments;
    } else if (arguments is Map<String, dynamic>) {
      // Ancienne compatibilité pour les arguments en Map
      vehicle = VehicleData.fromJson(arguments);
    } else {
      // Fallback par défaut
      vehicle = VehicleData(plate: 'TEMP', model: 'Unknown', brand: 'Unknown');
    }
    
    return ScannerDocumentScreen(vehicle: vehicle);
  },
  '/document_scanner': (context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    VehicleData? vehicle;
    
    if (arguments is VehicleData) {
      vehicle = arguments;
    } else if (arguments is Map<String, dynamic>) {
      try {
        vehicle = VehicleData.fromJson(arguments);
      } catch (e) {
        print('Erreur parsing VehicleData: $e');
      }
    }
    
    if (vehicle == null) {
      return const Scaffold(
        body: Center(child: Text('Erreur: Véhicule non spécifié')),
      );
    }
    
    return SimpleDocumentScanner(vehicle: vehicle);
  },
  '/calendar':(context) => const AppointmentScreen(), 
  '/profile': (context) => const ProfileScreen(),
};
