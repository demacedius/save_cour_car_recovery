// ignore_for_file: use_build_context_synchronously, duplicate_ignore, empty_catches, deprecated_member_use

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/services/document_service.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/responsive_helper.dart';

class ScannerDocumentScreen extends StatefulWidget {
  final VehicleData vehicle;

  const ScannerDocumentScreen({super.key, required this.vehicle});

  @override
  State<ScannerDocumentScreen> createState() => _ScannerDocumentScreenState();
}

class _ScannerDocumentScreenState extends State<ScannerDocumentScreen> {
  CameraController? controller;
  final ImagePicker _picker = ImagePicker();
  List<File> capturedImages = [];
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
    );

    controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await controller?.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (controller == null || !controller!.value.isInitialized) return;

    try {
      final XFile photo = await controller!.takePicture();
      setState(() {
        capturedImages.add(File(photo.path));
      });


      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Photo ${capturedImages.length} capturée!')),
      );
    // ignore: empty_catches
    } catch (e) {
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          capturedImages.add(File(image.path));
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image ${capturedImages.length} ajoutée!')),
        );
      }
    } catch (e) {
    }
  }

  Future<void> _createPdfAndUpload() async {

    if (capturedImages.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Aucune image capturée!')));
      return;
    }

    setState(() {
      isProcessing = true;
    });


    try {
      // Créer le PDF
      final pdf = pw.Document();

      for (int i = 0; i < capturedImages.length; i++) {
        final imageFile = capturedImages[i];
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
            },
          ),
        );
      }

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfPath =
          '${directory.path}/document_${widget.vehicle.plate}_$timestamp.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());


      // Afficher la boîte de dialogue pour les métadonnées
      await _showDocumentInfoDialog(pdfFile);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création du PDF: $e')),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  Future<void> _showDocumentInfoDialog(File pdfFile) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedType = 'carte_grise';

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Informations du document',
              style: TextStyle(
                fontSize: ResponsiveHelper.isMobile(context) ? 16 : 18,
              ),
            ),
            content: SingleChildScrollView(
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom du document',
                        hintText: 'Ex: Carte grise 2024',
                      ),
                    ),
                    SizedBox(height: ResponsiveHelper.isMobile(context) ? 12 : 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Type de document',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'carte_grise',
                          child: Text('Carte grise'),
                        ),
                        DropdownMenuItem(
                          value: 'assurance',
                          child: Text('Assurance'),
                        ),
                        DropdownMenuItem(
                          value: 'controle_technique',
                          child: Text('Contrôle technique'),
                        ),
                        DropdownMenuItem(value: 'facture', child: Text('Facture')),
                        DropdownMenuItem(value: 'autre', child: Text('Autre')),
                      ],
                      onChanged: (value) => selectedType = value!,
                    ),
                    SizedBox(height: ResponsiveHelper.isMobile(context) ? 12 : 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (optionnel)',
                        hintText: 'Détails supplémentaires...',
                      ),
                      maxLines: ResponsiveHelper.isMobile(context) ? 1 : 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Le nom est requis')),
                    );
                    return;
                  }

                  // Upload du document

                  final document = await DocumentService.uploadDocument(
                    vehicleId: widget.vehicle.id ?? 0,
                    name: nameController.text.trim(),
                    type: selectedType,
                    description:
                        descriptionController.text.trim().isEmpty
                            ? null
                            : descriptionController.text.trim(),
                    file: pdfFile,
                  );


                  if (document != null) {
                    Navigator.pop(context, true);
                    Navigator.pop(context); // Retour à l'écran précédent
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Document uploadé avec succès!'),
                      ),
                    );
                  } else {
                    Navigator.pop(context, false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erreur lors de l\'upload')),
                    );
                  }
                },
                child: Text(
                  'Sauvegarder',
                  style: TextStyle(
                    fontSize: ResponsiveHelper.responsiveFontSize(
                      context,
                      mobile: 10,
                      tablet: 14,
                      desktop: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
    );

    // Nettoyer le fichier temporaire si annulé
    if (result != true) {
      await pdfFile.delete();
    }
  }

  void _resetCapture() {
    setState(() {
      capturedImages.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          CameraPreview(controller!),

          // SafeArea + retour
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              height: ResponsiveHelper.isMobile(context) ? 100 : 120,
              color: FigmaColors.neutral100,
              child: Stack(
                children: [
                  Positioned(
                    left: ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
                    top: ResponsiveHelper.isMobile(context) ? 50 : 68,
                    child: Container(
                      width: ResponsiveHelper.isMobile(context) ? 24 : 28,
                      height: ResponsiveHelper.isMobile(context) ? 24 : 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: FigmaColors.neutral00.withOpacity(0.2),
                      ),
                      child: Center(
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          iconSize: ResponsiveHelper.isMobile(context) ? 16 : 20,
                          icon: const Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Overlay de détection du document
          Center(
            child: Container(
              width: ResponsiveHelper.isMobile(context) ? 280 : 300,
              height: ResponsiveHelper.isMobile(context) ? 360 : 400,
              decoration: BoxDecoration(
                border: Border.all(color: FigmaColors.primaryMain, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          height: ResponsiveHelper.isMobile(context) ? 120 : 140,
          margin: EdgeInsets.only(
            bottom: ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 0, desktop: 0),
          ),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Text(
                'Document - ${widget.vehicle.brand.isNotEmpty ? widget.vehicle.brand : 'Marque'} ${widget.vehicle.model.isNotEmpty ? widget.vehicle.model : 'Modèle'}',
                style: TextStyle(
                  color: FigmaColors.primaryMain,
                  fontWeight: FontWeight.bold,
                  fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (capturedImages.isNotEmpty)
                Text(
                  '${capturedImages.length} image(s) capturée(s)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 10, tablet: 12, desktop: 12),
                  ),
                ),
              // Debug info
              Text(
                'Debug: images=${capturedImages.length}, processing=$isProcessing',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 8, tablet: 10, desktop: 10),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.white),
                    onPressed: isProcessing ? null : _pickFromGallery,
                  ),
                  GestureDetector(
                    onTap: isProcessing ? null : _capturePhoto,
                    child: Container(
                      width: ResponsiveHelper.isMobile(context) ? 56 : 64,
                      height: ResponsiveHelper.isMobile(context) ? 56 : 64,
                      decoration: BoxDecoration(
                        color:
                            isProcessing ? Colors.grey : FigmaColors.primaryMain,
                        shape: BoxShape.circle,
                      ),
                      child:
                          isProcessing
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.restart_alt, color: Colors.white),
                    onPressed: isProcessing ? null : _resetCapture,
                  ),
                ],
              ),
              // Bouton principal
              if (capturedImages.isNotEmpty && !isProcessing)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: ElevatedButton.icon(
                    onPressed: _createPdfAndUpload,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Créer PDF et Sauvegarder'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FigmaColors.primaryMain,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              // Bouton debug toujours visible
              if (capturedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ElevatedButton(
                    onPressed:
                        isProcessing
                            ? null
                            : () {
                              _createPdfAndUpload();
                            },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      isProcessing ? 'Processing...' : 'DEBUG: Forcer Sauvegarde',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
