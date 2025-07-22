// ignore_for_file: avoid_print, sized_box_for_whitespace, use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            Stack(
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
                      const SizedBox(
                        height: 24,
                      ), 
                      widget.vehicle.brandImageUrl != null
                          ? Image.network(
                              widget.vehicle.brandImageUrl!,
                              width: ResponsiveHelper.brandLogoSize(context).width,
                              height: ResponsiveHelper.brandLogoSize(context).height,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  SvgPicture.asset(
                                "assets/images/Audi svg.svg",
                                width: ResponsiveHelper.brandLogoSize(context).width,
                                height: ResponsiveHelper.brandLogoSize(context).height,
                                fit: BoxFit.contain,
                              ),
                            )
                          : SvgPicture.asset(
                              "assets/images/Audi svg.svg",
                              width: ResponsiveHelper.brandLogoSize(context).width,
                              height: ResponsiveHelper.brandLogoSize(context).height,
                              fit: BoxFit.contain,
                            ),
                      const SizedBox(height: 8),
                      Text(
                        "${widget.vehicle.brand} ${widget.vehicle.model}",
                        style: textStyle.headingSBold.copyWith(
                          color: FigmaColors.neutral100,
                        ),
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

                // ← bouton retour - responsive positioning
                Positioned(
                  top: MediaQuery.of(context).size.height < 700 ? 48 : 68,
                  left: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: FigmaColors.neutral50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: FigmaColors.neutral00,
                      ),
                    ),
                  ),
                ),

                // Bouton refresh (pour debug) - responsive positioning
                Positioned(
                  top: MediaQuery.of(context).size.height < 700 ? 48 : 68,
                  right: isUserLoggedIn ? (MediaQuery.of(context).size.width < 400 ? 96 : 116) : (MediaQuery.of(context).size.width < 400 ? 56 : 70),
                  child: GestureDetector(
                    onTap: () {
                      _checkUserToken();
                      _loadDocuments();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: FigmaColors.neutral70,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.refresh,
                        size: 20,
                        color: FigmaColors.neutral00,
                      ),
                    ),
                  ),
                ),

                // Bouton déconnexion (pour debug) - responsive positioning
                if (isUserLoggedIn)
                  Positioned(
                    top: MediaQuery.of(context).size.height < 700 ? 48 : 68,
                    right: MediaQuery.of(context).size.width < 400 ? 56 : 70,
                    child: GestureDetector(
                      onTap: () async {
                        await AuthService.logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Déconnecté avec succès'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        setState(() {
                          isUserLoggedIn = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Bouton de transfert (seulement si connecté) - responsive positioning
                if (isUserLoggedIn)
                  Positioned(
                    top: MediaQuery.of(context).size.height < 700 ? 48 : 68,
                    right: MediaQuery.of(context).size.width < 400 ? 16 : 24,
                    child: GestureDetector(
                      onTap: () => _showTransferDialog(context),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: FigmaColors.primaryMain,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.transfer_within_a_station,
                          size: 20,
                          color: FigmaColors.neutral00,
                        ),
                      ),
                    ),
                  ),

                // ← bloc des 3 cartes info - constrained for small screens
                Positioned(
                  bottom: MediaQuery.of(context).size.height < 700 ? -42 : (ResponsiveHelper.isMobile(context) ? -48 : -54),
                  left: 0,
                  right: 0,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
                        SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 6, tablet: 12, desktop: 12)),
                        _infoCard(
                          icon: const Icon(Icons.speed),
                          title: "Kilométrage",
                          value: widget.vehicle.mileage != null 
                              ? "${NumberFormat('#,###').format(widget.vehicle.mileage).replaceAll(',', '.')}Km"
                              : "N/A",
                          textStyle: textStyle,
                        ),
                        SizedBox(width: ResponsiveHelper.responsiveSpacing(context, mobile: 6, tablet: 12, desktop: 12)),
                        _infoCard(
                          icon: const Icon(Icons.calendar_month_rounded),
                          title: "Contrôle",
                          value: widget.vehicle.technicalControlDate != null
                              ? DateFormat('dd/MM/yyyy').format(widget.vehicle.technicalControlDate!)
                              : "N/A",
                          textStyle: textStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: MediaQuery.of(context).size.height < 700 ? 52 : (ResponsiveHelper.isMobile(context) ? 58 : 64)), // pour ne pas cacher les cards

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
