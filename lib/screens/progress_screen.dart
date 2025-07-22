import 'package:flutter/material.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/theme/responsive_helper.dart';
import 'package:save_your_car/widgets/Main_scaffold.dart';
import 'package:save_your_car/services/progress_service.dart';
import 'package:save_your_car/screens/profile/edit_profile_screen.dart';
import 'package:save_your_car/screens/appointment_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> with TickerProviderStateMixin {
  Map<String, dynamic>? progressData;
  bool isLoading = true;
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressAnimationController, curve: Curves.easeOutCubic),
    );
    _loadProgress();
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    try {
      final data = await ProgressService.calculateProgress();
      setState(() {
        progressData = data;
        isLoading = false;
      });
      
      // Démarrer l'animation
      _progressAnimationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
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
    final textStyle = FigmaTextStyles();
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return MainScaffold(
      currentIndex: -1,
      child: Scaffold(
        backgroundColor: FigmaColors.neutral00,
        appBar: AppBar(
          backgroundColor: FigmaColors.neutral100,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Ma Progression',
            style: textStyle.headingSBold.copyWith(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () {
                setState(() {
                  isLoading = true;
                });
                _progressAnimationController.reset();
                _loadProgress();
              },
            ),
          ],
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(FigmaColors.primaryMain),
                ),
              )
            : SingleChildScrollView(
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jauge de progression
                    _buildProgressGauge(textStyle, isMobile),
                    
                    SizedBox(height: isMobile ? 24 : 32),
                    
                    // Message de motivation
                    _buildMotivationCard(textStyle, isMobile),
                    
                    SizedBox(height: isMobile ? 24 : 32),
                    
                    // Liste des tâches
                    Text(
                      'Étapes à compléter',
                      style: textStyle.textLBold.copyWith(
                        color: FigmaColors.neutral90,
                        fontSize: isMobile ? 16 : 18,
                      ),
                    ),
                    
                    SizedBox(height: isMobile ? 16 : 20),
                    
                    // Liste des items de progression
                    ...progressData!['items'].map<Widget>((item) {
                      return _buildProgressItem(item, textStyle, isMobile);
                    }).toList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildProgressGauge(FigmaTextStyles textStyle, bool isMobile) {
    final percentage = progressData!['percentage'] as int;
    final completedCount = progressData!['completedCount'] as int;
    final totalCount = progressData!['totalCount'] as int;
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FigmaColors.primaryMain, FigmaColors.primaryMain],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: FigmaColors.primaryMain.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre
          Text(
            'Votre Progression',
            style: textStyle.textLBold.copyWith(
              color: Colors.white,
              fontSize: isMobile ? 18 : 20,
            ),
          ),
          
          SizedBox(height: isMobile ? 16 : 20),
          
          // Jauge circulaire
          SizedBox(
            width: isMobile ? 150 : 180,
            height: isMobile ? 150 : 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Jauge de fond
                SizedBox(
                  width: isMobile ? 150 : 180,
                  height: isMobile ? 150 : 180,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: isMobile ? 8 : 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.transparent),
                  ),
                ),
                // Jauge animée
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: isMobile ? 150 : 180,
                      height: isMobile ? 150 : 180,
                      child: CircularProgressIndicator(
                        value: (percentage / 100) * _progressAnimation.value,
                        strokeWidth: isMobile ? 8 : 12,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(percentage),
                        ),
                      ),
                    );
                  },
                ),
                // Texte au centre
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        final animatedPercentage = (percentage * _progressAnimation.value).round();
                        return Text(
                          '$animatedPercentage%',
                          style: textStyle.headingLBold.copyWith(
                            color: Colors.white,
                            fontSize: isMobile ? 28 : 32,
                          ),
                        );
                      },
                    ),
                    Text(
                      '$completedCount/$totalCount étapes',
                      style: textStyle.textMRegular.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 12 : 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(FigmaTextStyles textStyle, bool isMobile) {
    final percentage = progressData!['percentage'] as int;
    final message = ProgressService.getMotivationMessage(percentage);
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FigmaColors.neutral20),
      ),
      child: Text(
        message,
        style: textStyle.textMRegular.copyWith(
          color: FigmaColors.neutral80,
          fontSize: isMobile ? 14 : 16,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildProgressItem(Map<String, dynamic> item, FigmaTextStyles textStyle, bool isMobile) {
    final isCompleted = item['completed'] as bool;
    
    return Container(
      margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.withOpacity(0.1) : FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? Colors.green.withOpacity(0.3) : FigmaColors.neutral20,
        ),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 20,
          vertical: isMobile ? 8 : 12,
        ),
        leading: Container(
          width: isMobile ? 40 : 48,
          height: isMobile ? 40 : 48,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : FigmaColors.primaryMain,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isCompleted ? Icons.check : _getItemIcon(item['icon']),
            color: Colors.white,
            size: isMobile ? 20 : 24,
          ),
        ),
        title: Text(
          item['title'],
          style: textStyle.textMSemiBold.copyWith(
            color: isCompleted ? Colors.green.shade700 : FigmaColors.neutral90,
            fontSize: isMobile ? 14 : 16,
          ),
        ),
        subtitle: Text(
          item['description'],
          style: textStyle.textMRegular.copyWith(
            color: isCompleted ? Colors.green.shade600 : FigmaColors.neutral70,
            fontSize: isMobile ? 12 : 14,
          ),
        ),
        trailing: isCompleted 
            ? Icon(
                Icons.check_circle,
                color: Colors.green,
                size: isMobile ? 20 : 24,
              )
            : IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios,
                  color: FigmaColors.primaryMain,
                  size: isMobile ? 16 : 20,
                ),
                onPressed: () => _navigateToItem(item['id']),
              ),
        onTap: isCompleted ? null : () => _navigateToItem(item['id']),
      ),
    );
  }

  IconData _getItemIcon(String iconType) {
    switch (iconType) {
      case 'profile':
        return Icons.person_outline;
      case 'vehicle':
        return Icons.directions_car_outlined;
      case 'document':
        return Icons.document_scanner_outlined;
      case 'appointment':
        return Icons.calendar_today_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  Color _getProgressColor(int percentage) {
    if (percentage >= 100) return Colors.green;
    if (percentage >= 75) return Colors.lightGreen;
    if (percentage >= 50) return Colors.orange;
    if (percentage >= 25) return Colors.yellow.shade700;
    return Colors.red;
  }

  void _navigateToItem(String itemId) {
    switch (itemId) {
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        ).then((_) => _loadProgress());
        break;
      case 'vehicle':
        // Navigate to vehicles page (simplified)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirection vers Mes Véhicules')),
        );
        break;
      case 'document':
        // Navigate to camera scanner (simplified)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Redirection vers Scanner de documents')),
        );
        break;
      case 'appointment':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AppointmentScreen()),
        ).then((_) => _loadProgress());
        break;
    }
  }
}