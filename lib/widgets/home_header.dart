import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/services/user_service.dart';
import 'package:save_your_car/services/auth_service.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  String _displayName = 'Utilisateur';
  bool _isLoading = true;
  bool _needsLogin = false;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    try {
      // Vérifier si l'utilisateur doit se reconnecter
      final needsLogin = await AuthService.needsLogin();

      // Vérifier si l'utilisateur est connecté
      final isLoggedIn = await AuthService.isLoggedIn();

      if (needsLogin || !isLoggedIn) {
        if (mounted) {
          setState(() {
            _displayName = needsLogin ? 'Session expirée' : 'Invité';
            _needsLogin = needsLogin;
            _isLoading = false;
          });
        }
        return;
      }

      final displayName = await UserService.getUserDisplayName();
      if (mounted) {
        setState(() {
          _displayName = displayName;
          _needsLogin = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement nom utilisateur: $e');
      if (mounted) {
        setState(() {
          _displayName = 'Utilisateur';
          _needsLogin = false;
          _isLoading = false;
        });
      }
    }
  }

  /// Méthode publique pour rafraîchir les données utilisateur
  Future<void> refreshUserData() async {
    setState(() {
      _isLoading = true;
    });
    await UserService.clearUserCache();
    await _loadUserName();
  }

  @override
  Widget build(BuildContext context) {
    final textStyles = FigmaTextStyles();
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(
        MediaQuery.of(context).size.width * 0.06,
        topPadding + 16,
        MediaQuery.of(context).size.width * 0.06,
        16,
      ),
      height: MediaQuery.of(context).size.height * 0.22,
      decoration: const BoxDecoration(color: Colors.black),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/Group 1.png'),
            radius: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _isLoading
                    ? Container(
                      height: 24,
                      width: 150,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                    : Text(
                      "Bonjour $_displayName !",
                      style: textStyles.textXLBold.copyWith(
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                const SizedBox(height: 4),
                Text(
                  _needsLogin
                      ? "Veuillez vous reconnecter"
                      : "Fixons votre véhicules",
                  style: textStyles.textLRegular.copyWith(
                    color: _needsLogin ? Colors.orange[300] : Colors.white70,
                  ),
                ),
                if (_needsLogin) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/login'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Se connecter",
                        style: textStyles.textMMedium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF2C2C2E),
                child: Icon(Icons.notifications, color: Colors.white),
              ),
              const Positioned(
                top: 2,
                right: 2,
                child: CircleAvatar(radius: 4, backgroundColor: Colors.amber),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
