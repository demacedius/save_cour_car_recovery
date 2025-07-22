import 'package:flutter/material.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:intl/intl.dart';

class NotificationService {
  static bool _isInitialized = false;

  /// Initialise le service de notifications
  static Future<void> initialize() async {
    if (_isInitialized) return;

    await AwesomeNotifications().initialize(
      'resource://mipmap/ic_launcher', // Utiliser l'icône de l'app
      [
        NotificationChannel(
          channelKey: 'scheduled_channel',
          channelName: 'Rappels programmés',
          channelDescription: 'Rappels pour contrôles techniques et rendez-vous',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
        NotificationChannel(
          channelKey: 'instant_channel',
          channelName: 'Notifications instantanées',
          channelDescription: 'Notifications immédiates',
          defaultColor: const Color(0xFF9D50DD),
          ledColor: Colors.white,
          importance: NotificationImportance.High,
          channelShowBadge: true,
        ),
      ],
    );

    _isInitialized = true;
    print('✅ Service de notifications initialisé');
  }

  /// Demande les permissions de notification
  static Future<bool> requestPermissions() async {
    return await AwesomeNotifications().isNotificationAllowed().then((isAllowed) async {
      if (!isAllowed) {
        // Demander les permissions de base pour les notifications
        return await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      return true;
    });
  }

  /// Demande les permissions pour les notifications programmées précises (Android 12+)
  static Future<bool> requestPreciseAlarmsPermission() async {
    try {
      return await AwesomeNotifications().requestPermissionToSendNotifications(
        channelKey: 'scheduled_channel',
        permissions: [
          NotificationPermission.Alert,
          NotificationPermission.Sound,
          NotificationPermission.Badge,
          NotificationPermission.Vibration,
          NotificationPermission.PreciseAlarms,
        ],
      );
    } catch (e) {
      print('⚠️ Permissions précises non disponibles: $e');
      return true; // Continue sans permissions précises
    }
  }


  /// Programme une notification de contrôle technique
  static Future<void> scheduleTechnicalControlReminder({
    required int vehicleId,
    required String vehiclePlate,
    required DateTime technicalControlDate,
  }) async {
    // Programmer 3 notifications : 7, 3 et 1 jour avant
    final List<int> daysBefore = [7, 3, 1];
    
    for (int days in daysBefore) {
      final scheduledDate = technicalControlDate.subtract(Duration(days: days));
      
      // Ne programmer que si la date est dans le futur
      if (scheduledDate.isAfter(DateTime.now())) {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: _generateTechnicalControlId(vehicleId, days),
            channelKey: 'scheduled_channel',
            title: 'Contrôle technique à prévoir',
            body: days == 1 
                ? 'Demain ! Contrôle technique pour $vehiclePlate'
                : 'Dans $days jours - Contrôle technique pour $vehiclePlate',
            notificationLayout: NotificationLayout.Default,
            payload: {'type': 'technical_control', 'vehicle_id': vehicleId.toString()},
          ),
          schedule: NotificationCalendar.fromDate(date: scheduledDate),
        );
      }
    }
    
    print('📅 Rappels contrôle technique programmés pour $vehiclePlate');
  }

  /// Programme une notification de rendez-vous
  static Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required String garageName,
    required DateTime appointmentDate,
    required String service,
  }) async {
    final now = DateTime.now();
    DateTime reminderDate;
    
    // Calculer la date de rappel selon la proximité du RDV
    final daysDifference = appointmentDate.difference(now).inDays;
    
    if (daysDifference == 0) {
      // RDV aujourd'hui : rappel dans 1 heure (si possible)
      reminderDate = now.add(const Duration(hours: 1));
    } else if (daysDifference == 1) {
      // RDV demain : rappel dans 2 heures ou demain matin à 9h
      if (now.hour < 20) {
        // Il est encore tôt, rappel dans 2 heures
        reminderDate = now.add(const Duration(hours: 2));
      } else {
        // Il est tard, rappel demain matin à 9h
        reminderDate = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day - 1, 9, 0);
      }
    } else {
      // RDV dans plusieurs jours : rappel la veille à 9h
      reminderDate = DateTime(appointmentDate.year, appointmentDate.month, appointmentDate.day - 1, 9, 0);
    }
    
    if (reminderDate.isAfter(now)) {
      try {
        await AwesomeNotifications().createNotification(
          content: NotificationContent(
            id: _generateAppointmentId(appointmentId, 'reminder'),
            channelKey: 'scheduled_channel',
            title: 'Rendez-vous demain',
            body: 'RDV chez $garageName pour $service',
            notificationLayout: NotificationLayout.Default,
            payload: {'type': 'appointment', 'appointment_id': appointmentId.toString()},
          ),
          schedule: NotificationCalendar.fromDate(date: reminderDate),
        );
        print('📅 Rappel programmé pour le ${DateFormat('dd/MM/yyyy à HH:mm').format(reminderDate)}');
      } catch (e) {
        print('❌ Erreur programmation notification RDV: $e');
      }
    }
  }

  /// Programme une notification immédiate (nouveau rendez-vous créé, etc.)
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: DateTime.now().millisecondsSinceEpoch % 100000,
        channelKey: 'instant_channel',
        title: title,
        body: body,
        notificationLayout: NotificationLayout.Default,
        payload: payload != null ? {'data': payload} : null,
      ),
    );
  }


  /// Annule les notifications d'un contrôle technique
  static Future<void> cancelTechnicalControlReminders(int vehicleId) async {
    final List<int> daysBefore = [7, 3, 1];
    
    for (int days in daysBefore) {
      await AwesomeNotifications().cancel(_generateTechnicalControlId(vehicleId, days));
    }
    
    print('❌ Rappels contrôle technique annulés pour véhicule $vehicleId');
  }

  /// Annule les notifications d'un rendez-vous
  static Future<void> cancelAppointmentReminders(int appointmentId) async {
    await AwesomeNotifications().cancel(_generateAppointmentId(appointmentId, 'reminder'));
    await AwesomeNotifications().cancel(_generateAppointmentId(appointmentId, 'today'));
    
    print('❌ Rappels rendez-vous annulés pour $appointmentId');
  }

  /// Génère un ID unique pour les notifications de contrôle technique
  static int _generateTechnicalControlId(int vehicleId, int daysBefore) {
    return int.parse('1$vehicleId$daysBefore'); // Préfixe 1 pour technique
  }

  /// Génère un ID unique pour les notifications de rendez-vous
  static int _generateAppointmentId(int appointmentId, String type) {
    final typeCode = type == 'reminder' ? 1 : 2;
    // Utiliser un ID plus petit pour éviter le dépassement 32-bit
    final safeId = (appointmentId % 1000000) + (typeCode * 1000000) + 20000000; // Préfixe 2 pour RDV
    return safeId;
  }

  /// Annule toutes les notifications programmées
  static Future<void> cancelAllNotifications() async {
    await AwesomeNotifications().cancelAll();
    print('❌ Toutes les notifications annulées');
  }

  /// Liste les notifications programmées (debug)
  static Future<void> listPendingNotifications() async {
    final List<NotificationModel> pendingNotifications =
        await AwesomeNotifications().listScheduledNotifications();
    
    print('📋 Notifications programmées: ${pendingNotifications.length}');
    for (var notification in pendingNotifications) {
      print('  - ID: ${notification.content?.id}, Title: ${notification.content?.title}');
    }
  }
}