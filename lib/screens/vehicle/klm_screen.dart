import 'package:flutter/material.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/widgets/stepper_components.dart';
import 'technical_control_screen.dart';

class KlmScreen extends StatefulWidget {
  final VehicleData vehicle;
  const KlmScreen({super.key, required this.vehicle});

  static Route route(RouteSettings settings) {
    final arguments = settings.arguments;
    VehicleData? vehicle;
    
    if (arguments is VehicleData) {
      vehicle = arguments;
    } else if (arguments is Map<String, dynamic>) {
      try {
        vehicle = VehicleData.fromJson(arguments);
      } catch (e) {
        print('Erreur parsing VehicleData pour KlmScreen: $e');
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

  @override
  State<KlmScreen> createState() => _KlmScreenState();
}

class _KlmScreenState extends State<KlmScreen> {
  final TextEditingController _kmController = TextEditingController();

  @override
  void dispose() {
    _kmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              const SizedBox(height: 40),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_left, size: 20, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10.9),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      StepDot(isActive: false),
                      StepLine(isActive: false),
                      StepDot(isActive: true),
                      StepLine(isActive: false),
                      StepDot(isActive: false),
                    ],
                  ),
                  const SizedBox(width: 40),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Renseignez Vos Informations Concernant Le Véhicule',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Pour accéder aux caractéristiques techniques de votre véhicule, merci de fournir les informations demandées dans les champs prévus à cet effet.',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                  color: FigmaColors.neutral70,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                height: 201,
                decoration: BoxDecoration(
                  color: FigmaColors.primaryFocus,
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.only(left: 16, right: 16, top: 46, bottom: 67),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quel est le kilométrage de votre véhicule ?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Plus Jakarta Sans',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _kmController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: FigmaColors.neutral10,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        hintText: '125356 km',
                        hintStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFC9C8C9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      child: const Text(
                        'Ignorer cette étape',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final km = int.tryParse(_kmController.text.replaceAll(' ', ''));
                        if (km != null) {
                          final updatedVehicle = widget.vehicle.copyWith(mileage: km);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TechnicalControlScreen(vehicle: updatedVehicle),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Veuillez entrer un kilométrage valide')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        
                        backgroundColor: FigmaColors.primaryMain,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                          side: const BorderSide(color: FigmaColors.primaryMain, width: 2),
                        ),
                      ),
                      child: const Text(
                        'Continuer',
                        style: TextStyle(
                          inherit: true,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
