import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/document.dart';

class DocumentService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<DocumentModel>> getMyDocuments({String? documentType}) async {
    try {
      String url = ApiConfig.myDocuments;
      if (documentType != null) url += '?document_type=$documentType';

      final response = await http.get(Uri.parse(url), headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => DocumentModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>> uploadDocument({
    required File file,
    required String documentType,
    required String documentName,
    int? employeeId,
  }) async {
    try {
      final token = await _authService.getToken();
      final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.uploadDocument));

      request.headers['Authorization'] = 'Bearer $token';
      request.fields['document_type'] = documentType;
      request.fields['document_name'] = documentName;
      if (employeeId != null) request.fields['employee_id'] = employeeId.toString();

      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);
      return {'success': response.statusCode == 201, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Upload failed: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteDocument(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.deleteDocument(id)),
        headers: await _headers(),
      );
      final data = json.decode(response.body);
      return {'success': response.statusCode == 200, ...data};
    } catch (e) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  Future<List<DocumentModel>> getAllDocuments({int? employeeId, String? documentType}) async {
    try {
      String url = ApiConfig.allDocuments;
      final params = <String>[];
      if (employeeId != null) params.add('employee_id=$employeeId');
      if (documentType != null) params.add('document_type=$documentType');
      if (params.isNotEmpty) url += '?${params.join('&')}';

      final response = await http.get(Uri.parse(url), headers: await _headers());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List).map((e) => DocumentModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}