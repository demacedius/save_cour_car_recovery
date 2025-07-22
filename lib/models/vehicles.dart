class VehicleData {
  final int? id;
  final String plate;
  final String model;
  final String brand;
  final String? imageUrl;
  final String? brandImageUrl;
  final int? year;
  final int? mileage;
  final DateTime? technicalControlDate;

  VehicleData({
    this.id,
    required this.plate,
    required this.model,
    required this.brand,
    this.imageUrl,
    this.brandImageUrl,
    this.year,
    this.mileage,
    this.technicalControlDate,
  });

  factory VehicleData.fromJson(Map<String, dynamic> json) {
    return VehicleData(
      id: json['id'],
      plate: json['plate'] ?? '',
      model: json['model'] ?? '',
      brand: json['brand'] ?? '',
      imageUrl: json['imageUrl'],
      brandImageUrl: json['brandImageUrl'],
      year: json['year'] != null ? int.tryParse(json['year'].toString()) : null,
      mileage: json['mileage'],
      technicalControlDate: json['technical_control_date'] != null
          ? _parseDate(json['technical_control_date'])
          : json['technicalControlDate'] != null
              ? _parseDate(json['technicalControlDate'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plate': plate,
      'model': model,
      'brand': brand,
      'imageUrl': imageUrl,
      'brandImageUrl': brandImageUrl,
      'year': year,
      'mileage': mileage,
      'technicalControlDate': technicalControlDate?.toUtc().toIso8601String(),
    };
  }

  VehicleData copyWith({
    int? id,
    String? plate,
    String? model,
    String? brand,
    String? imageUrl,
    String? brandImageUrl,
    int? year,
    int? mileage,
    DateTime? technicalControlDate,
  }) {
    return VehicleData(
      id: id ?? this.id,
      plate: plate ?? this.plate,
      model: model ?? this.model,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      brandImageUrl: brandImageUrl ?? this.brandImageUrl,
      year: year ?? this.year,
      mileage: mileage ?? this.mileage,
      technicalControlDate: technicalControlDate ?? this.technicalControlDate,
    );
  }

  // Fonction pour parser différents formats de date vers DateTime
  static DateTime? _parseDate(String dateStr) {
    try {
      // Nettoyer la chaîne
      String cleanDateStr = dateStr.trim();
      
      // Format ISO 8601 / RFC3339 (du backend) : "2024-10-11T00:00:00Z" ou "2024-10-11T00:00:00.000Z"
      if (cleanDateStr.contains('T')) {
        return DateTime.parse(cleanDateStr);
      }
      
      // Format "dd-mm-yyyy" (ancien format)
      if (cleanDateStr.contains('-') && cleanDateStr.length <= 10) {
        final parts = cleanDateStr.split('-');
        if (parts.length == 3) {
          // Vérifier si c'est dd-mm-yyyy ou yyyy-mm-dd
          if (parts[0].length == 4) {
            // Format yyyy-mm-dd
            final year = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final day = int.parse(parts[2]);
            return DateTime(year, month, day);
          } else {
            // Format dd-mm-yyyy
            final day = int.parse(parts[0]);
            final month = int.parse(parts[1]);
            final year = int.parse(parts[2]);
            return DateTime(year, month, day);
          }
        }
      }
      
      // Essayer le parsing automatique de Dart
      return DateTime.parse(cleanDateStr);
      
    } catch (e) {
      print('❌ Erreur parsing date: "$dateStr" - $e');
    }
    return null;
  }
}
