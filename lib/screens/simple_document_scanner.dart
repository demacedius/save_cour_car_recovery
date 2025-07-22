import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/services/document_service.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/responsive_helper.dart';

class SimpleDocumentScanner extends StatefulWidget {
  final VehicleData vehicle;
  
  const SimpleDocumentScanner({super.key, required this.vehicle});

  @override
  State<SimpleDocumentScanner> createState() => _SimpleDocumentScannerState();
}

class _SimpleDocumentScannerState extends State<SimpleDocumentScanner> {
  final ImagePicker _picker = ImagePicker();
  List<File> capturedImages = [];
  bool isProcessing = false;

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1200,
        maxHeight: 1600,
      );
      
      if (image != null) {
        setState(() {
          capturedImages.add(File(image.path));
        });
        
        print('📸 Photo capturée! Total: ${capturedImages.length}');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo ${capturedImages.length} capturée!')),
        );
      }
    } catch (e) {
      print('Erreur capture caméra: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur caméra: $e')),
      );
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
      print('Erreur galerie: $e');
    }
  }

  Future<void> _createPdfAndUpload() async {
    print('📄 Début création PDF...');
    print('📄 Nombre d\'images: ${capturedImages.length}');
    
    if (capturedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune image capturée!')),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });
    
    print('📄 Processing démarré...');

    try {
      // Créer le PDF
      print('📄 Création du PDF...');
      final pdf = pw.Document();
      
      for (int i = 0; i < capturedImages.length; i++) {
        final imageFile = capturedImages[i];
        print('📄 Traitement image ${i + 1}/${capturedImages.length}');
        final imageBytes = await imageFile.readAsBytes();
        final image = pw.MemoryImage(imageBytes);
        
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(image, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Sauvegarder le PDF
      print('📄 Sauvegarde du PDF...');
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final pdfPath = '${directory.path}/document_${widget.vehicle.plate}_$timestamp.pdf';
      final pdfFile = File(pdfPath);
      await pdfFile.writeAsBytes(await pdf.save());
      
      print('📄 PDF créé: $pdfPath');
      print('📄 Taille: ${await pdfFile.length()} bytes');

      // Afficher la boîte de dialogue pour les métadonnées
      print('📄 Affichage dialogue métadonnées...');
      await _showDocumentInfoDialog(pdfFile);

    } catch (e) {
      print('Erreur création PDF: $e');
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
      builder: (context) => AlertDialog(
        title: Text(
          'Informations du document',
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 16, tablet: 18, desktop: 18),
          ),
        ),
        contentPadding: EdgeInsets.fromLTRB(
          ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
          ResponsiveHelper.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 20),
          ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
          ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: ResponsiveHelper.isMobile(context) ? 280 : 400,
            maxHeight: ResponsiveHelper.isMobile(context) ? 300 : 400,
          ),
          child: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Nom du document',
                      hintText: 'Ex: Carte grise 2024',
                      labelStyle: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
                      ),
                      hintStyle: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
                      ),
                    ),
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12)),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                      color: Colors.black,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Type de document',
                      labelStyle: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'carte_grise',
                        child: Text(
                          'Carte grise',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'assurance',
                        child: Text(
                          'Assurance',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'controle_technique',
                        child: Text(
                          'Contrôle technique',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'facture',
                        child: Text(
                          'Facture',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'autre',
                        child: Text(
                          'Autre',
                          style: TextStyle(
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) => selectedType = value!,
                  ),
                  SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12)),
                  TextField(
                    controller: descriptionController,
                    style: TextStyle(
                      fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                    ),
                    decoration: InputDecoration(
                      labelText: 'Description (optionnel)',
                      hintText: 'Détails supplémentaires...',
                      labelStyle: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
                      ),
                      hintStyle: TextStyle(
                        fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
                      ),
                    ),
                    maxLines: ResponsiveHelper.isMobile(context) ? 1 : 2,
                  ),
                ],
              ),
            ),
          ),
        ),
        actionsPadding: EdgeInsets.fromLTRB(
          ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
          ResponsiveHelper.responsiveSpacing(context, mobile: 4, tablet: 8, desktop: 8),
          ResponsiveHelper.responsivePadding(context, mobile: 16, tablet: 24, desktop: 24),
          ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
              ),
            ),
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
              print('📤 Début upload document...');
              print('📤 Vehicle ID: ${widget.vehicle.id}');
              print('📤 Nom: ${nameController.text.trim()}');
              print('📤 Type: $selectedType');
              
              final document = await DocumentService.uploadDocument(
                vehicleId: widget.vehicle.id ?? 0,
                name: nameController.text.trim(),
                type: selectedType,
                description: descriptionController.text.trim().isEmpty 
                    ? null 
                    : descriptionController.text.trim(),
                file: pdfFile,
              );

              print('📤 Résultat upload: ${document != null ? "SUCCESS" : "FAILED"}');

              if (document != null) {
                Navigator.pop(context, true);
                Navigator.pop(context); // Retour à l'écran précédent
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Document uploadé avec succès!')),
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
                fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
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

  void _removeImage(int index) {
    setState(() {
      capturedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Scanner - ${widget.vehicle.brand.isNotEmpty ? widget.vehicle.brand : 'Marque'} ${widget.vehicle.model.isNotEmpty ? widget.vehicle.model : 'Modèle'}',
          style: TextStyle(
            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 16, tablet: 18, desktop: 20),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(ResponsiveHelper.responsivePadding(context, mobile: 12, tablet: 16, desktop: 16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info section
            Container(
              padding: EdgeInsets.all(ResponsiveHelper.responsivePadding(context, mobile: 12, tablet: 16, desktop: 16)),
              decoration: BoxDecoration(
                color: FigmaColors.primaryFocus,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: FigmaColors.primaryMain),
                  SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scannez vos documents',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                          ),
                        ),
                        Text(
                          'Prenez des photos de vos documents pour les sauvegarder en PDF',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 12, tablet: 14, desktop: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 20)),
            
            // Boutons de capture
            ResponsiveHelper.isMobile(context)
                ? Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : _pickFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Prendre une photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FigmaColors.primaryMain,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galerie'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : _pickFromCamera,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Prendre une photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FigmaColors.primaryMain,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isProcessing ? null : _pickFromGallery,
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Galerie'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
            
            SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 20)),
            
            // Liste des images capturées
            if (capturedImages.isNotEmpty) ...[
              Text(
                '${capturedImages.length} image(s) capturée(s)',
                style: TextStyle(
                  fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12)),
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveHelper.isMobile(context) ? 2 : 3,
                    crossAxisSpacing: ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12),
                    mainAxisSpacing: ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 12, desktop: 12),
                  ),
                  itemCount: capturedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              capturedImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: ResponsiveHelper.responsiveSpacing(context, mobile: 16, tablet: 20, desktop: 20)),
            ] else 
              Expanded(
                child: Center(
                  child: Text(
                    'Aucune image capturée\nUtilisez les boutons ci-dessus pour commencer',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: ResponsiveHelper.responsiveFontSize(context, mobile: 14, tablet: 16, desktop: 16),
                    ),
                  ),
                ),
              ),
            
            // Boutons d'action avec SafeArea pour éviter la barre de navigation Android
            if (capturedImages.isNotEmpty) ...[
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: ResponsiveHelper.responsiveSpacing(context, mobile: 16, tablet: 12, desktop: 12),
                  ),
                  child: ResponsiveHelper.isMobile(context)
                      ? Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isProcessing ? null : _resetCapture,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Recommencer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: isProcessing ? null : _createPdfAndUpload,
                                icon: isProcessing 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf),
                                label: Text(isProcessing ? 'Traitement...' : 'Créer PDF et Sauvegarder'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FigmaColors.primaryMain,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: isProcessing ? null : _resetCapture,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Recommencer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey[600],
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: isProcessing ? null : _createPdfAndUpload,
                                icon: isProcessing 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.picture_as_pdf),
                                label: Text(isProcessing ? 'Traitement...' : 'Créer PDF et Sauvegarder'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: FigmaColors.primaryMain,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}