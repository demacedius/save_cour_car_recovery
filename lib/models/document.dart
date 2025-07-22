class DocumentData {
  final int id;
  final int vehicleId;
  final String name;
  final String type;
  final String? description;
  final String fileName;
  final int fileSize;
  final String downloadUrl;
  final DateTime createdAt;

  DocumentData({
    required this.id,
    required this.vehicleId,
    required this.name,
    required this.type,
    this.description,
    required this.fileName,
    required this.fileSize,
    required this.downloadUrl,
    required this.createdAt,
  });

  factory DocumentData.fromJson(Map<String, dynamic> json) {
    return DocumentData(
      id: json['id'] ?? 0,
      vehicleId: json['vehicle_id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'],
      fileName: json['file_name'] ?? '',
      fileSize: json['file_size'] ?? 0,
      downloadUrl: json['download_url'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  String get typeDisplayName {
    switch (type) {
      case 'carte_grise':
        return 'Carte grise';
      case 'assurance':
        return 'Assurance';
      case 'controle_technique':
        return 'Contrôle technique';
      case 'facture':
        return 'Facture';
      default:
        return 'Autre';
    }
  }

  String get fileSizeFormatted {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}