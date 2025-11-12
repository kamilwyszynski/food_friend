import 'dart:convert';
import '../config.dart';
import 'api_client.dart';

class MobileChatService {
  final ApiClient _api = ApiClient();
  String? _sessionId;

  String? get sessionId => _sessionId;

  Future<String> sendMessage(String message) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/chat/');
    final payload = jsonEncode({
      'message': message,
      'session_id': _sessionId,
    });
    final res = await _api.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: payload,
    );
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      _sessionId = body['session_id'] as String? ?? _sessionId;
      final dynamic raw = body['response'];
      return _extractAssistantText(raw);
    }
    throw Exception('Chat error: ${res.statusCode} ${res.body}');
  }

  String _extractAssistantText(dynamic val) {
    // Case 1: dict with messages
    if (val is Map && val.containsKey('messages')) {
      final msgs = (val['messages'] as List?) ?? [];
      for (int i = msgs.length - 1; i >= 0; i--) {
        final m = msgs[i];
        if (m is Map && m['role'] == 'assistant') {
          final c = m['content'];
          if (c is String) return c;
        }
      }
      return val.toString();
    }
    // Case 2: JSON string
    if (val is String) {
      try {
        final j = jsonDecode(val);
        if (j is Map && j.containsKey('messages')) {
          final msgs = (j['messages'] as List?) ?? [];
          for (int i = msgs.length - 1; i >= 0; i--) {
            final m = msgs[i];
            if (m is Map && m['role'] == 'assistant') {
              final c = m['content'];
              if (c is String) return c;
            }
          }
        }
      } catch (_) {
        // Not JSON; try LangGraph/LC repr regex fallbacks
        final aiMsg = RegExp(r"AIMessage\(content='([\s\S]*?)'", multiLine: true);
        final matches = aiMsg.allMatches(val).toList();
        if (matches.isNotEmpty) {
          return matches.last.group(1) ?? val;
        }
        final roleContent = RegExp(
          r"role['\"]\s*[:=]\s*['\"]assistant['\"][\s\S]*?content['\"]\s*[:=]\s*['\"]([\s\S]*?)['\"]",
          multiLine: true,
        ).allMatches(val).toList();
        if (roleContent.isNotEmpty) {
          return roleContent.last.group(1) ?? val;
        }
      }
      return val;
    }
    // Fallback
    return val?.toString() ?? '';
  }
}


