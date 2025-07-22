import 'package:flutter/material.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/screens/auth/sign_up_screen.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/widgets/stepper_components.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'package:save_your_car/api_service/user_vehicles.dart';
import 'package:save_your_car/services/notification_service.dart';
import 'package:intl/intl.dart';

class TechnicalControlScreen extends StatefulWidget {
  final VehicleData vehicle;

  const TechnicalControlScreen({super.key, required this.vehicle});

  @override
  State<TechnicalControlScreen> createState() => _TechnicalControlScreenState();
}

class _TechnicalControlScreenState extends State<TechnicalControlScreen> {
  DateTime? selectedDate;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Utiliser la date de contrôle technique de l'API SIV comme valeur par défaut
    selectedDate = widget.vehicle.technicalControlDate;
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> _handleContinue() async {
    final updatedVehicle = widget.vehicle.copyWith(
      technicalControlDate: selectedDate!,
    );

    // Vérifier si l'utilisateur est connecté
    final token = await AuthService.getToken();
    
    if (token != null) {
      // Utilisateur connecté : enregistrer directement le véhicule
      await _saveVehicleForLoggedUser(updatedVehicle, token);
    } else {
      // Utilisateur non connecté : aller vers l'inscription
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignUpScreen(vehicle: updatedVehicle),
        ),
      );
    }
  }

  Future<void> _saveVehicleForLoggedUser(VehicleData vehicle, String token) async {
    setState(() {
      isLoading = true;
    });

    try {
      final success = await createVehicle(vehicle, token);
      
      if (success && mounted) {
        // Programmer les notifications de contrôle technique si la date est définie
        if (vehicle.technicalControlDate != null && vehicle.id != null) {
          await NotificationService.scheduleTechnicalControlReminder(
            vehicleId: vehicle.id!,
            vehiclePlate: vehicle.plate,
            technicalControlDate: vehicle.technicalControlDate!,
          );
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Véhicule ajouté avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Retourner à la liste des véhicules avec un résultat positif
        Navigator.of(context).popUntil((route) => route.settings.name == '/vehicles' || route.isFirst);
      } else {
        throw Exception('Erreur lors de l\'enregistrement');
      }
    } catch (e) {
      print('❌ Erreur sauvegarde véhicule: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        selectedDate != null
            ? DateFormat('dd/MM/yyyy').format(selectedDate!)
            : 'Sélectionnez une date';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE4E4E4)),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 10.9),
                  Row(
                    children: [
                      StepDot(isActive: false),
                      StepLine(isActive: false),
                      StepDot(isActive: false),
                      StepLine(isActive: false),
                      StepDot(isActive: true),
                    ],
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Date du contrôle technique',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Merci d’indiquer la date de votre dernier contrôle technique.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: FigmaColors.neutral70,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: FigmaColors.primaryFocus,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: (selectedDate != null && !isLoading) 
                    ? _handleContinue 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: FigmaColors.primaryMain,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Center(
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Continuer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
