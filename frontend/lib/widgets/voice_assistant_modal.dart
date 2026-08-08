import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../utils/app_colors.dart';
import 'emergency_sos_sheet.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? actionType;
  final String? payload;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.actionType,
    this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class VoiceAssistantModal extends StatefulWidget {
  final Function(String category)? onFilterCategory;
  final Function(int tabIndex, {String? subType})? onNavigateTab;

  const VoiceAssistantModal({
    super.key,
    this.onFilterCategory,
    this.onNavigateTab,
  });

  static void show(
    BuildContext context, {
    Function(String category)? onFilterCategory,
    Function(int tabIndex, {String? subType})? onNavigateTab,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceAssistantModal(
        onFilterCategory: onFilterCategory,
        onNavigateTab: onNavigateTab,
      ),
    );
  }

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool isListening = false;
  bool isThinking = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Vanakkam! I'm PulseAI, your friendly civic companion. 🤖✨\n\nI can help you report road potholes, check water leaks, locate nearby hospitals, or find community drives. How's your neighborhood today?",
      isUser: false,
      payload: "welcome",
    ),
  ];

  List<String> dynamicSuggestions = [
    "💧 Show water leaks",
    "🏥 Nearest hospital",
    "🚨 Emergency SOS",
    "🚧 Report road damage",
    "🌳 Tree plantation events",
    "🏆 How does karma work?"
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleListening() {
    if (isListening) {
      setState(() => isListening = false);
      if (_queryController.text.trim().isNotEmpty) {
        _handleQuery(_queryController.text);
      }
    } else {
      setState(() {
        isListening = true;
      });

      // Interactive auto-listen simulate
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (!mounted || !isListening) return;
        setState(() => isListening = false);
        if (_queryController.text.trim().isEmpty) {
          _queryController.text = "Show water leaks near RS Puram";
        }
        _handleQuery(_queryController.text);
      });
    }
  }

  void _handleQuery(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return;
    _queryController.clear();

    setState(() {
      _messages.add(ChatMessage(text: clean, isUser: true));
      isThinking = true;
      isListening = false;
    });
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 600), () {
      final res = PulseAIService.processQuery(clean);
      if (!mounted) return;

      setState(() {
        isThinking = false;
        _messages.add(ChatMessage(
          text: res.text,
          isUser: false,
          actionType: res.actionType,
          payload: res.payload,
        ));
        if (res.followUpSuggestions != null && res.followUpSuggestions!.isNotEmpty) {
          dynamicSuggestions = res.followUpSuggestions!;
        }
      });
      _scrollToBottom();

      // Trigger automatic navigation if query is a direct intent
      if (res.actionType != null) {
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (!mounted) return;
          _executeAction(res.actionType!, res.payload);
        });
      }
    });
  }

  void _executeAction(String actionType, String? payload) {
    Navigator.pop(context);
    if (actionType == "open_emergency") {
      EmergencySOSSheet.show(context);
    } else if (actionType == "open_explore") {
      widget.onNavigateTab?.call(1, subType: payload);
    } else if (actionType == "filter_category" && payload != null) {
      widget.onFilterCategory?.call(payload);
    } else if (actionType == "open_events") {
      widget.onNavigateTab?.call(3);
    } else if (actionType == "open_report") {
      widget.onNavigateTab?.call(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 12),

          // Header with Live Waveform Mic
          Row(
            children: [
              GestureDetector(
                onTap: _toggleListening,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final double scale = isListening ? 1.0 + (_pulseController.value * 0.18) : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isListening ? AppColors.alertGradient : AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: (isListening ? AppColors.alert : AppColors.primary).withValues(alpha: 0.4),
                              blurRadius: isListening ? 16 : 8,
                            ),
                          ],
                        ),
                        child: Icon(
                          isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "PulseAI Civic Buddy",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary),
                  ),
                  Text(
                    isListening ? "Listening to your voice..." : "Friendly civic assistant & neighborhood guide",
                    style: TextStyle(
                      fontSize: 12,
                      color: isListening ? AppColors.alert : AppColors.textSecondary,
                      fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Chat Messages History
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length + (isThinking ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && isThinking) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                          SizedBox(width: 10),
                          Text("PulseAI is thinking...", style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  );
                }

                final msg = _messages[index];
                return _buildChatBubble(msg);
              },
            ),
          ),

          // Dynamic Suggestions Carousel
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: dynamicSuggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = dynamicSuggestions[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.surfaceSecondary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    final cleanQuery = prompt.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                    _handleQuery(cleanQuery);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Query Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  onSubmitted: _handleQuery,
                  decoration: InputDecoration(
                    hintText: "Ask anything (e.g. 'Show water leaks', 'Nearest hospital')...",
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.background,
                    prefixIcon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  onPressed: () => _handleQuery(_queryController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
            boxShadow: AppColors.softShadow,
          ),
          child: Text(
            msg.text,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.35),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.8, height: 1.42),
            ),
            if (msg.actionType != null) ...[
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _executeAction(msg.actionType!, msg.payload),
                icon: const Icon(Icons.touch_app_rounded, size: 16),
                label: Text(
                  _getActionLabel(msg.actionType!),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getActionLabel(String actionType) {
    switch (actionType) {
      case "open_emergency":
        return "Open Emergency SOS";
      case "open_explore":
        return "View on Explore Map";
      case "filter_category":
        return "Filter Feed Issues";
      case "open_events":
        return "Go to Community Drives";
      case "open_report":
        return "Submit New Report";
      default:
        return "View Details";
    }
  }
}
