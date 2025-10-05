import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';
import 'api_client.dart';
import '../models/preferences.dart';

class PreferencesService {
  final ApiClient _api = ApiClient();

  Future<Preferences?> getMyPreferences() async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/preferences/me');
    final res = await _api.get(uri);
    if (res.statusCode == 200) {
      final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
      return Preferences.fromJson(jsonMap);
    }
    if (res.statusCode == 404) return null;
    throw Exception('Failed to load preferences: ${res.statusCode} ${res.body}');
  }

  Future<Preferences> upsertMyPreferences(Preferences prefs) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/preferences/me');
    final res = await _api.put(
      uri,
      headers: { 'Content-Type': 'application/json' },
      body: jsonEncode(prefs.toJson()),
    );
    if (res.statusCode == 200) {
      final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
      return Preferences.fromJson(jsonMap);
    }
    throw Exception('Failed to save preferences: ${res.statusCode} ${res.body}');
  }
}


