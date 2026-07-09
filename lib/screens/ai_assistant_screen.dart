import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_controller.dart';
import '../providers/finance_provider.dart';
import '../models/chat_message.dart';
import '../utils/formatters.dart';
import '../core/theme.dart';
import '../widgets/ai_avatar_widget.dart';
import '../providers/ai_avatar_controller.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _suggestedPrompts = [
    "Where did I spend most?",
    "Can I afford this purchase?",
    "Give me saving tips.",
    "Analyze my expenses.",
    "How much did I spend on food?",
    "Create a monthly budget.",
    "Explain SIP.",
    "Explain ETF.",
    "Give investment education."
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(aiAvatarControllerProvider.notifier).syncWithFinanceState(
              isThinking: ref.read(chatControllerProvider).isTyping,
              finance: ref.read(financeProvider),
            );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSendMessage(
    String text,
    ChatController controller,
    FinanceProvider financeProvider,
  ) async {
    if (text.trim().isEmpty) return;
    _messageController.clear();
    
    await controller.sendMessage(text, financeProvider);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chat = ref.watch(chatControllerProvider);
    final chatNotifier = ref.read(chatControllerProvider.notifier);
    final finance = ref.watch(financeProvider);

    // Listen to changes in chat typing status to update the avatar animation
    ref.listen(chatControllerProvider, (previous, next) {
      if (previous?.isTyping != next.isTyping) {
        ref.read(aiAvatarControllerProvider.notifier).syncWithFinanceState(
              isThinking: next.isTyping,
              finance: ref.read(financeProvider),
            );
      }
    });

    // Listen to changes in finance status to update the avatar animation
    ref.listen(financeProvider, (previous, next) {
      ref.read(aiAvatarControllerProvider.notifier).syncWithFinanceState(
            isThinking: ref.read(chatControllerProvider).isTyping,
            finance: next,
          );
    });

    // Trigger auto-scroll on view update
    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Budget Diagnostic', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  Text(
                    'Daily Limit: ${chat.aiRequestCount}/20 queries',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: chat.aiRequestCount >= 20 ? AppTheme.accentOrange : AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => chatNotifier.clearHistory(),
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Clear Conversation Logs',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Error Message Banner if a query failed
            if (chat.errorMessage != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.3), width: 1.0),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        chat.errorMessage!,
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 14),
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        chatNotifier.clearError();
                      },
                    ),
                  ],
                ),
              ),

            // 3D Avatar character at the top of the assistant view!
            const AIAvatarWidget(),

            // 1. Messages thread
            Expanded(
              child: chat.messages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation with FinSense AI.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        return _buildChatBubble(chat.messages[index], theme);
                      },
                    ),
            ),

            // 2. Typing status banner
            if (chat.isTyping)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'AI is running database queries...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Quick Suggestion Chips (only when keyboard is closed)
            Container(
              height: 44,
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _suggestedPrompts.length,
                itemBuilder: (context, index) {
                  final prompt = _suggestedPrompts[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ActionChip(
                      label: Text(prompt),
                      labelStyle: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: theme.brightness == Brightness.dark ? AppTheme.darkCardBg : AppTheme.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: theme.brightness == Brightness.dark ? Colors.white10 : AppTheme.borderLight, width: 1.0),
                      onPressed: chat.isTyping
                          ? null
                          : () {
                              _handleSendMessage(prompt, chatNotifier, finance);
                            },
                    ),
                  );
                },
              ),
            ),

            // 4. Input Row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textInputAction: TextInputAction.send,
                      readOnly: chat.isTyping,
                      onSubmitted: chat.isTyping
                          ? null
                          : (val) => _handleSendMessage(val, chatNotifier, finance),
                      decoration: const InputDecoration(
                        hintText: 'Ask FinSense AI...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: chat.isTyping ? theme.disabledColor : theme.colorScheme.primary,
                    onPressed: chat.isTyping
                        ? null
                        : () {
                            _handleSendMessage(_messageController.text, chatNotifier, finance);
                          },
                    child: const Icon(Icons.send_rounded, size: 18),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bubble builder
  Widget _buildChatBubble(ChatMessage msg, ThemeData theme) {
    final isUser = msg.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColor = isUser
        ? theme.colorScheme.primary
        : (theme.brightness == Brightness.dark ? AppTheme.darkCardBg : AppTheme.cardBg);
    final textColor = isUser
        ? Colors.white
        : (theme.brightness == Brightness.dark ? AppTheme.darkText : AppTheme.textDark);
    
    return Container(
      alignment: alignment,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          border: isUser ? null : Border.all(color: theme.brightness == Brightness.dark ? Colors.white10 : AppTheme.borderLight, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUser) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: theme.colorScheme.primary, size: 12),
                  const SizedBox(width: 4),
                  const Text(
                    'FINSENSE AI',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (isUser)
              Text(
                msg.text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  height: 1.35,
                  fontSize: 13.5,
                ),
              )
            else
              MarkdownBody(
                data: msg.text,
                styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                  p: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    height: 1.35,
                    fontSize: 13.5,
                  ),
                  listBullet: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                  ),
                  strong: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                  em: theme.textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                Formatters.time(msg.timestamp),
                style: TextStyle(
                  fontSize: 8.5,
                  color: isUser ? Colors.white.withOpacity(0.6) : AppTheme.textMuted.withOpacity(0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
