import 'package:flutter/material.dart';
import 'package:save_your_car/api_service/user_vehicles.dart';
import 'package:save_your_car/widgets/Main_scaffold.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/services/appointment_service.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'package:save_your_car/services/notification_service.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:intl/intl.dart';

// Classe pour représenter un événement du calendrier
class CalendarEvent {
  final String title;
  final String type; // 'appointment' ou 'technical_control'
  final Color color;
  final String? details;
  final String? vehicleInfo; // Ajout des informations du véhicule

  CalendarEvent({
    required this.title,
    required this.type,
    required this.color,
    this.details,
    this.vehicleInfo,
  });
}

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _selectedTime = "10:00";
  String _selectedService = "Révision générale";
  String _garageName = "";
  String _description = "";
  List<Map<String, dynamic>> _userVehicles = [];
  List<Map<String, dynamic>> _userAppointments = [];
  List<VehicleData> _vehicles = [];
  int? _selectedVehicleId;
  bool _isLoading = false;
  bool _isLoadingAppointments = true;
  
  // Map pour stocker les événements du calendrier
  Map<DateTime, List<CalendarEvent>> _calendarEvents = {};
  
  final textStyle = FigmaTextStyles();
  final _garageController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadVehicles();
  }

  Future<void> _checkAuthAndLoadVehicles() async {
    // Vérifier d'abord si l'utilisateur est connecté
    final isLoggedIn = await AuthService.isLoggedIn();
    print('🔐 Utilisateur connecté: $isLoggedIn');
    
    if (!isLoggedIn) {
      // Rediriger vers la page de connexion si pas connecté
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }
    
    // Charger les véhicules et rendez-vous si connecté
    _loadUserVehicles();
    _loadUserAppointments();
  }

  @override
  void dispose() {
    _garageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserVehicles() async {
    try {
      // Récupère le token depuis AuthService
      final token = await AuthService.getToken();

      if (token == null) {
        print('❌ Token manquant pour charger les véhicules');
        return;
      }

      // Appelle l'API avec le token
      final vehicles = await getUserVehicles(token);

      // Convertit VehicleData en Map<String, dynamic>
      final vehiclesMap = vehicles.map((vehicle) => {
        'id': vehicle.id,
        'plate': vehicle.plate,
        'model': vehicle.model,
        'brand': vehicle.brand,
        'year': vehicle.year,
        'mileage': vehicle.mileage,
      }).toList();
      
      setState(() {
        _vehicles = vehicles; // Stocker les véhicules complets
        _userVehicles = vehiclesMap;
        if (_userVehicles.isNotEmpty) {
          _selectedVehicleId = _userVehicles[0]['id'];
        }
      });
      
      // Créer les événements de contrôle technique
      _updateCalendarEvents();
    } catch (e) {
      print('Erreur chargement véhicules: $e');
    }
  }

  Future<void> _loadUserAppointments() async {
    try {
      setState(() {
        _isLoadingAppointments = true;
      });

      final appointments = await AppointmentService.getUserAppointments();
      
      setState(() {
        _userAppointments = appointments;
        _isLoadingAppointments = false;
      });
      
      // Mettre à jour les événements du calendrier
      _updateCalendarEvents();
    } catch (e) {
      print('Erreur chargement rendez-vous: $e');
      setState(() {
        _isLoadingAppointments = false;
      });
    }
  }

  /// Met à jour les événements du calendrier avec les contrôles techniques et rendez-vous
  void _updateCalendarEvents() {
    final Map<DateTime, List<CalendarEvent>> events = {};
    
    // Ajouter les contrôles techniques
    for (final vehicle in _vehicles) {
      if (vehicle.technicalControlDate != null) {
        // Ajouter 2 ans à la date de contrôle technique de la base pour obtenir la prochaine échéance
        final nextTechnicalControlDate = DateTime(
          vehicle.technicalControlDate!.year + 2,
          vehicle.technicalControlDate!.month,
          vehicle.technicalControlDate!.day,
        );
        
        final date = DateTime(
          nextTechnicalControlDate.year,
          nextTechnicalControlDate.month,
          nextTechnicalControlDate.day,
        );
        
        final event = CalendarEvent(
          title: 'Contrôle technique ${vehicle.plate}',
          type: 'technical_control',
          color: Colors.orange,
          details: '${vehicle.brand} ${vehicle.model}',
          vehicleInfo: '${vehicle.brand} ${vehicle.model} - ${vehicle.plate}',
        );
        
        if (events[date] == null) {
          events[date] = [];
        }
        events[date]!.add(event);
      }
    }
    
    // Ajouter les rendez-vous
    for (final appointment in _userAppointments) {
      try {
        final dateStr = appointment['date']?.toString();
        if (dateStr != null) {
          final appointmentDate = DateTime.parse(dateStr);
          final date = DateTime(
            appointmentDate.year,
            appointmentDate.month,
            appointmentDate.day,
          );
          
          final event = CalendarEvent(
            title: '${appointment['garage_name']} - ${appointment['service']}',
            type: 'appointment',
            color: FigmaColors.primaryMain,
            details: appointment['description']?.toString(),
            vehicleInfo: _getVehicleInfoForAppointment(appointment),
          );
          
          if (events[date] == null) {
            events[date] = [];
          }
          events[date]!.add(event);
        }
      } catch (e) {
        print('Erreur parsing date rendez-vous: $e');
      }
    }
    
    setState(() {
      _calendarEvents = events;
    });
    
    print('📅 Événements calendrier mis à jour: ${events.length} jours avec événements');
    events.forEach((date, eventList) {
      print('📍 Date: ${date.day}/${date.month}/${date.year} - ${eventList.length} événements');
      for (var event in eventList) {
        print('   - ${event.type}: ${event.title}');
      }
    });
  }

  /// Retourne les événements pour un jour donné (utilisé par le calendrier)
  List<CalendarEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _calendarEvents[normalizedDay] ?? [];
  }

  Future<void> _createAppointment() async {
    if (_selectedDay == null) {
      _showErrorDialog('Veuillez sélectionner une date');
      return;
    }

    if (_garageName.isEmpty) {
      _showErrorDialog('Veuillez entrer le nom du garage');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AppointmentService.createAppointment(
        garageName: _garageName,
        date: AppointmentService.formatDateForApi(_selectedDay!),
        time: _selectedTime,
        service: _selectedService,
        description: _description,
        vehicleId: _selectedVehicleId,
      );

      if (mounted) {
        // Programmer les notifications pour le nouveau rendez-vous
        try {
          // Construire la date complète du rendez-vous
          final appointmentDateTime = DateTime(
            _selectedDay!.year,
            _selectedDay!.month,
            _selectedDay!.day,
            int.parse(_selectedTime.split(':')[0]), // Heure
            int.parse(_selectedTime.split(':')[1]), // Minutes
          );
          
          // Programmer les notifications (on utilise un ID temporaire car on n'a pas l'ID réel)
          await NotificationService.scheduleAppointmentReminder(
            appointmentId: DateTime.now().millisecondsSinceEpoch % 1000000, // ID temporaire plus petit
            garageName: _garageName,
            appointmentDate: appointmentDateTime,
            service: _selectedService,
          );
          
          // Notification instantanée
          await NotificationService.showInstantNotification(
            title: 'Rendez-vous confirmé',
            body: 'RDV le ${DateFormat('dd/MM/yyyy').format(_selectedDay!)} chez $_garageName',
          );
        } catch (e) {
          print('❌ Erreur programmation notifications RDV: $e');
        }
        
        // Recharger la liste des rendez-vous
        _loadUserAppointments();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Erreur lors de la création: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Succès'),
        content: const Text('Rendez-vous créé avec succès !'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer seulement la dialog
              // Réinitialiser le formulaire
              _resetForm();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedDay = null;
      _selectedTime = "10:00";
      _selectedService = "Révision générale";
      _garageName = "";
      _description = "";
      _garageController.clear();
      _descriptionController.clear();
      if (_userVehicles.isNotEmpty) {
        _selectedVehicleId = _userVehicles[0]['id'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      currentIndex: 2,
      child: Scaffold(
        backgroundColor: FigmaColors.neutral00,
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // AppBar noire
              Container(
                height: 162,
                width: double.infinity,
                color: FigmaColors.neutral100,
                padding: const EdgeInsets.only(top: 68, left: 24, right: 24),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "RDV",
                      style: textStyle.headingSBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
      
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Pense-bêtes (Contrôles techniques)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "📝 Pense-bêtes",
                              style: textStyle.headingMMedium.copyWith(
                                color: FigmaColors.neutral100,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._buildTechnicalControlReminders(),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Section des rendez-vous existants
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Mes rendez-vous",
                              style: textStyle.headingMMedium.copyWith(
                                color: FigmaColors.neutral100,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _isLoadingAppointments
                                ? const Center(child: CircularProgressIndicator())
                                : _userAppointments.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: FigmaColors.neutral10,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: FigmaColors.neutral20),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.event_busy,
                                              color: Colors.grey[400],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              "Aucun rendez-vous planifié",
                                              style: textStyle.textMRegular.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Column(
                                        children: _userAppointments.map((appointment) {
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: FigmaColors.neutral10,
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: FigmaColors.neutral20),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 48,
                                                  height: 48,
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(appointment['status']).withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    _getStatusIcon(appointment['status']),
                                                    color: _getStatusColor(appointment['status']),
                                                    size: 24,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        appointment['garage_name'] ?? 'Garage',
                                                        style: textStyle.textMSemiBold,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        "${_formatDate(appointment['date'])} à ${appointment['time']}",
                                                        style: textStyle.textMRegular.copyWith(
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        appointment['service'] ?? 'Service',
                                                        style: textStyle.textMRegular.copyWith(
                                                          color: FigmaColors.primaryMain,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                Column(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _getStatusColor(appointment['status']),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        _getStatusLabel(appointment['status']),
                                                        style: textStyle.textMMedium.copyWith(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    _buildAppointmentActions(appointment),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                          ],
                                        ),
                                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Section nouveau rendez-vous
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "Nouveau rendez-vous",
                          style: textStyle.headingMMedium.copyWith(
                            color: FigmaColors.neutral100,
                          ),
                        ),
                      ),
                      
                      // Calendrier
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: FigmaColors.neutral10,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              TableCalendar(
                                firstDay: DateTime.utc(2020, 1, 1),
                                lastDay: DateTime.utc(2030, 12, 31),
                                focusedDay: _focusedDay,
                                selectedDayPredicate:
                                    (day) => isSameDay(_selectedDay, day),
                                eventLoader: _getEventsForDay,
                                onDaySelected: (selected, focused) {
                                  setState(() {
                                    _selectedDay = selected;
                                    _focusedDay = focused;
                                  });
                                },
                                calendarBuilders: CalendarBuilders(
                                  markerBuilder: (context, day, events) {
                                    // Récupérer directement les événements pour ce jour
                                    final dayEvents = _getEventsForDay(day);
                                    if (dayEvents.isNotEmpty) {
                                      return _buildCustomMarkers(dayEvents);
                                    }
                                    return null;
                                  },
                                ),
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                  leftChevronIcon: Icon(
                                    Icons.chevron_left,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                  rightChevronIcon: Icon(
                                    Icons.chevron_right,
                                    size: 20,
                                    color: Colors.black,
                                  ),
                                  titleTextStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  decoration: BoxDecoration(), // pas de fond
                                ),
                                calendarStyle: CalendarStyle(
                                  selectedDecoration: const BoxDecoration(
                                    color: FigmaColors.primaryMain, // couleur violette
                                    shape: BoxShape.circle,
                                  ),
                                  todayDecoration: BoxDecoration(
                                    color: FigmaColors.primaryFocus,
                                    shape: BoxShape.circle,
                                  ),
                                  defaultTextStyle: const TextStyle(
                                    color: Colors.black,
                                  ),
                                  weekendTextStyle: const TextStyle(
                                    color: Colors.black,
                                  ),
                                  selectedTextStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  todayTextStyle: const TextStyle(
                                    color: Colors.black,
                                  ),
                                  outsideTextStyle: const TextStyle(
                                    color: Colors.grey,
                                  ),
                                  markersMaxCount: 0, // Désactiver les marqueurs par défaut
                                ),
                                daysOfWeekStyle: const DaysOfWeekStyle(
                                  weekdayStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                  weekendStyle: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
      
                              const SizedBox(height: 16),

                              // Événements du jour sélectionné
                              if (_selectedDay != null && _getEventsForDay(_selectedDay!).isNotEmpty) ...[
                                Text(
                                  "Événements du ${DateFormat('dd/MM/yyyy').format(_selectedDay!)}",
                                  style: textStyle.textLSemiBold,
                                ),
                                const SizedBox(height: 8),
                                ...(_getEventsForDay(_selectedDay!).map((event) => Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: event.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: event.color.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        event.type == 'technical_control' 
                                            ? Icons.build_circle 
                                            : Icons.event,
                                        color: event.color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              event.title,
                                              style: textStyle.textLMedium.copyWith(
                                                color: event.color,
                                              ),
                                            ),
                                            if (event.details != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                event.details!,
                                                style: textStyle.textMRegular.copyWith(
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                            if (event.vehicleInfo != null) ...[
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.directions_car,
                                                    size: 14,
                                                    color: Colors.grey[600],
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      event.vehicleInfo!,
                                                      style: textStyle.textMRegular.copyWith(
                                                        color: Colors.grey[600],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ))),
                                const SizedBox(height: 16),
                              ],
                              
                              // Sélection de l'heure
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Heure: $_selectedTime",
                                    style: textStyle.textLSemiBold,
                                  ),
                                  DropdownButton<String>(
                                    value: _selectedTime,
                                    underline: const SizedBox(),
                                    items: AppointmentService.getAvailableTimeSlots()
                                        .map((time) => DropdownMenuItem(
                                              value: time,
                                              child: Text(time),
                                            ))
                                        .toList(),
                                    onChanged: (value) => setState(() => _selectedTime = value!),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
      
                      // Formulaire de rendez-vous
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sélection du véhicule
                            if (_userVehicles.isNotEmpty) ...[
                              Text("Véhicule", style: textStyle.textLSemiBold),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: FigmaColors.neutral10,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: FigmaColors.neutral20),
                                ),
                                child: DropdownButton<int>(
                                  value: _selectedVehicleId,
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items: _userVehicles.map((vehicle) {
                                    return DropdownMenuItem<int>(
                                      value: vehicle['id'],
                                      child: Text(
                                        "${vehicle['brand']} ${vehicle['model']} - ${vehicle['plate']}",
                                        style: textStyle.textMRegular,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) => setState(() => _selectedVehicleId = value),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Nom du garage
                            Text("Garage", style: textStyle.textLSemiBold),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _garageController,
                              onChanged: (value) => _garageName = value,
                              decoration: InputDecoration(
                                hintText: "Nom du garage",
                                filled: true,
                                fillColor: FigmaColors.neutral10,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: FigmaColors.neutral20),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: FigmaColors.neutral20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Type de service
                            Text("Service", style: textStyle.textLSemiBold),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              decoration: BoxDecoration(
                                color: FigmaColors.neutral10,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: FigmaColors.neutral20),
                              ),
                              child: DropdownButton<String>(
                                value: _selectedService,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: AppointmentService.getServiceTypes()
                                    .map((service) => DropdownMenuItem(
                                          value: service,
                                          child: Text(service, style: textStyle.textMRegular),
                                        ))
                                    .toList(),
                                onChanged: (value) => setState(() => _selectedService = value!),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Description
                            Text("Description (optionnel)", style: textStyle.textLSemiBold),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _descriptionController,
                              onChanged: (value) => _description = value,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: "Détails supplémentaires...",
                                filled: true,
                                fillColor: FigmaColors.neutral10,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: FigmaColors.neutral20),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: FigmaColors.neutral20),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
      
                      const SizedBox(height: 24),
      
                      // Bouton
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FigmaColors.primaryMain,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading ? null : _createAppointment,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Prendre un RDV",
                                    style: TextStyle(color: Colors.white, fontSize: 16),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    try {
      if (dateString == null) return 'Date inconnue';
      
      DateTime date;
      if (dateString is String) {
        date = DateTime.parse(dateString);
      } else {
        date = dateString as DateTime;
      }
      
      const months = [
        '', 'janv', 'févr', 'mars', 'avr', 'mai', 'juin',
        'juil', 'août', 'sept', 'oct', 'nov', 'déc'
      ];
      
      return "${date.day} ${months[date.month]} ${date.year}";
    } catch (e) {
      return 'Date invalide';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'validated':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      case 'completed':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      case 'rejected':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'validated':
        return 'Validé';
      case 'confirmed':
        return 'Confirmé';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      case 'rejected':
        return 'Refusé';
      default:
        return 'Inconnu';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'validated':
        return Icons.check_circle_outline;
      case 'confirmed':
        return Icons.check_circle;
      case 'completed':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'rejected':
        return Icons.close;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildAppointmentActions(Map<String, dynamic> appointment) {
    final status = appointment['status']?.toString().toLowerCase();
    
    switch (status) {
      case 'pending':
        // En attente : peut valider ou annuler
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionButton(
              icon: Icons.check,
              color: Colors.green,
              onTap: () => _updateAppointmentStatus(appointment['id'], 'validated'),
            ),
            const SizedBox(width: 4),
            _actionButton(
              icon: Icons.close,
              color: Colors.red,
              onTap: () => _updateAppointmentStatus(appointment['id'], 'cancelled'),
            ),
          ],
        );
        
      case 'validated':
        // Validé : peut confirmer ou annuler
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionButton(
              icon: Icons.done,
              color: Colors.blue,
              onTap: () => _updateAppointmentStatus(appointment['id'], 'confirmed'),
            ),
            const SizedBox(width: 4),
            _actionButton(
              icon: Icons.close,
              color: Colors.red,
              onTap: () => _updateAppointmentStatus(appointment['id'], 'cancelled'),
            ),
          ],
        );
        
      case 'confirmed':
        // Confirmé : peut marquer comme terminé ou annuler
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionButton(
              icon: Icons.done_all,
              color: Colors.purple,
              onTap: () => _updateAppointmentStatus(appointment['id'], 'completed'),
            ),
            const SizedBox(width: 4),
            _actionButton(
              icon: Icons.close,
              color: Colors.red,
              onTap: () => _updateAppointmentStatus(appointment['id'], 'cancelled'),
            ),
          ],
        );
        
      case 'completed':
      case 'cancelled':
      case 'rejected':
        // États finaux : peut supprimer
        return _actionButton(
          icon: Icons.delete_outline,
          color: Colors.grey.shade600,
          onTap: () => _deleteAppointment(appointment['id']),
        );
        
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: color,
        ),
      ),
    );
  }

  Future<void> _updateAppointmentStatus(int appointmentId, String newStatus) async {
    try {
      // Afficher une confirmation pour l'annulation
      if (newStatus == 'cancelled') {
        final confirm = await _showConfirmDialog(
          'Annuler le rendez-vous',
          'Êtes-vous sûr de vouloir annuler ce rendez-vous ?',
        );
        if (!confirm) return;
      }

      // Mettre à jour le statut
      await AppointmentService.updateAppointment(
        appointmentId: appointmentId,
        status: newStatus,
      );

      // Recharger la liste
      _loadUserAppointments();

      // Afficher un message de succès
      if (mounted) {
        String message = '';
        switch (newStatus) {
          case 'validated':
            message = 'Rendez-vous validé ✅';
            break;
          case 'confirmed':
            message = 'Rendez-vous confirmé 🎯';
            break;
          case 'completed':
            message = 'Rendez-vous marqué comme terminé ✨';
            break;
          case 'cancelled':
            message = 'Rendez-vous annulé ❌';
            break;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: newStatus == 'cancelled' ? Colors.red : Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAppointment(int appointmentId) async {
    try {
      // Afficher une confirmation
      final confirm = await _showConfirmDialog(
        'Supprimer le rendez-vous',
        'Êtes-vous sûr de vouloir supprimer définitivement ce rendez-vous ?',
      );
      if (!confirm) return;

      // Supprimer le rendez-vous
      await AppointmentService.deleteAppointment(appointmentId);

      // Recharger la liste
      _loadUserAppointments();

      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rendez-vous supprimé 🗑️'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Construit les cartes pense-bêtes pour les contrôles techniques
  List<Widget> _buildTechnicalControlReminders() {
    final List<Widget> reminders = [];
    final now = DateTime.now();
    
    // Trier les véhicules par date de contrôle technique (les plus proches en premier)
    final vehiclesWithTechnicalControl = _vehicles
        .where((vehicle) => vehicle.technicalControlDate != null)
        .toList()
        ..sort((a, b) {
          // Calculer les prochaines échéances pour le tri
          final nextDateA = DateTime(
            a.technicalControlDate!.year + 2,
            a.technicalControlDate!.month,
            a.technicalControlDate!.day,
          );
          final nextDateB = DateTime(
            b.technicalControlDate!.year + 2,
            b.technicalControlDate!.month,
            b.technicalControlDate!.day,
          );
          return nextDateA.compareTo(nextDateB);
        });

    if (vehiclesWithTechnicalControl.isEmpty) {
      reminders.add(
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: FigmaColors.neutral10,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FigmaColors.neutral20),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[400],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Aucune date de contrôle technique renseignée",
                  style: textStyle.textMRegular.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      return reminders;
    }

    for (final vehicle in vehiclesWithTechnicalControl) {
      // Calculer la prochaine échéance en ajoutant 2 ans à la date de la base
      final nextTechDate = DateTime(
        vehicle.technicalControlDate!.year + 2,
        vehicle.technicalControlDate!.month,
        vehicle.technicalControlDate!.day,
      );
      final daysDifference = nextTechDate.difference(now).inDays;
      
      // Définir la couleur selon l'urgence
      Color cardColor;
      Color iconColor;
      IconData icon;
      String urgencyText;
      
      if (daysDifference < 0) {
        // Expiré
        cardColor = Colors.red.shade50;
        iconColor = Colors.red;
        icon = Icons.warning_rounded;
        urgencyText = "Expiré depuis ${(-daysDifference)} jour(s) ⚠️";
      } else if (daysDifference <= 30) {
        // Urgent (moins de 30 jours)
        cardColor = Colors.orange.shade50;
        iconColor = Colors.orange;
        icon = Icons.schedule_rounded;
        urgencyText = "Dans $daysDifference jour(s) 🔥";
      } else if (daysDifference <= 90) {
        // À surveiller (moins de 3 mois)
        cardColor = Colors.yellow.shade50;
        iconColor = Colors.amber;
        icon = Icons.access_time_rounded;
        urgencyText = "Dans $daysDifference jour(s) ⏰";
      } else {
        // OK
        cardColor = Colors.green.shade50;
        iconColor = Colors.green;
        icon = Icons.check_circle_rounded;
        urgencyText = "Dans $daysDifference jour(s) ✅";
      }
      
      reminders.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: iconColor.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contrôle technique",
                      style: textStyle.textMSemiBold.copyWith(
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${vehicle.brand} ${vehicle.model} - ${vehicle.plate}",
                      style: textStyle.textMRegular.copyWith(
                        color: FigmaColors.neutral90,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Échéance: ${DateFormat('dd/MM/yyyy').format(nextTechDate)}",
                      style: textStyle.textLRegular.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: iconColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      urgencyText,
                      style: textStyle.textLSemiBold.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _scheduleControlReminder(vehicle, nextTechDate),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: iconColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.notification_add,
                            size: 14,
                            color: iconColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Rappel",
                            style: textStyle.textLSemiBold.copyWith(
                              color: iconColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return reminders;
  }

  /// Programme un rappel pour le contrôle technique
  Future<void> _scheduleControlReminder(VehicleData vehicle, DateTime techDate) async {
    try {
      // Vérifier qu'on peut programmer des rappels (au moins 1 jour avant)
      final oneDayBefore = techDate.subtract(const Duration(days: 1));
      
      if (oneDayBefore.isAfter(DateTime.now())) {
        // Utiliser la méthode appropriée du NotificationService
        await NotificationService.scheduleTechnicalControlReminder(
          vehicleId: vehicle.id!,
          vehiclePlate: vehicle.plate,
          technicalControlDate: techDate,
        );
        
        // Notification instantanée de confirmation
        await NotificationService.showInstantNotification(
          title: "Rappel programmé",
          body: "Vous serez notifié avant l'échéance du contrôle technique de votre ${vehicle.brand} ${vehicle.model}",
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("📱 Rappels programmés pour votre ${vehicle.brand} ${vehicle.model} (${vehicle.plate})"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("⚠️ Échéance trop proche pour programmer un rappel"),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Erreur programmation rappel contrôle technique: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la programmation du rappel: $e"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Construit des marqueurs personnalisés pour le calendrier
  Widget _buildCustomMarkers(List<CalendarEvent> events) {
    print('🎯 Building markers for ${events.length} events');
    
    return Positioned(
      bottom: 2,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: events.take(3).map((event) {
          final color = event.type == 'technical_control' ? Colors.orange : FigmaColors.primaryMain;
          print('📍 Creating marker: ${event.type} - Color: $color');
          
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }


  /// Récupère les informations du véhicule pour un rendez-vous
  String? _getVehicleInfoForAppointment(Map<String, dynamic> appointment) {
    final vehicleId = appointment['vehicle_id'];
    if (vehicleId != null) {
      // Trouver le véhicule correspondant dans la liste
      try {
        final vehicle = _vehicles.firstWhere(
          (v) => v.id == vehicleId,
        );
        return '${vehicle.brand} ${vehicle.model} - ${vehicle.plate}';
      } catch (e) {
        // Véhicule non trouvé
        return 'Véhicule non trouvé';
      }
    }
    return null;
  }

}
