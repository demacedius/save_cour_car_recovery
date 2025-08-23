import 'package:flutter/material.dart';
import 'package:auth_buttons/auth_buttons.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'package:save_your_car/services/notification_service.dart';
import 'package:save_your_car/theme/figma_color.dart';


class SignUpScreen extends StatefulWidget {
  final VehicleData? vehicle;

  const SignUpScreen({super.key, this.vehicle});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  /// Formate une date pour être compatible avec le backend Go (RFC3339)
  String? _formatDateForBackend(DateTime? date) {
    if (date == null) return null;
    // Format RFC3339 attendu par Go: 2006-01-02T15:04:05Z07:00
    return date.toUtc().toIso8601String();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            children: [
            Stack(
              children: [
                // Image de fond - responsive height
                Image.asset(
                  "assets/images/Group 1bg.png",
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height < 700 ? 250 : 300,
                  fit: BoxFit.cover,
                ),
                // Contenu superposé
                Positioned.fill(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bouton retour
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 8),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            size: 20,
                            color: Colors.black,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Logo et texte centrés
                      Center(
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/images/Group 1.png",
                              width: 60,
                              height: 60,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Créer Votre Compte',
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 400 ? 20 : 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Créer un compte pour profiter d\'une\nexpérience personnalisé',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: MediaQuery.of(context).size.width < 400 ? 12 : 14,
                                color: Color(0xFF666666),
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 24,
              ),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height < 700 ? 16 : 32),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.email_outlined,
                        color: Colors.grey[400],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Mot de passe',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey[400],
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Confirmer le mot de passe',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.lock_outline,
                        color: Colors.grey[400],
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF6C63FF)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : registerUser,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FigmaColors.primaryMain,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Inscription',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(color: Color(0xFFE5E5E5), thickness: 1),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Continuer avec',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: Color(0xFFE5E5E5), thickness: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Déjà un compte? ',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login');
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFF6C63FF),
                        ),
                        child: const Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height < 700 ? 16 : 24),
                ],
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> registerUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // Validation des champs
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre email')),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Format d\'email invalide')),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir votre mot de passe')),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le mot de passe doit contenir au moins 6 caractères')),
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez confirmer votre mot de passe')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Préparer les données du véhicule si disponibles
      Map<String, dynamic>? vehicleData;
      if (widget.vehicle != null) {
        vehicleData = {
          'fullName': '', // Vous pouvez ajouter un champ nom dans le formulaire
          'plate': widget.vehicle!.plate,
          'model': widget.vehicle!.model,
          'brand': widget.vehicle!.brand,
          'year': widget.vehicle!.year,
          'mileage': widget.vehicle!.mileage,
          'technicalControlDate': _formatDateForBackend(widget.vehicle!.technicalControlDate),
          'technical_control_date': _formatDateForBackend(widget.vehicle!.technicalControlDate), // Format snake_case pour le backend
          'imageUrl': widget.vehicle!.imageUrl,
          'brandImageUrl': widget.vehicle!.brandImageUrl,
        };
        
        // Debug : Afficher les données envoyées
        print('🚗 Données véhicule envoyées pour inscription:');
        print('  - Plaque: ${vehicleData['plate']}');
        print('  - Modèle: ${vehicleData['model']}');
        print('  - Marque: ${vehicleData['brand']}');
        print('  - Année: ${vehicleData['year']}');
        print('  - Kilométrage: ${vehicleData['mileage']}');
        print('  - Date contrôle technique (camelCase): ${vehicleData['technicalControlDate']}');
        print('  - Date contrôle technique (snake_case): ${vehicleData['technical_control_date']}');
        print('  - Date originale Flutter: ${widget.vehicle!.technicalControlDate}');
      }

      final result = await AuthService.register(email, password, vehicleData: vehicleData);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
         if (widget.vehicle?.technicalControlDate != null) {
          await NotificationService.scheduleTechnicalControlReminder(
            vehicleId: widget.vehicle!.id ?? 0,
            vehiclePlate: widget.vehicle!.plate,
            technicalControlDate: widget.vehicle!.technicalControlDate!,
          );
        }

        // Si l'inscription inclut une connexion automatique
        if (result['autoLogin'] == true) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          // Rediriger vers la page de connexion
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
