import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'gemini_service.dart';

class AIService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GeminiService _geminiService = GeminiService();

  /// Refusal string for off-topic queries
  static const String offTopicRefusal = 
      "I'm FinSense AI. I specialize in helping you manage your finances.";

  /// Legacy non-streaming request fallback
  Future<String> queryFinancialAssistant({
    required String uid,
    required String prompt,
    required String financialSummary,
    required List<Map<String, String>> history,
  }) async {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw Exception("User message cannot be empty.");
    }

    _verifyOffTopicAndInjection(cleanPrompt);
    await _checkRateLimits(uid);

    List<Map<String, String>> activeHistory = List.from(history);
    if (activeHistory.length > 8) {
      activeHistory = await _compressHistory(activeHistory);
    }

    final goalsSummary = await _fetchGoalsFromFirestore(uid);
    final enrichedSummary = "$financialSummary\n\n[FINANCIAL GOALS]\n$goalsSummary";

    try {
      final responseText = await _geminiService.queryGeminiDirectly(
        prompt: cleanPrompt,
        financialSummary: enrichedSummary,
        history: activeHistory,
      );

      await _incrementRateLimitCount(uid);
      return responseText;
    } catch (e) {
      debugPrint("[AI SERVICE] EXCEPTION - Gemini direct query failed: $e");
      rethrow;
    }
  }

  /// Streams Gemini responses chunk-by-chunk
  Stream<String> queryFinancialAssistantStream({
    required String uid,
    required String prompt,
    required String financialSummary,
    required List<Map<String, String>> history,
  }) async* {
    final cleanPrompt = prompt.trim();
    if (cleanPrompt.isEmpty) {
      throw Exception("User message cannot be empty.");
    }

    _verifyOffTopicAndInjection(cleanPrompt);
    await _checkRateLimits(uid);

    List<Map<String, String>> activeHistory = List.from(history);
    if (activeHistory.length > 8) {
      activeHistory = await _compressHistory(activeHistory);
    }

    final goalsSummary = await _fetchGoalsFromFirestore(uid);
    final enrichedSummary = "$financialSummary\n\n[FINANCIAL GOALS]\n$goalsSummary";

    try {
      await for (final chunk in _geminiService.queryGeminiStream(
        prompt: cleanPrompt,
        financialSummary: enrichedSummary,
        history: activeHistory,
      )) {
        yield chunk;
      }

      await _incrementRateLimitCount(uid);
    } catch (e) {
      debugPrint("[AI SERVICE] EXCEPTION - Gemini stream query failed: $e");
      rethrow;
    }
  }

  void _verifyOffTopicAndInjection(String cleanPrompt) {
    final lowerPrompt = cleanPrompt.toLowerCase();
    
    final injectionIndicators = [
      "system prompt", "api key", "secret key", "hidden instruction",
      "backend implementation", "ignore previous instructions", "override constraints",
      "developer instructions", "you must ignore"
    ];

    if (injectionIndicators.any((indicator) => lowerPrompt.contains(indicator))) {
      debugPrint("[AUTH AUDIT] Blocked prompt injection signature: '$cleanPrompt'");
      throw Exception(offTopicRefusal);
    }

    final offTopicKeywords = [
      "programming", "coding", "javascript", "python", "html", "css", "java", "rust",
      "movie", "film", "cinema", "actor", "director", "hollywood", "bollywood",
      "politics", "election", "president", "government",
      "cricket", "football", "soccer", "sports", "match", "score",
      "geography", "capital of", "population of"
    ];

    if (offTopicKeywords.any((keyword) => lowerPrompt.contains(keyword))) {
      debugPrint("[AUTH AUDIT] Blocked off-topic query locally: '$cleanPrompt'");
      throw Exception(offTopicRefusal);
    }
  }

  Future<String> _fetchGoalsFromFirestore(String uid) async {
    if (uid.isEmpty) return "No active financial goals registered.";
    
    try {
      // 1. Try user subcollection
      final goalsSnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .get();
      
      if (goalsSnapshot.docs.isNotEmpty) {
        return goalsSnapshot.docs.map((doc) {
          final data = doc.data();
          final title = data['title'] ?? 'Goal';
          final target = (data['targetAmount'] ?? 0.0).toString();
          final current = (data['currentAmount'] ?? 0.0).toString();
          final deadline = data['deadline'] ?? 'No deadline';
          return '- $title: Target $target, Saved $current, Deadline: $deadline';
        }).join('\n');
      }
      
      // 2. Try top-level goals collection with filter
      final topGoalsSnapshot = await _firestore
          .collection('goals')
          .where('userId', isEqualTo: uid)
          .get();
      
      if (topGoalsSnapshot.docs.isNotEmpty) {
        return topGoalsSnapshot.docs.map((doc) {
          final data = doc.data();
          final title = data['title'] ?? 'Goal';
          final target = (data['targetAmount'] ?? 0.0).toString();
          final current = (data['currentAmount'] ?? 0.0).toString();
          final deadline = data['deadline'] ?? 'No deadline';
          return '- $title: Target $target, Saved $current, Deadline: $deadline';
        }).join('\n');
      }
    } catch (e) {
      debugPrint("[AI SERVICE] Failed to fetch goals from Firestore: $e");
    }
    
    return "No active financial goals registered.";
  }

  Future<void> _checkRateLimits(String uid) async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final metadataDocRef = _firestore.collection('chatHistory').doc(uid);

    int currentCount = 0;
    String lastRequestDate = "";

    try {
      final docSnapshot = await metadataDocRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          currentCount = data['aiRequestCount'] ?? 0;
          lastRequestDate = data['lastAiRequestDate'] ?? "";
        }
      }
    } catch (e) {
      debugPrint("[AUTH AUDIT] Error fetching rate limit metadata: $e");
    }

    if (lastRequestDate != todayStr) {
      currentCount = 0;
    }

    if (currentCount >= 20) {
      throw Exception("Daily limit of 20 AI assistant queries reached. Please try again tomorrow.");
    }
  }

  Future<void> _incrementRateLimitCount(String uid) async {
    final now = DateTime.now();
    final todayStr = "${now.year}-${now.month}-${now.day}";
    final metadataDocRef = _firestore.collection('chatHistory').doc(uid);

    int currentCount = 0;
    String lastRequestDate = "";

    try {
      final docSnapshot = await metadataDocRef.get();
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          currentCount = data['aiRequestCount'] ?? 0;
          lastRequestDate = data['lastAiRequestDate'] ?? "";
        }
      }
    } catch (_) {}

    if (lastRequestDate != todayStr) {
      currentCount = 0;
    }

    try {
      await metadataDocRef.set({
        'aiRequestCount': currentCount + 1,
        'lastAiRequestDate': todayStr,
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<List<Map<String, String>>> _compressHistory(List<Map<String, String>> history) async {
    final toSummarize = history.sublist(0, history.length - 4);
    final keepRecent = history.sublist(history.length - 4);
    
    try {
      debugPrint("[AI SERVICE] History length exceeds limits. Summarizing older conversations...");
      final summary = await _geminiService.summarizeHistory(toSummarize);
      return [
        {
          'role': 'user',
          'text': '[Summary of previous conversation context: $summary]'
        },
        ...keepRecent
      ];
    } catch (e) {
      debugPrint("[AI SERVICE] Failed to summarize previous history context: $e");
      return keepRecent; // Fallback to simple truncation
    }
  }
}
