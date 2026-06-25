import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ============================================================
//  GEMINI AI SERVICE
//  Handles all communication with Google Gemini API.
//  Uses gemini-1.5-flash (FREE — 1 million tokens/day limit).
//  Supports: text chat, streaming responses, PDF/image input.
// ============================================================

class GeminiService {
  // ⚠️  PUT YOUR GEMINI API KEY HERE
  // Get free key at: https://aistudio.google.com/app/apikey
  static const String _apiKey = 'AIzaSyBnaJgl21XZfCNZCMuZKNzXm8YqJ5u7xxU';

  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';

  // Use flash for speed and free tier; switch to pro for harder tasks
  static const String _model = 'gemini-1.5-flash';

  // ----------------------------------------------------------
  //  SEND MESSAGE — returns complete response string
  //  Use this for short responses (resume, MCQs, explanations)
  // ----------------------------------------------------------
  static Future<String> sendMessage({
    required String systemPrompt,
    required List<Map<String, dynamic>> conversationHistory,
    required String userMessage,
    String? pdfText, // extracted text from uploaded PDF
  }) async {
    // Build the contents array — Gemini uses user/model roles
    final List<Map<String, dynamic>> contents = [];

    // Add conversation history
    for (final msg in conversationHistory) {
      contents.add({
        'role': msg['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': msg['content']},
        ],
      });
    }

    // Add current user message (with PDF context if provided)
    String finalUserMessage = userMessage;
    if (pdfText != null && pdfText.isNotEmpty) {
      finalUserMessage =
          'Here is the content from my uploaded document:\n\n"""\n$pdfText\n"""\n\nMy question: $userMessage';
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': finalUserMessage},
      ],
    });

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7, // 0 = factual/deterministic, 1 = creative
        'topP': 0.95,
        'maxOutputTokens': 4096, // ~3000 words max response
        'responseMimeType': 'text/plain',
      },
      'safetySettings': [
        // Allow all educational content
        {'category': 'HARM_CATEGORY_HARASSMENT', 'threshold': 'BLOCK_ONLY_HIGH'},
        {'category': 'HARM_CATEGORY_HATE_SPEECH', 'threshold': 'BLOCK_ONLY_HIGH'},
        {'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT', 'threshold': 'BLOCK_ONLY_HIGH'},
        {'category': 'HARM_CATEGORY_DANGEROUS_CONTENT', 'threshold': 'BLOCK_ONLY_HIGH'},
      ],
    };

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text =
            data['candidates'][0]['content']['parts'][0]['text'] as String;
        return text;
      } else if (response.statusCode == 429) {
        // Rate limit hit — tell user nicely
        return 'I am getting too many requests right now. Please wait 30 seconds and try again.';
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Gemini API error: ${error['error']['message']}');
      }
    } on SocketException {
      return 'No internet connection. Please check your network and try again.';
    } catch (e) {
      return 'Sorry, something went wrong: ${e.toString()}. Please try again.';
    }
  }

  // ----------------------------------------------------------
  //  STREAM MESSAGE — returns response word-by-word (like ChatGPT)
  //  Use this for chat screen for a better user experience
  // ----------------------------------------------------------
  static Stream<String> streamMessage({
    required String systemPrompt,
    required List<Map<String, dynamic>> conversationHistory,
    required String userMessage,
    String? pdfText,
  }) async* {
    final List<Map<String, dynamic>> contents = [];

    for (final msg in conversationHistory) {
      contents.add({
        'role': msg['role'] == 'assistant' ? 'model' : 'user',
        'parts': [
          {'text': msg['content']},
        ],
      });
    }

    String finalUserMessage = userMessage;
    if (pdfText != null && pdfText.isNotEmpty) {
      finalUserMessage =
          'Document content:\n"""\n$pdfText\n"""\n\nQuestion: $userMessage';
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': finalUserMessage},
      ],
    });

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': contents,
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 4096,
      },
    };

    try {
      final request = http.Request(
        'POST',
        Uri.parse('$_baseUrl/$_model:streamGenerateContent?alt=sse&key=$_apiKey'),
      );
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(requestBody);

      final streamedResponse = await http.Client().send(request);

      await for (final chunk in streamedResponse.stream.transform(utf8.decoder)) {
        // Each SSE chunk starts with "data: "
        for (final line in chunk.split('\n')) {
          if (line.startsWith('data: ') && line.length > 6) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr == '[DONE]') return;
            try {
              final data = jsonDecode(jsonStr);
              final text = data['candidates']?[0]?['content']?['parts']?[0]
                  ?['text'] as String?;
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            } catch (_) {
              // Skip malformed chunks
            }
          }
        }
      }
    } on SocketException {
      yield '\n\n[No internet connection]';
    } catch (e) {
      yield '\n\n[Error: $e]';
    }
  }

  // ----------------------------------------------------------
  //  GENERATE MCQs — specialized for study mode
  // ----------------------------------------------------------
  static Future<List<MCQQuestion>> generateMCQs({
    required String topic,
    required String content,
    int count = 5,
    String difficulty = 'mixed',
  }) async {
    final prompt = SystemPrompts.studyMode(subject: topic);
    final question =
        '''Generate exactly $count multiple choice questions about: "$topic"
        
Based on this content (if provided): "$content"

IMPORTANT: Respond ONLY in this exact JSON format, no other text:
{
  "questions": [
    {
      "question": "Question text here?",
      "options": ["A) Option 1", "B) Option 2", "C) Option 3", "D) Option 4"],
      "correct": "A",
      "explanation": "Brief explanation why A is correct"
    }
  ]
}''';

    final rawResponse = await sendMessage(
      systemPrompt: prompt,
      conversationHistory: [],
      userMessage: question,
    );

    try {
      // Extract JSON from response
      final jsonMatch =
          RegExp(r'\{[\s\S]*\}').firstMatch(rawResponse)?.group(0);
      if (jsonMatch == null) return [];

      final data = jsonDecode(jsonMatch);
      final questionsList = data['questions'] as List;

      return questionsList
          .map(
            (q) => MCQQuestion(
              question: q['question'],
              options: List<String>.from(q['options']),
              correctAnswer: q['correct'],
              explanation: q['explanation'],
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ----------------------------------------------------------
  //  GENERATE RESUME BULLETS — for career mode
  // ----------------------------------------------------------
  static Future<List<String>> generateResumeBullets({
    required String role,
    required String task,
    required String context,
  }) async {
    final response = await sendMessage(
      systemPrompt: SystemPrompts.careerMode(targetRole: role),
      conversationHistory: [],
      userMessage:
          '''Write 4 strong resume bullet points for a "$role" who did this:
          
Task/Project: $task
Context: $context

Rules:
- Start each with a strong action verb
- Include measurable impact where possible
- Keep each under 15 words
- Make them ATS-friendly

Respond ONLY with a JSON array of strings: ["bullet1", "bullet2", "bullet3", "bullet4"]''',
    );

    try {
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(response)?.group(0);
      if (jsonMatch == null) return [];
      return List<String>.from(jsonDecode(jsonMatch));
    } catch (_) {
      return [];
    }
  }
}

// ----------------------------------------------------------
//  DATA MODELS
// ----------------------------------------------------------

class MCQQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  String? userAnswer;

  MCQQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.userAnswer,
  });

  bool get isAnswered => userAnswer != null;
  bool get isCorrect => userAnswer == correctAnswer;
}

// Import this where needed
// ignore: non_constant_identifier_names
SystemPrompts get SystemPrompts => _SystemPrompts();
class _SystemPrompts {
  // This is a workaround — directly use SystemPrompts class above
}
