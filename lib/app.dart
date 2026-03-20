// ignore_for_file: empty_catches

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/screens/vehicle/klm_screen.dart';
import 'routes/app_router.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    // Cold start: app launched from deep link
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(initialLink);
        });
      }
    } catch (_) {}

    // App already running: deep link received
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'saveyourcar' && uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        navigatorKey.currentState?.pushNamed('/reset_password', arguments: token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
            } catch (e) {}
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
