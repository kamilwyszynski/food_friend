import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/recipe_service.dart';
import '../models/recipe.dart';
import '../widgets/recipe_display.dart';
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chat = MobileChatService();
  final _controller = TextEditingController();
  final List<_Msg> _messages = [];
  final _recipeService = RecipeService();
  bool _sending = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _messages.add(_Msg(role: 'user', content: text));
      _controller.clear();
    });
    try {
      final reply = await _chat.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(role: 'assistant', content: reply));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sous Chef'),
        backgroundColor: Colors.orange.shade300,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, i) {
                final m = _messages[i];
                final isUser = m.role == 'user';
                final recipeId = _extractRecipeId(m.content);
                if (!isUser && recipeId != null) {
                  return FutureBuilder<Recipe>(
                    future: _recipeService.getRecipeById(recipeId),
                    builder: (context, snap) {
                      Widget inner;
                      if (snap.connectionState != ConnectionState.done) {
                        inner = const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                        );
                      } else if (snap.hasError) {
                        inner = Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text('Failed to load recipe #$recipeId: ${snap.error}', style: const TextStyle(color: Colors.red)),
                        );
                      } else {
                        inner = RecipeDisplay(recipe: snap.data!);
                      }
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          constraints: const BoxConstraints(maxWidth: 480),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.brown.withOpacity(0.1),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: inner,
                        ),
                      );
                    },
                  );
                }
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 480),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.orange.shade200 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.brown.withOpacity(0.1),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: isUser
                        ? Text(
                            m.content,
                            style: const TextStyle(fontSize: 15, color: Colors.brown),
                          )
                        : MarkdownBody(
                            data: _stripRecipeFences(m.content),
                            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                              p: const TextStyle(fontSize: 15, color: Colors.brown),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Message Sous Chef...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _Msg {
  final String role;
  final String content;
  _Msg({required this.role, required this.content});
}

int? _extractRecipeId(String content) {
  // Detect a fenced block like:
  // ```recipe\n{ "id": 123 }\n```
  final start = content.indexOf('```recipe');
  if (start == -1) return null;
  final fenceEnd = content.indexOf('```', start + 8);
  if (fenceEnd == -1) return null;
  final block = content.substring(start + '```recipe'.length, fenceEnd).trim();
  // Expect JSON with id
  try {
    final json = block.startsWith('{') ? block : content.substring(start + 9, fenceEnd).trim();
    final map = _tryParseJson(json);
    if (map == null) return null;
    final idVal = map['id'];
    if (idVal is int) return idVal;
    if (idVal is String) return int.tryParse(idVal);
  } catch (_) {}
  return null;
}

Map<String, dynamic>? _tryParseJson(String s) {
  try {
    return jsonDecode(s) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

String _stripRecipeFences(String text) {
  final start = text.indexOf('```recipe');
  if (start == -1) return text;
  final end = text.indexOf('```', start + 8);
  if (end == -1) return text;
  // Remove the fenced block and leave surrounding prose
  return (text.substring(0, start) + text.substring(end + 3)).trim();
}


