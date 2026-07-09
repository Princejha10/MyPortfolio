import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/chat_message.dart';
import '../repositories/chat_repository.dart';
import '../services/ai_service.dart';
import '../services/financial_insight_service.dart';
import 'finance_provider.dart';
import 'auth_provider.dart';

// Providers for services
final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository());
final aiServiceProvider = Provider<AIService>((ref) => AIService());

/// Riverpod State Notifier Provider for AI Chat
final chatControllerProvider = StateNotifierProvider<ChatController, ChatState>((ref) {
  final auth = ref.watch(authStateChangesProvider).value;
  final repo = ref.watch(chatRepositoryProvider);
  final ai = ref.watch(aiServiceProvider);

  return ChatController(
    uid: auth?.uid ?? '',
    repository: repo,
    aiService: ai,
  );
});

/// Immutable Chat State Object
class ChatState {
  final List<ChatMessage> messages;
  final bool isTyping;
  final String? errorMessage;
  final int aiRequestCount;

  ChatState({
    required this.messages,
    required this.isTyping,
    this.errorMessage,
    this.aiRequestCount = 0,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isTyping,
    String? errorMessage,
    int? aiRequestCount,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isTyping: isTyping ?? this.isTyping,
      errorMessage: errorMessage, // Reset if not specified
      aiRequestCount: aiRequestCount ?? this.aiRequestCount,
    );
  }
}

class ChatController extends StateNotifier<ChatState> {
  final String _uid;
  final ChatRepository _repository;
  final AIService _aiService;
  StreamSubscription? _msgSubscription;
  StreamSubscription? _metaSubscription;
  
  // Track local messages in memory for instant responsiveness
  final List<ChatMessage> _localMessages = [];

  // Rate Limiting Variable
  DateTime _lastRequestTime = DateTime.fromMillisecondsSinceEpoch(0);

  ChatController({
    required String uid,
    required ChatRepository repository,
    required AIService aiService,
  })  : _uid = uid,
        _repository = repository,
        _aiService = aiService,
        super(ChatState(messages: [], isTyping: false)) {
    if (_uid.isNotEmpty) {
      _listenToMessages();
      _listenToRateLimit();
    }
  }

  void _listenToMessages() {
    if (Firebase.apps.isEmpty) {
      debugPrint("[INIT GUARD] Skipping messages stream listener: Firebase is uninitialized.");
      return;
    }
    _msgSubscription?.cancel();
    _msgSubscription = _repository.getMessagesStream(_uid).listen((msgs) {
      _localMessages.clear();
      _localMessages.addAll(msgs);
      state = state.copyWith(messages: List.from(_localMessages));
    }, onError: (e) {
      debugPrint("[AUTH AUDIT] Chat messages stream error: $e");
    });
  }

