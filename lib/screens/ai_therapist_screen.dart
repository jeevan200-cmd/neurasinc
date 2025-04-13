import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';

class AITherapistScreen extends StatefulWidget {
  const AITherapistScreen({super.key});

  @override
  State<AITherapistScreen> createState() => _AITherapistScreenState();
}

class _AITherapistScreenState extends State<AITherapistScreen> {
  final List<types.Message> _messages = [];
  final _user = const types.User(id: 'user');
  final _therapist =
      const types.User(id: 'therapist', firstName: 'AI Therapist');
  bool _isTyping = false;
  final String _apiKey = const String.fromEnvironment('OPENAI_API_KEY');

  @override
  void initState() {
    super.initState();
    _addMessage(
      types.TextMessage(
        author: _therapist,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: 'Hello! I\'m your AI therapist. How are you feeling today?',
      ),
    );
  }

  void _addMessage(types.Message message) {
    setState(() {
      _messages.insert(0, message);
    });
  }

  Future<String> _getAIResponse(String message) async {
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo',
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a supportive and empathetic AI therapist. Provide helpful, therapeutic responses while maintaining professional boundaries.',
          },
          {
            'role': 'user',
            'content': message,
          },
        ],
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('Failed to get AI response');
    }
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: _user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    _addMessage(textMessage);
    setState(() {
      _isTyping = true;
    });

    try {
      final response = await _getAIResponse(message.text);
      final therapistMessage = types.TextMessage(
        author: _therapist,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: const Uuid().v4(),
        text: response,
      );

      _addMessage(therapistMessage);
    } catch (e) {
      _addMessage(
        types.TextMessage(
          author: _therapist,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          id: const Uuid().v4(),
          text: 'I apologize, but I encountered an error. Please try again.',
        ),
      );
    }

    setState(() {
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('AI Therapist'),
      ),
      body: Chat(
        messages: _messages,
        onSendPressed: _handleSendPressed,
        showUserAvatars: true,
        showUserNames: true,
        user: _user,
        theme: const DefaultChatTheme(
          backgroundColor: Colors.black,
          primaryColor: Colors.blue,
          secondaryColor: Colors.grey,
          inputBackgroundColor: Colors.white10,
          inputTextColor: Colors.white,
          sentMessageBodyTextStyle: TextStyle(color: Colors.white),
          receivedMessageBodyTextStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
