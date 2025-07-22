// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'dart:io';

import 'package:save_your_car/services/user_service.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      // Diagnostic du cache avant chargement
      await UserService.diagnosticAndRepairCache();
      
      // Vérifier d'abord si l'utilisateur est authentifié
      final isAuthenticated = await AuthService.isLoggedIn();
      
      if (!isAuthenticated && mounted) {
        // Utilisateur non authentifié - redirection immédiate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expirée. Veuillez vous reconnecter.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
          (Route<dynamic> route) => false,
        );
        return;
      }
      
      final userData = await UserService.getCurrentUser();

      if (userData != null && mounted) {
        setState(() {
          _firstNameController.text = userData['first_name'] ?? '';
          _lastNameController.text = userData['last_name'] ?? '';
          _emailController.text = userData['email'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _profileImageUrl = userData['profile_picture'];
          _isLoading = false;
        });
      } else {
        // Mode démonstration avec des données factices
        setState(() {
          _firstNameController.text = 'Jean';
          _lastNameController.text = 'Dupont';
          _emailController.text = 'jean.dupont@email.com';
          _phoneController.text = '06 12 34 56 78';
          _profileImageUrl = null;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mode démonstration - Données fictives chargées'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FigmaColors.neutral00,
      appBar: AppBar(
        backgroundColor: FigmaColors.neutral100,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Modifier le profil',
          style: FigmaTextStyles().headingSBold.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child:
                _isSaving
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : Text(
                      'Sauvegarder',
                      style: FigmaTextStyles().textMSemiBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    FigmaColors.primaryMain,
                  ),
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Photo de profil
                      Center(
                        child: GestureDetector(
                          onTap: _pickProfileImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: FigmaColors.neutral20,
                                  border: Border.all(
                                    color: FigmaColors.primaryMain,
                                    width: 3,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child:
                                      _profileImage != null
                                          ? Image.file(
                                            _profileImage!,
                                            fit: BoxFit.cover,
                                          )
                                          : _profileImageUrl != null
                                          ? Image.network(
                                            _profileImageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    const Icon(
                                                      Icons.person,
                                                      size: 60,
                                                      color:
                                                          FigmaColors.neutral60,
                                                    ),
                                          )
                                          : const Icon(
                                            Icons.person,
                                            size: 60,
                                            color: FigmaColors.neutral60,
                                          ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: FigmaColors.primaryMain,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Prénom
                      _buildTextField(
                        controller: _firstNameController,
                        label: 'Prénom',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre prénom';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Nom de famille
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Nom de famille',
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre nom de famille';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Email
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Veuillez entrer un email valide';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Téléphone
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Téléphone (optionnel)',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            // Validation basique du format téléphone français
                            if (!RegExp(
                              r'^(\+33|0)[1-9](\d{8})$',
                            ).hasMatch(value.replaceAll(' ', ''))) {
                              return 'Format téléphone invalide (ex: 06 12 34 56 78)';
                            }
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Section sécurité
                      _buildSectionTitle('Sécurité'),
                      const SizedBox(height: 16),

                      _buildSecurityOption(
                        'Changer le mot de passe',
                        Icons.lock_outline,
                        () => _showChangePasswordDialog(),
                      ),

                      const SizedBox(height: 12),

                      _buildSecurityOption(
                        'Authentification à deux facteurs',
                        Icons.security,
                        () => _showTwoFactorDialog(),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: FigmaColors.primaryMain),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FigmaColors.neutral30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: FigmaColors.primaryMain,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: FigmaColors.neutral10,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: FigmaTextStyles().textLBold.copyWith(
          color: FigmaColors.neutral90,
        ),
      ),
    );
  }

  Widget _buildSecurityOption(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: FigmaColors.neutral10,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FigmaColors.neutral20),
        ),
        child: Row(
          children: [
            Icon(icon, color: FigmaColors.primaryMain),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: FigmaTextStyles().textMSemiBold),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: FigmaColors.neutral60,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() {
        _isSaving = true;
      });

      try {
        // Upload de la photo de profil si nécessaire
        if (_profileImage != null) {
          final imageUploaded = await UserService.uploadProfilePicture(
            _profileImage!.path,
          );
          if (!imageUploaded) {
            throw Exception('Erreur lors de l\'upload de la photo');
          }
        }

        // Vérifier si l'utilisateur est authentifié
        final isAuthenticated = await AuthService.isLoggedIn();
        
        if (isAuthenticated) {
          // Utilisateur connecté - mise à jour réelle
          final success = await UserService.updateUserProfile(
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );

          if (success) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profil sauvegardé avec succès'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.pop(context, true);
            }
          } else {
            throw Exception('Erreur lors de la sauvegarde');
          }
        } else {
          // Utilisateur non authentifié - redirection vers la connexion
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Session expirée. Veuillez vous reconnecter.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            
            // Redirection vers l'écran de connexion
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/welcome',
              (Route<dynamic> route) => false,
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  Future<void> _pickProfileImage() async {
    try {
      // Afficher un dialog pour choisir la source
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Choisir une photo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir dans la galerie'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      );

      if (source != null) {
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 80,
          maxWidth: 400,
          maxHeight: 400,
        );

        if (image != null) {
          setState(() {
            _profileImage = File(image.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isChangingPassword = false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: const Text('Changer le mot de passe'),
                  content: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Mot de passe actuel',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe actuel';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Nouveau mot de passe',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Le mot de passe doit contenir au moins 6 caractères';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Confirmer le mot de passe',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          validator: (value) {
                            if (value != newPasswordController.text) {
                              return 'Les mots de passe ne correspondent pas';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed:
                          isChangingPassword
                              ? null
                              : () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                    ElevatedButton(
                      onPressed:
                          isChangingPassword
                              ? null
                              : () async {
                                if (formKey.currentState!.validate()) {
                                  setDialogState(() {
                                    isChangingPassword = true;
                                  });

                                  try {
                                    final success =
                                        await UserService.updatePassword(
                                          currentPassword:
                                              currentPasswordController.text,
                                          newPassword:
                                              newPasswordController.text,
                                        );

                                    if (success) {
                                      Navigator.pop(context);
                                      if (mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Mot de passe changé avec succès',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      }
                                    } else {
                                      throw Exception(
                                        'Mot de passe actuel incorrect',
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Erreur: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } finally {
                                    setDialogState(() {
                                      isChangingPassword = false;
                                    });
                                  }
                                }
                              },
                      child:
                          isChangingPassword
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text('Changer'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Authentification à deux facteurs'),
            content: const Text(
              'Cette fonctionnalité sera bientôt disponible.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
