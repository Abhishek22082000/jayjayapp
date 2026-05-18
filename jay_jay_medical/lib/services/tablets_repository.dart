import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/tablet.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);
  final int statusCode;
  final String message;
  @override
  String toString() => 'ApiException($statusCode): $message';
}

class TabletsRepository {
  TabletsRepository({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;

  Uri _u(String path) {
    if (!AppConfig.hasBaseUrl) {
      throw ApiException(
        0,
        'API_BASE_URL is not set. Pass it with --dart-define=API_BASE_URL=...',
      );
    }
    final String base = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl.substring(0, AppConfig.apiBaseUrl.length - 1)
        : AppConfig.apiBaseUrl;
    return Uri.parse('$base$path');
  }

  Map<String, String> _headers({bool json = false}) {
    return <String, String>{
      if (json) 'Content-Type': 'application/json',
      if (AppConfig.apiToken.isNotEmpty)
        'Authorization': 'Bearer ${AppConfig.apiToken}',
    };
  }

  Future<List<Tablet>> fetchAll() async {
    final http.Response res =
        await _client.get(_u('/api/tablets'), headers: _headers());
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, res.body);
    }
    final Map<String, dynamic> body =
        jsonDecode(res.body) as Map<String, dynamic>;
    final List<dynamic> raw = (body['tablets'] as List<dynamic>?) ?? <dynamic>[];
    return raw
        .map((dynamic e) => Tablet.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Tablet> add(Tablet t) async {
    final http.Response res = await _client.post(
      _u('/api/tablets'),
      headers: _headers(json: true),
      body: jsonEncode(t.toJsonPayload()),
    );
    if (res.statusCode != 201) {
      throw ApiException(res.statusCode, res.body);
    }
    return Tablet.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<Tablet> update(Tablet t) async {
    final http.Response res = await _client.put(
      _u('/api/tablets/${Uri.encodeComponent(t.id)}'),
      headers: _headers(json: true),
      body: jsonEncode(t.toJsonPayload()),
    );
    if (res.statusCode != 200) {
      throw ApiException(res.statusCode, res.body);
    }
    return Tablet.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    final http.Response res = await _client.delete(
      _u('/api/tablets/${Uri.encodeComponent(id)}'),
      headers: _headers(),
    );
    if (res.statusCode != 204 && res.statusCode != 200) {
      throw ApiException(res.statusCode, res.body);
    }
  }
}
