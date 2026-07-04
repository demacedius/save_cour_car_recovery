import 'dart:math';
import 'package:flutter/material.dart';
import 'package:save_your_car/api_service/api_service.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/widgets/stepper_components.dart';
import 'klm_screen.dart';

class MatriculeScreen extends StatefulWidget {
  const MatriculeScreen({super.key});

  @override
  State<MatriculeScreen> createState() => _MatriculeScreenState();
}

class _MatriculeScreenState extends State<MatriculeScreen> {
  final TextEditingController _plateController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _continuer() async {
    final plate = _plateController.text.trim().toUpperCase();
    if (plate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer votre plaque d\'immatriculation')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vehicle = await fetchVehicleInfo(plate);
      if (!mounted) return;

      if (vehicle != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => KlmScreen(vehicle: vehicle)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Véhicule introuvable. Vous pouvez saisir les informations manuellement.'),
            duration: Duration(seconds: 3),
          ),
        );
        _showManualEntrySheet(plate);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showManualEntrySheet(String plate) {
    final brandController = TextEditingController();
    final modelController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: FigmaColors.neutral30,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Saisie manuelle',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Votre plaque n\'a pas été trouvée dans la base SIV. Renseignez votre véhicule manuellement.',
              style: TextStyle(fontSize: 14, color: FigmaColors.neutral70, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: brandController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Marque',
                hintText: 'Ex : Renault, Peugeot...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FigmaColors.primaryMain),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: modelController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Modèle',
                hintText: 'Ex : Clio, 308...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: FigmaColors.primaryMain),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final brand = brandController.text.trim();
                  final model = modelController.text.trim();
                  if (brand.isEmpty || model.isEmpty) {
                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                      const SnackBar(content: Text('Veuillez renseigner la marque et le modèle')),
                    );
                    return;
                  }
                  final vehicle = VehicleData(
                    plate: plate.isNotEmpty ? plate : 'MANUEL',
                    brand: brand,
                    model: model,
                  );
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => KlmScreen(vehicle: vehicle)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: FigmaColors.primaryMain,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                ),
                child: const Text(
                  'Continuer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Center(
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
                          ),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.chevron_left, size: 20, color: Colors.black),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.9),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          StepDot(isActive: true),
                          StepLine(isActive: false),
                          StepDot(isActive: false),
                          StepLine(isActive: false),
                          StepDot(isActive: false),
                        ],
                      ),
                      const SizedBox(width: 40),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Entrez votre plaque d\'immatriculation',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pour accéder aux données de votre véhicule, veuillez entrer votre plaque d\'immatriculation.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 24 / 16,
                      color: FigmaColors.neutral70,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 201,
                    decoration: BoxDecoration(
                      color: FigmaColors.primaryFocus,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: FigmaColors.neutral70, width: 3),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              decoration: const BoxDecoration(
                                color: Color(0xFF003399),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  bottomLeft: Radius.circular(4),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Stack(
                                      children: List.generate(12, (index) {
                                        final angle = (index * (2 * 3.14159) / 12);
                                        const radius = 8.0;
                                        return Positioned(
                                          left: 12 + radius * cos(angle),
                                          top: 12 + radius * sin(angle),
                                          child: Transform.rotate(
                                            angle: angle + 3.14159 / 2,
                                            child: const Icon(Icons.star, color: Colors.yellow, size: 4),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  const Text(
                                    'FR',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _plateController,
                                textAlign: TextAlign.center,
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  hintText: 'AA-123-AA',
                                  hintStyle: TextStyle(
                                    color: FigmaColors.neutral50,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                                ),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 16 : 0,
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _continuer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FigmaColors.primaryMain,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Continuer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showManualEntrySheet(
                            _plateController.text.trim().toUpperCase(),
                          ),
                          child: const Text(
                            'Saisir manuellement',
                            style: TextStyle(
                              color: FigmaColors.neutral70,
                              fontSize: 14,
                              fontFamily: 'Poppins',
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
