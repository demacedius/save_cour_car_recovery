import 'package:flutter/material.dart';
import 'package:save_your_car/screens/profile/edit_profile_screen.dart';
import 'package:save_your_car/screens/profile/notification_screen.dart';
import 'package:save_your_car/screens/profile/language_screen.dart';
import 'package:save_your_car/screens/profile/help_screen.dart';
import 'package:save_your_car/screens/profile/invite_friends_screen.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/widgets/Main_scaffold.dart';
import 'package:save_your_car/services/user_service.dart';
import 'package:save_your_car/screens/auth/welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final textStyle = FigmaTextStyles();

    return MainScaffold(
      currentIndex: 3,
      child: Scaffold(
        backgroundColor: FigmaColors.neutral00,
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                color: FigmaColors.neutral100,
                padding: const EdgeInsets.only(left: 24, top: 68),
                width: double.infinity,
                height: 147,
                child: Text(
                  "Profile",
                  style: textStyle.headingMBold.copyWith(
                    color: FigmaColors.neutral00,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
      
              const SizedBox(height: 16),
      
              // Options
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _ProfileOption(
                      title: "Edit Profile", 
                      icon: Icons.person_outline,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen())),
                    ),
                    _ProfileOption(
                      title: "Notification", 
                      icon: Icons.notifications_none,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                    ),
                    _ProfileOption(
                      title: "Langage", 
                      icon: Icons.language,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LanguageScreen())),
                    ),
                    _ProfileOption(
                      title: "Aide", 
                      icon: Icons.help_outline,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen())),
                    ),
                    _ProfileOption(
                      title: "Inviter des amis", 
                      icon: Icons.group_outlined,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InviteFriendsScreen())),
                    ),
                    const SizedBox(height: 12),
                    const _LogoutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _ProfileOption({
    required this.title,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: FigmaColors.neutral10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: FigmaColors.neutral90),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title, style: FigmaTextStyles().textMSemiBold),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: FigmaColors.neutral60),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: FigmaColors.neutral10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout, size: 20, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Se déconnecter",
                style: FigmaTextStyles().textMSemiBold.copyWith(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Déconnexion',
            style: FigmaTextStyles().textLBold,
          ),
          content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ?',
            style: FigmaTextStyles().textMRegular,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: FigmaTextStyles().textMSemiBold.copyWith(
                  color: FigmaColors.neutral70,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await UserService.logout();
                
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                    (route) => false,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Se déconnecter',
                style: FigmaTextStyles().textMSemiBold,
              ),
            ),
          ],
        );
      },
    );
  }
}