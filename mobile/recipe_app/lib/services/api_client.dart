import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiClient {
  final SupabaseClient _supabase = Supabase.instance.client;

  Map<String, String> _withAuth(Map<String, String>? headers, String token) {
    final result = <String, String>{};
    if (headers != null) {
      result.addAll(headers);
    }
    result[HttpHeaders.authorizationHeader] = 'Bearer $token';
    return result;
  }

  Future<String> _requireToken() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Not authenticated');
    }
    return session.accessToken;
  }

  Future<void> _refreshSession() async {
    await _supabase.auth.refreshSession();
  }

  Future<http.Response> get(Uri uri, {Map<String, String>? headers}) async {
    var token = await _requireToken();
    var res = await http.get(uri, headers: _withAuth(headers, token));
    if (res.statusCode != 401) return res;

    await _refreshSession();
    final session = _supabase.auth.currentSession;
    if (session == null) {
      return res;
    }
    res = await http.get(uri, headers: _withAuth(headers, session.accessToken));
    // Do not auto sign-out; surface response to caller
    return res;
  }

  Future<http.Response> put(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) async {
    var token = await _requireToken();
    var res = await http.put(
      uri,
      headers: _withAuth(headers, token),
      body: body,
      encoding: encoding,
    );
    if (res.statusCode != 401) return res;

    await _refreshSession();
    final session = _supabase.auth.currentSession;
    if (session == null) {
      return res;
    }
    res = await http.put(
      uri,
      headers: _withAuth(headers, session.accessToken),
      body: body,
      encoding: encoding,
    );
    // Do not auto sign-out; surface response to caller
    return res;
  }

  Future<http.StreamedResponse> postMultipart(
    Uri uri, {
    required List<http.MultipartFile> files,
    Map<String, String>? fields,
    Map<String, String>? headers,
  }) async {
    Future<http.StreamedResponse> _sendWithToken(String token) async {
      final request = http.MultipartRequest('POST', uri);
      if (fields != null) {
        request.fields.addAll(fields);
      }
      request.files.addAll(files);
      request.headers.addAll(_withAuth(headers, token));
      return request.send();
    }

    var token = await _requireToken();
    var res = await _sendWithToken(token);
    if (res.statusCode != 401) return res;

    await _refreshSession();
    final session = _supabase.auth.currentSession;
    if (session == null) {
      return res;
    }
    res = await _sendWithToken(session.accessToken);
    // Do not auto sign-out; surface response to caller
    return res;
  }
}


