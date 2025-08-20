// ignore_for_file: unused_import, avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:save_your_car/models/document.dart';
import 'package:save_your_car/services/auth_service.dart';
import 'package:save_your_car/config/api_config.dart';

class DocumentService {
  static String get baseUrl => ApiConfig.baseUrl;

  static Future<DocumentData?> uploadDocument({
    required int vehicleId,
    required String name,
    required String type,
    String? description,
    required File file,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ Aucun token trouvé');
        return null;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/documents'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['vehicle_id'] = vehicleId.toString();
      request.fields['name'] = name;
      request.fields['type'] = type;
      if (description != null) {
        request.fields['description'] = description;
      }

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Status upload: ${response.statusCode}');
      print('Response upload: $responseBody');

      if (response.statusCode == 201) {
        final data = jsonDecode(responseBody);
        return DocumentData.fromJson(data['document']);
      } else {
        print('❌ Erreur upload document: $responseBody');
        return null;
      }
    } catch (e) {
      print('Erreur lors de l\'upload: $e');
      return null;
    }
  }

  static Future<List<DocumentData>> getVehicleDocuments(int vehicleId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ Aucun token trouvé');
        return [];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/vehicles/$vehicleId/documents'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status documents: ${response.statusCode}');
      print('Response documents: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> documentsList = data['documents'] ?? [];
        
        return documentsList.map((docJson) {
          return DocumentData.fromJson(docJson);
        }).toList();
      } else {
        print('❌ Erreur récupération documents: ${response.body}');
        return [];
      }
    } catch (e) {
      print('Erreur lors de la récupération des documents: $e');
      return [];
    }
  }

  static Future<bool> deleteDocument(int documentId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ Aucun token trouvé');
        return false;
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/documents/$documentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status delete: ${response.statusCode}');
      print('Response delete: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur lors de la suppression: $e');
      return false;
    }
  }

  static String getDownloadUrl(int documentId) {
    return '$baseUrl/documents/$documentId/download';
  }

  /// Télécharge un document et le sauvegarde dans le dossier de téléchargements
  static Future<String?> downloadDocument(DocumentData document) async {
    try {
      // Pour Android, utiliser le dossier app sans permissions spéciales
      // Les permissions de stockage sont complexes sur Android 13+

      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (status.isDenied) {
          final result = await Permission.storage.request();
          if (result.isPermanentlyDenied) {
            await openAppSettings();
            return null;
          }
        }
      }

      final token = await AuthService.getToken();
      if (token == null) {
        print('❌ Aucun token trouvé');
        return null;
      }

      // Télécharger le fichier
      final response = await http.get(
        Uri.parse('$baseUrl/documents/${document.id}/download'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('📥 Status téléchargement: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Utiliser le dossier Downloads public (facilement accessible)
        late Directory downloadsDir;
        
        if (Platform.isAndroid) {
          // Utiliser directement le dossier Downloads standard d'Android
          downloadsDir = Directory('/storage/emulated/0/Download');
          
          // Si le dossier Downloads standard n'est pas accessible, utiliser external storage
          if (!downloadsDir.existsSync()) {
            try {
              final external = await getExternalStorageDirectory();
              if (external != null) {
                // Créer un dossier Downloads dans l'espace externe
                downloadsDir = Directory('${external.path}/Downloads');
                if (!downloadsDir.existsSync()) {
                  downloadsDir.createSync(recursive: true);
                }
              } else {
                throw Exception('External storage non disponible');
              }
            } catch (e) {
              // Dernière option : dossier Documents de l'app
              print('⚠️ Impossible d\'accéder aux dossiers externes, utilisation app: $e');
              downloadsDir = await getApplicationDocumentsDirectory();
            }
          }
        } else {
          // iOS - utiliser le dossier Documents
          downloadsDir = await getApplicationDocumentsDirectory();
        }
        
        // S'assurer que le dossier existe
        if (!downloadsDir.existsSync()) {
          downloadsDir.createSync(recursive: true);
        }

        // Créer le nom du fichier avec extension
        final extension = _getFileExtension(document.fileName);
        // Nettoyer le nom de fichier (enlever les caractères spéciaux)
        final cleanName = document.name.replaceAll(RegExp(r'[^\w\s-.]'), '_');
        final fileName = 'SaveYourCar_$cleanName$extension';
        final filePath = '${downloadsDir.path}/$fileName';

        // Sauvegarder le fichier
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        print('✅ Document téléchargé: $filePath');
        return filePath;
      } else {
        print('❌ Erreur téléchargement: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Erreur lors du téléchargement: $e');
      return null;
    }
  }

  /// Extrait l'extension du fichier à partir du chemin
  static String _getFileExtension(String filePath) {
    final lastDot = filePath.lastIndexOf('.');
    if (lastDot != -1 && lastDot < filePath.length - 1) {
      return filePath.substring(lastDot);
    }
    return '.pdf'; // Extension par défaut
  }

  /// Partage un fichier téléchargé via le système de partage Android
  static Future<void> shareDocument(String filePath, String documentName) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Document: $documentName',
          subject: 'Document SaveYourCar',
        );
        print('✅ Document partagé: $filePath');
      } else {
        print('❌ Fichier non trouvé: $filePath');
      }
    } catch (e) {
      print('❌ Erreur partage: $e');
    }
  }
}