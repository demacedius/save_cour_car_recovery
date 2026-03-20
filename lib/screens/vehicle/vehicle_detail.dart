// ignore_for_file: avoid_print, sized_box_for_whitespace, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:save_your_car/models/document.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/services/document_service.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/widgets/Main_scaffold.dart';
import 'package:save_your_car/theme/responsive_helper.dart';
import 'package:save_your_car/api_service/api_service.dart';
import 'package:save_your_car/services/token_storage.dart';
import 'package:save_your_car/services/auth_service.dart';

class VehicleDetail extends StatefulWidget {
  final VehicleData vehicle;
  const VehicleDetail({super.key, required this.vehicle});

  @override
  State<VehicleDetail> createState() => _VehicleDetailState();
}

class _VehicleDetailState extends State<VehicleDetail> {
  List<DocumentData> documents = [];
  bool isLoadingDocuments = true;
  bool isUserLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
    _checkUserToken();
  }

  Future<void> _checkUserToken() async {
    try {
      final token = await AuthService.getToken();
      print('🔍 Debug vehicle_detail - Token récupéré: ${token != null ? "✅ Présent (${token.length} chars)" : "❌ Absent"}');
      
      if (mounted) {
        setState(() {
          isUserLoggedIn = token != null && token.isNotEmpty;
        });
        print('🔍 Debug vehicle_detail - État final isUserLoggedIn: $isUserLoggedIn');
      }
    } catch (e) {
      print('❌ Erreur lors de la vérification du token: $e');
      if (mounted) {
        setState(() {
          isUserLoggedIn = false;
        });
      }
    }
  }

  Future<void> _loadDocuments() async {
    if (widget.vehicle.id == null) return;
    
    try {
      final vehicleDocuments = await DocumentService.getVehicleDocuments(widget.vehicle.id!);
      setState(() {
        documents = vehicleDocuments;
        isLoadingDocuments = false;
      });
    } catch (e) {
      print('Erreur chargement documents: $e');
      setState(() {
        isLoadingDocuments = false;
      });
    }
  }

  void _showTransferDialog(BuildContext context) async {
    // Vérifier à nouveau si l'utilisateur est connecté
    final token = await AuthService.getToken();
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vous devez être connecté pour transférer un véhicule'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Se connecter',
              onPressed: () {
                // Rediriger vers la page de connexion
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ),
        );
      }
      return;
    }

    final TextEditingController emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.transfer_within_a_station, color: FigmaColors.primaryMain),
            SizedBox(width: 8),
            Text('Transférer le véhicule'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vous allez transférer "${widget.vehicle.brand} ${widget.vehicle.model}" ainsi que tous ses documents au nouveau propriétaire.\n\nCette action est irréversible.',
                style: TextStyle(fontSize: 14, color: Colors.grey[700]),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email du nouveau propriétaire',
                  hintText: 'exemple@email.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Veuillez saisir un email';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                    return 'Veuillez saisir un email valide';
                  }
                  return null;
                },
              ),
              SizedBox(height: 8),
              Text(
                '⚠️ Le destinataire doit avoir un compte sur l\'application',
                style: TextStyle(fontSize: 12, color: Colors.orange[700]),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                await _transferVehicle(emailController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FigmaColors.primaryMain,
            ),
            child: Text('Transférer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _transferVehicle(String newOwnerEmail) async {
    if (widget.vehicle.id == null) return;

    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Transfert en cours...'),
          ],
        ),
      ),
    );

    try {
      final result = await transferVehicle(widget.vehicle.id!, newOwnerEmail);
      
      // Fermer le dialog de chargement
      if (mounted) Navigator.pop(context);

      if (result != null && !result.containsKey('error')) {
        // Succès
        if (mounted) {
          final documentsCount = result['documentsTransferred'] ?? 0;
          final appointmentsCount = result['appointmentsTransferred'] ?? 0;
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Transfert réussi'),
                ],
              ),
              content: Text(
                'Le véhicule "${widget.vehicle.brand} ${widget.vehicle.model}", $documentsCount document(s) et $appointmentsCount rendez-vous ont été transférés avec succès à $newOwnerEmail.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Fermer le dialog
                    Navigator.pop(context); // Retourner à la liste des véhicules
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }
      } else {
        // Erreur
        if (mounted) {
          String errorMessage = 'Erreur lors du transfert';
          if (result != null && result.containsKey('error')) {
            errorMessage = result['error'].toString();
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      // Fermer le dialog de chargement
      if (mounted) Navigator.pop(context);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final yearController = TextEditingController(text: widget.vehicle.year?.toString() ?? '');
    final mileageController = TextEditingController(text: widget.vehicle.mileage?.toString() ?? '');
    final engineTypeController = TextEditingController(text: widget.vehicle.engineType ?? '');
    final displacementController = TextEditingController(text: widget.vehicle.displacement ?? '');

    DateTime? selectedDate = widget.vehicle.technicalControlDate;

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Modifier les informations'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: yearController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Année',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: mileageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kilométrage',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: engineTypeController,
                decoration: const InputDecoration(
                  labelText: 'Type de moteur (Essence, Diesel, Électrique, Hybride)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: displacementController,
                decoration: const InputDecoration(
                  labelText: 'Cylindrée (ex: 1.6L, 2.0L)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(
                  selectedDate != null
                      ? 'Contrôle technique: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}'
                      : 'Date du contrôle technique',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    selectedDate = picked;
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Mettre à jour le véhicule
              final updatedVehicle = widget.vehicle.copyWith(
                year: int.tryParse(yearController.text),
                mileage: int.tryParse(mileageController.text),
                engineType: engineTypeController.text.trim().isEmpty ? null : engineTypeController.text.trim(),
                displacement: displacementController.text.trim().isEmpty ? null : displacementController.text.trim(),
                technicalControlDate: selectedDate,
              );

              // Appeler l'API pour mettre à jour
              final token = await AuthService.getToken();
              if (token != null && widget.vehicle.id != null) {
                final success = await updateVehicle(updatedVehicle, token);
                if (success && mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Véhicule mis à jour !'), backgroundColor: Colors.green),
                  );
                  // Recharger la page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => VehicleDetail(vehicle: updatedVehicle)),
                  );
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('❌ Erreur lors de la mise à jour'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: FigmaColors.primaryMain),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = FigmaTextStyles();

    return MainScaffold(
      selectedVehicleId: widget.vehicle.id,
      selectedVehicle: widget.vehicle,
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: ResponsiveHelper.headerHeight(context) + ResponsiveHelper.infoCardSize(context).height / 2,
              child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  height: ResponsiveHelper.headerHeight(context),
                  decoration: const BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: FigmaColors.neutral80,
                        offset: Offset(0, 4),
                        blurRadius: 10,
                        spreadRadius: 5,
                        blurStyle: BlurStyle.outer
                      )
                    ],
                    color: Color.fromARGB(255, 255, 255, 255),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                      
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      widget.vehicle.brandImageUrl != null
                          ? Image.network(
                              widget.vehicle.brandImageUrl!,
                              width: ResponsiveHelper.brandLogoSize(context).width,
                              height: ResponsiveHelper.brandLogoSize(context).height,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => _brandInitialAvatar(context),
                            )
                          : _brandInitialAvatar(context),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              "${widget.vehicle.brand} ${widget.vehicle.model}",
                              style: textStyle.headingSBold.copyWith(
                                color: FigmaColors.neutral100,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _showEditDialog(context),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: FigmaColors.primaryMain.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: FigmaColors.primaryMain,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      widget.vehicle.imageUrl != null
                          ? Container(
                              width: ResponsiveHelper.vehicleImageSize(context).width,
                              height: ResponsiveHelper.vehicleImageSize(context).height,
                              child: Stack(
                                children: [
                                  Image.network(
                                    widget.vehicle.imageUrl!,
                                    width: ResponsiveHelper.vehicleImageSize(context).width,
                                    height: ResponsiveHelper.vehicleImageSize(context).height,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Image.asset(
                                      "assets/images/AudiXL.png",
                                      width: ResponsiveHelper.vehicleImageSize(context).width,
                                      height: ResponsiveHelper.vehicleImageSize(context).height,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                 
                                ],
                              ),
                            )
                          : Image.asset(
                              "assets/images/AudiXL.png",
                              width: ResponsiveHelper.vehicleImageSize(context).width,
                              height: ResponsiveHelper.vehicleImageSize(context).height,
                              fit: BoxFit.contain,
                            ),
                    ],
                  ),
                ),

                // Bouton retour
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: FigmaColors.neutral50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left, size: 20, color: FigmaColors.neutral00),
                    ),
                  ),
                ),

                // Boutons droite groupés
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Refresh
                      GestureDetector(
                        onTap: () { _checkUserToken(); _loadDocuments(); },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: FigmaColors.neutral70, shape: BoxShape.circle),
                          child: const Icon(Icons.refresh, size: 18, color: FigmaColors.neutral00),
                        ),
                      ),
                      if (isUserLoggedIn) ...[
                        const SizedBox(width: 8),
                        // Transfert
                        GestureDetector(
                          onTap: () => _showTransferDialog(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: FigmaColors.primaryMain, shape: BoxShape.circle),
                            child: const Icon(Icons.transfer_within_a_station, size: 18, color: FigmaColors.neutral00),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Cards en scroll horizontal, centrées sur le bas du header
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: ResponsiveHelper.infoCardSize(context).height,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        _infoCard(
                          icon: Transform.rotate(
                            angle: -90 * 3.1415926535 / 180,
                            child: const Icon(Icons.tune_rounded),
                          ),
                          title: "Année",
                          value: widget.vehicle.year?.toString() ?? "N/A",
                          textStyle: textStyle,
                        ),
                        const SizedBox(width: 12),
                        _infoCard(
                          icon: const Icon(Icons.speed),
                          title: "Kilométrage",
                          value: widget.vehicle.mileage != null
                              ? "${NumberFormat('#,###').format(widget.vehicle.mileage).replaceAll(',', '.')}Km"
                              : "N/A",
                          textStyle: textStyle,
                        ),
                        const SizedBox(width: 12),
                        _infoCard(
                          icon: const Icon(Icons.calendar_month_rounded),
                          title: "Contrôle",
                          value: widget.vehicle.technicalControlDate != null
                              ? DateFormat('dd/MM/yyyy').format(widget.vehicle.technicalControlDate!)
                              : "N/A",
                          textStyle: textStyle,
                        ),
                        const SizedBox(width: 12),
                        _infoCard(
                          icon: const Icon(Icons.local_gas_station),
                          title: "Type moteur",
                          value: widget.vehicle.engineType ?? "N/A",
                          textStyle: textStyle,
                        ),
                        const SizedBox(width: 12),
                        _infoCard(
                          icon: const Icon(Icons.settings),
                          title: "Cylindrée",
                          value: widget.vehicle.displacement ?? "N/A",
                          textStyle: textStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ), // SizedBox

            const SizedBox(height: 20),

            Padding(
              padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 24),
              child: Text("Documents du véhicule", style: textStyle.textXXLBold),
            ),
            const SizedBox(height: 24),

            // Liste scrollable uniquement
            Expanded(
              child: isLoadingDocuments
                  ? const Center(child: CircularProgressIndicator())
                  : documents.isEmpty
                      ? const Center(
                          child: Text(
                            'Aucun document enregistré\nUtilisez le bouton central 📄 pour scanner des documents',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(horizontal: MediaQuery.of(context).size.width < 400 ? 16 : 24),
                          itemCount: documents.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _DocumentCard(
                              document: documents[index],
                              onDelete: () async {
                                final success = await DocumentService.deleteDocument(documents[index].id);
                                if (success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Document supprimé')),
                                  );
                                  _loadDocuments();
                                }
                              },
                            ),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandInitialAvatar(BuildContext context) {
    final initial = widget.vehicle.brand.isNotEmpty
        ? widget.vehicle.brand[0].toUpperCase()
        : '?';
    final size = ResponsiveHelper.brandLogoSize(context).height;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FigmaColors.primaryFocus,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.55,
            fontWeight: FontWeight.bold,
            color: FigmaColors.primaryMain,
            fontFamily: 'Poppins',
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required Widget icon,
    required String title,
    required String value,
    required FigmaTextStyles textStyle,
  }) {
    return Container(
      width: ResponsiveHelper.infoCardSize(context).width,
      height: ResponsiveHelper.infoCardSize(context).height,
      padding: EdgeInsets.all(ResponsiveHelper.responsiveSpacing(context, mobile: 8, tablet: 14, desktop: 16)),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: FigmaColors.neutral50,
            offset: Offset(0, 0),
            spreadRadius: 3,
            blurRadius: 3,
            blurStyle: BlurStyle.normal
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: ResponsiveHelper.isMobile(context) ? 28 : 32,
            height: ResponsiveHelper.isMobile(context) ? 28 : 32,
            decoration: BoxDecoration(
              color: FigmaColors.neutral30,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: icon),
          ),
          SizedBox(height: ResponsiveHelper.isMobile(context) ? 8 : 12),
          Flexible(
            child: Text(
              title,
              style: textStyle.captionXSMedium.copyWith(
                color: FigmaColors.neutral70,
                fontSize: ResponsiveHelper.isMobile(context) ? 10 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: ResponsiveHelper.isMobile(context) ? 1 : 2),
          Flexible(
            child: Text(
              value, 
              style: textStyle.textMBold.copyWith(
                fontSize: ResponsiveHelper.isMobile(context) ? 12 : null,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentData document;
  final VoidCallback onDelete;

  const _DocumentCard({
    required this.document,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône du type de document
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FigmaColors.primaryFocus,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getDocumentIcon(document.type),
              color: FigmaColors.primaryMain,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          
          // Informations du document
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  document.typeDisplayName,
                  style: const TextStyle(
                    fontSize: 14,
                    color: FigmaColors.primaryMain,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  children: [
                    Text(
                      document.fileSizeFormatted,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(document.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Boutons d'action
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.download, color: FigmaColors.primaryMain),
                onPressed: () => _downloadDocument(context, document),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Supprimer le document'),
                      content: Text('Voulez-vous vraiment supprimer "${document.name}" ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onDelete();
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'carte_grise':
        return Icons.credit_card;
      case 'assurance':
        return Icons.security;
      case 'controle_technique':
        return Icons.build;
      case 'facture':
        return Icons.receipt;
      default:
        return Icons.description;
    }
  }

  Future<void> _downloadDocument(BuildContext context, DocumentData document) async {
    // Afficher un indicateur de chargement
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Téléchargement en cours...'),
          ],
        ),
      ),
    );

    try {
      final filePath = await DocumentService.downloadDocument(document);
      
      // Fermer le dialog de chargement
      if (context.mounted) Navigator.pop(context);

      if (filePath != null) {
        // Succès
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('📥 Document téléchargé dans Téléchargements'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 8),
              action: SnackBarAction(
                label: 'Ouvrir dossier',
                textColor: Colors.white,
                onPressed: () {
                  DocumentService.shareDocument(filePath, document.name);
                },
              ),
            ),
          );
        }
      } else {
        // Erreur
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors du téléchargement'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Fermer le dialog de chargement
      if (context.mounted) Navigator.pop(context);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
