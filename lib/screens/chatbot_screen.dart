import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/groq_service.dart';
import '../services/transaction_service.dart';
import '../models/transaction_model.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final GroqService _groq = GroqService();
  final TransactionService _txnService = TransactionService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoadingContext = true;
  bool _isSending = false;
  String? _contextError;
  String _userFirstName = 'there';
  String _selectedModel = GroqService.defaultModel;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isLoadingContext = true;
      _contextError = null;
    });
    try {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user == null) {
        throw Exception('You must be signed in to use the assistant.');
      }
      // Validate context loads, but discard — we'll always fetch fresh on send.
      await _fetchContext(user.id, user.name);

      if (!mounted) return;
      setState(() {
        _userFirstName = user.name.isNotEmpty ? user.name.split(' ').first : 'there';
        _messages
          ..clear()
          ..add(ChatMessage(
            text: "Hi $_userFirstName! I'm Fin, your finance assistant. "
                "Ask me about your spending, budget, or where you can save.",
            isUser: false,
          ));
        _isLoadingContext = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contextError = e.toString();
        _isLoadingContext = false;
      });
    }
  }

  Future<String> _fetchContext(String userId, String userName) async {
    final month = DateFormat('yyyy-MM').format(DateTime.now());
    final transactions = await _txnService.getTransactions(userId);
    final analytics = await _txnService.getAnalytics(userId, month);
    return _buildContext(userName, month, transactions, analytics);
  }

  String _buildContext(
    String name,
    String month,
    List<Transaction> transactions,
    Map<String, dynamic> analytics,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('User name: $name');
    buffer.writeln('Current month: $month');
    buffer.writeln(
        'Total income this month: \$${(analytics['totalIncome'] as num).toStringAsFixed(2)}');
    buffer.writeln(
        'Total expense this month: \$${(analytics['totalExpense'] as num).toStringAsFixed(2)}');
    buffer.writeln(
        'Balance this month: \$${(analytics['balance'] as num).toStringAsFixed(2)}');
    final budgetLimit = (analytics['budgetLimit'] as num).toDouble();
    if (budgetLimit > 0) {
      buffer.writeln(
          'Monthly budget limit: \$${budgetLimit.toStringAsFixed(2)}');
      buffer.writeln(
          'Budget used: ${(analytics['budgetPercentage'] as num).toStringAsFixed(1)}%');
    } else {
      buffer.writeln('Monthly budget limit: not set');
    }

    final categories =
        Map<String, double>.from(analytics['categoryBreakdown'] ?? {});
    if (categories.isNotEmpty) {
      final sorted = categories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      buffer.writeln('Spending by category this month:');
      for (final e in sorted) {
        buffer.writeln('  - ${e.key}: \$${e.value.toStringAsFixed(2)}');
      }
    }

    final recent = transactions.take(25).toList();
    if (recent.isNotEmpty) {
      buffer.writeln('Recent transactions (most recent first):');
      for (final t in recent) {
        final sign = t.type == TransactionType.income ? '+' : '-';
        buffer.writeln(
            '  - ${DateFormat('yyyy-MM-dd').format(t.date)} | ${t.title} | ${t.category} | $sign\$${t.amount.toStringAsFixed(2)}');
      }
    } else {
      buffer.writeln('No transactions recorded yet.');
    }

    return buffer.toString();
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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) return;

    // History sent to Gemini = prior turns, trimmed so it starts with a user turn.
    final history = List<ChatMessage>.from(_messages);
    while (history.isNotEmpty && !history.first.isUser) {
      history.removeAt(0);
    }

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isSending = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      // Always send the latest snapshot so Fin sees freshly added transactions.
      final freshContext = await _fetchContext(user.id, user.name);
      final reply = await _groq.sendMessage(
        financialContext: freshContext,
        history: history,
        message: text,
        modelName: _selectedModel,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: reply, isUser: false));
        _isSending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          isUser: false,
        ));
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Model',
            enabled: !_isSending,
            initialValue: _selectedModel,
            onSelected: (value) => setState(() => _selectedModel = value),
            itemBuilder: (context) => [
              for (final m in GroqService.availableModels)
                PopupMenuItem<String>(
                  value: m.id,
                  child: Row(
                    children: [
                      Icon(
                        m.id == _selectedModel
                            ? Icons.check
                            : Icons.check_box_outline_blank,
                        size: 18,
                        color: m.id == _selectedModel
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                      ),
                      const SizedBox(width: 8),
                      Text(m.label),
                    ],
                  ),
                ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    GroqService.availableModels
                        .firstWhere((m) => m.id == _selectedModel)
                        .label,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Reset chat',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoadingContext || _isSending ? null : _initialize,
          ),
        ],
      ),
      body: _isLoadingContext
          ? const Center(child: CircularProgressIndicator())
          : _contextError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Could not load your data: $_contextError',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _initialize,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_isSending ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _messages.length) {
                            return _buildTypingIndicator(theme);
                          }
                          return _buildBubble(theme, _messages[index]);
                        },
                      ),
                    ),
                    _buildInputBar(theme),
                  ],
                ),
    );
  }

  Widget _buildBubble(ThemeData theme, ChatMessage message) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        decoration: BoxDecoration(
          color:
              isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: isUser ? Colors.white : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildInputBar(ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                  hintText: 'Ask about your finances...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton(
              onPressed: _isSending ? null : _send,
              mini: true,
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