  void _listenToRateLimit() {
    if (Firebase.apps.isEmpty) {
      debugPrint("[INIT GUARD] Skipping metadata rate-limit listener: Firebase is uninitialized.");
      return;
    }
    _metaSubscription?.cancel();
    _metaSubscription = FirebaseFirestore.instance
        .collection('chatHistory')
        .doc(_uid)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        final data = snap.data();
        final now = DateTime.now();
        final todayStr = "${now.year}-${now.month}-${now.day}";
        final lastDate = data?['lastAiRequestDate'] as String? ?? "";
        final count = data?['aiRequestCount'] as int? ?? 0;
        
        if (lastDate == todayStr) {
          state = state.copyWith(aiRequestCount: count);
        } else {
          state = state.copyWith(aiRequestCount: 0);
        }
      } else {
        state = state.copyWith(aiRequestCount: 0);
      }
    }, onError: (e) {
      debugPrint("[AUTH AUDIT] Chat metadata stream error: $e");
    });
  }

  /// Sends a user query to the backend secure functions with retry capabilities.
  Future<void> sendMessage(String text, FinanceProvider finance) async {
    if (text.trim().isEmpty) return;
    if (state.isTyping) return; // Request locking: Prevent multiple calls while loading.

    // Rate Limiting Check: Maximum 1 request every 3 seconds
    final now = DateTime.now();
    final timeDiff = now.difference(_lastRequestTime);
    if (timeDiff < const Duration(seconds: 3)) {
      await Future.delayed(const Duration(seconds: 3) - timeDiff);
    }
    _lastRequestTime = DateTime.now();

    final msgId = "${DateTime.now().millisecondsSinceEpoch}_${100 + (DateTime.now().microsecond % 900)}";
    final userMsg = ChatMessage(
      id: msgId,
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    // 1. Immediately post the user message locally (displays instantly)
    _localMessages.add(userMsg);
    state = state.copyWith(
      messages: List.from(_localMessages),
      isTyping: true,
      errorMessage: null,
    );

    // Persist user message to firestore
    try {
      await _repository.addMessage(_uid, userMsg);
    } catch (e) {
      debugPrint("[AUTH AUDIT] ChatController failed to persist user message in Firestore: $e");
    }

    // 2. Prepare financial summary and context history records (exclude the new userMsg)
    final summary = FinancialInsightService.generateSummary(finance);
    final history = _localMessages.map((m) {
      return {
        'role': m.isUser ? 'user' : 'model',
        'text': m.text,
      };
    }).toList();

    if (history.isNotEmpty) {
      history.removeLast();
    }

    // 3. Create the placeholder AI response message
    final aiMsgId = "${DateTime.now().millisecondsSinceEpoch}_${100 + (DateTime.now().microsecond % 900)}";
    final aiMsg = ChatMessage(
      id: aiMsgId,
      text: '',
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    _localMessages.add(aiMsg);
    state = state.copyWith(messages: List.from(_localMessages));

    // 4. Consume the stream with exponential retries on failure (1s, 2s, 4s)
    int attempt = 0;
    const maxAttempts = 3;
    final retryDelays = [1, 2, 4];
    bool streamStarted = false;
    String fullResponseText = "";

    while (attempt <= maxAttempts) {
      try {
        final stream = _aiService.queryFinancialAssistantStream(
          uid: _uid,
          prompt: text,
          financialSummary: summary,
          history: history,
        );

        await for (final chunk in stream) {
          if (!streamStarted) {
            streamStarted = true;
          }
          fullResponseText += chunk;
          
          // Update the message text dynamically in the UI message list
          final index = _localMessages.indexWhere((m) => m.id == aiMsgId);
          if (index != -1) {
            _localMessages[index] = ChatMessage(
              id: aiMsgId,
              text: fullResponseText,
              isUser: false,
              timestamp: aiMsg.timestamp,
            );
            state = state.copyWith(messages: List.from(_localMessages));
          }
        }
        break; // Stream finished successfully
      } catch (e) {
        if (streamStarted) {
          // If the stream started successfully, don't restart from beginning on transient failures
          state = state.copyWith(
            isTyping: false,
            errorMessage: e.toString().replaceFirst("Exception: ", ""),
          );
          return;
        }

        final errorMsg = e.toString().toLowerCase();
        final isRetryable = errorMsg.contains("429") || 
                            errorMsg.contains("503") || 
                            errorMsg.contains("timeout") || 
                            errorMsg.contains("connection");
        
        attempt++;
        if (attempt > maxAttempts || !isRetryable) {
          String displayError = e.toString().replaceFirst("Exception: ", "");
          if (errorMsg.contains("429")) {
            displayError = "Gemini is temporarily busy.\nPlease wait a few seconds and try again.";
          }
          
          // Remove the empty AI message from the UI since it failed
          _localMessages.removeWhere((m) => m.id == aiMsgId);
          state = state.copyWith(
            messages: List.from(_localMessages),
            isTyping: false,
            errorMessage: displayError,
          );
          return;
        }
        
        // Wait before retrying (1s, 2s, 4s)
        await Future.delayed(Duration(seconds: retryDelays[attempt - 1]));
      }
    }

    // 5. Persist finalized AI reply to database
    if (fullResponseText.isNotEmpty) {
      final finalizedMsg = ChatMessage(
        id: aiMsgId,
        text: fullResponseText,
        isUser: false,
        timestamp: aiMsg.timestamp,
      );
      try {
        await _repository.addMessage(_uid, finalizedMsg);
      } catch (e) {
        debugPrint("[AUTH AUDIT] ChatController failed to persist finalized AI message in Firestore: $e");
      }
    }

    state = state.copyWith(isTyping: false);
  }

  /// Deletes all conversation logs
  Future<void> clearHistory() async {
    _localMessages.clear();
    state = state.copyWith(messages: []);
    try {
      await _repository.clearHistory(_uid);
    } catch (e) {
      debugPrint("[AUTH AUDIT] ChatController failed to clear Firestore history: $e");
    }
  }

  /// Clears any currently active local error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    _msgSubscription?.cancel();
    _metaSubscription?.cancel();
    super.dispose();
  }
}
