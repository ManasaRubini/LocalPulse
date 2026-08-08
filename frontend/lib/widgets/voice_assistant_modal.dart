import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/voice_service.dart';
import '../utils/app_colors.dart';
import 'emergency_sos_sheet.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String? actionType;
  final String? payload;
  final String? engine;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.actionType,
    this.payload,
    this.engine,
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
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool isListening = false;
  bool isThinking = false;
  bool speechAvailable = false;
  bool showHistoryView = false;
  List<ChatHistoryItem> _savedHistoryList = [];

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Vanakkam! I'm PulseAI, powered by Google Gemini 1.5 Flash ✨\n\nAsk me anything about active civic reports, road repairs, hospital availability, or chat freely in Tanglish & English!",
      isUser: false,
      payload: "welcome",
      engine: "Google Gemini 1.5 Flash ✨",
    ),
  ];

  List<String> dynamicSuggestions = [
    "📊 What issues are in the app?",
    "🏥 Hospital la ethavathu prachanaya?",
    "💧 Thanni leak aagudhu",
    "🚧 Road la pallam irukku",
    "🏆 Who has the highest karma?",
    "🚨 Emergency SOS"
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _initSpeech();
    _loadChatHistory();
  }

  Future<void> _loadChatHistory() async {
    final list = await PulseAIService.loadHistory();
    if (mounted) {
      setState(() => _savedHistoryList = list);
    }
  }

  Future<void> _initSpeech() async {
    try {
      speechAvailable = await _speech.initialize(
        onError: (err) => setState(() => isListening = false),
        onStatus: (status) {
          if (status == "done" || status == "notListening") {
            if (mounted && isListening) {
              setState(() => isListening = false);
              if (_queryController.text.trim().isNotEmpty) {
                _handleQuery(_queryController.text);
              }
            }
          }
        },
      );
    } catch (_) {
      speechAvailable = false;
    }
  }

  @override
  void dispose() {
    _speech.stop();
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

  Future<void> _toggleListening() async {
    if (isListening) {
      await _speech.stop();
      setState(() => isListening = false);
      if (_queryController.text.trim().isNotEmpty) {
        _handleQuery(_queryController.text);
      }
    } else {
      if (!speechAvailable) {
        speechAvailable = await _speech.initialize();
      }

      if (speechAvailable) {
        setState(() {
          isListening = true;
          _queryController.clear();
        });

        _speech.listen(
          onResult: (result) {
            setState(() {
              _queryController.text = result.recognizedWords;
            });
          },
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Microphone ready! Type or speak your question freely."),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleQuery(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    _queryController.clear();

    if (isListening) {
      _speech.stop();
      isListening = false;
    }

    if (showHistoryView) {
      setState(() => showHistoryView = false);
    }

    final List<Map<String, String>> historyPayload = _messages.map((m) {
      return {
        "role": m.isUser ? "user" : "assistant",
        "text": m.text,
      };
    }).toList();

    setState(() {
      _messages.add(ChatMessage(text: clean, isUser: true));
      isThinking = true;
    });
    _scrollToBottom();

    try {
      final res = await PulseAIService.processQueryAsync(
        clean,
        history: historyPayload,
      );

      if (!mounted) return;

      setState(() {
        isThinking = false;
        _messages.add(ChatMessage(
          text: res.text,
          isUser: false,
          actionType: res.actionType,
          payload: res.payload,
          engine: res.engine ?? "Google Gemini 1.5 Flash ✨",
        ));
        if (res.followUpSuggestions != null && res.followUpSuggestions!.isNotEmpty) {
          dynamicSuggestions = res.followUpSuggestions!;
        }
      });
      _scrollToBottom();
      _loadChatHistory();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        isThinking = false;
        _messages.add(ChatMessage(
          text: "Vanakkam! Unga query purinjikitten. Water leaks, hospital pins, road repairs, illana emergency help thevaiya thalaiva?",
          isUser: false,
          engine: "Google Gemini 1.5 Flash ✨",
        ));
      });
      _scrollToBottom();
    }
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
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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

          // Header with Live Waveform Mic + Gemini Badge + History Toggle
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PulseAI Assistant",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                    ),
                    Text(
                      isListening ? "Listening to your voice..." : "Conversational civic companion in Coimbatore",
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isListening ? AppColors.alert : AppColors.textSecondary,
                        fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              // Chat History Toggle Button
              IconButton(
                tooltip: "Chat History",
                icon: Icon(
                  showHistoryView ? Icons.chat_rounded : Icons.history_rounded,
                  color: showHistoryView ? AppColors.primary : AppColors.textSecondary,
                ),
                onPressed: () {
                  setState(() => showHistoryView = !showHistoryView);
                  _loadChatHistory();
                },
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Main View: History List OR Active Chat
          Expanded(
            child: showHistoryView ? _buildHistoryView() : _buildChatView(),
          ),

          if (!showHistoryView) ...[
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
                      final cleanQuery = prompt.replaceAll(RegExp(r'[^\w\s\?]'), '').trim();
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
                      hintText: isListening ? "Listening... speak now" : "Ask Gemini anything (e.g. 'hospital la ethavathu prachanaya')...",
                      hintStyle: TextStyle(
                        color: isListening ? AppColors.alert : AppColors.textMuted,
                        fontSize: 13,
                      ),
                      filled: true,
                      fillColor: isListening ? AppColors.alertLight.withValues(alpha: 0.3) : AppColors.background,
                      prefixIcon: Icon(
                        isListening ? Icons.mic_rounded : Icons.chat_bubble_outline_rounded,
                        color: isListening ? AppColors.alert : AppColors.primary,
                        size: 20,
                      ),
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
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return ListView.builder(
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
                  Text("Google Gemini is thinking...", style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          );
        }

        final msg = _messages[index];
        return _buildChatBubble(msg);
      },
    );
  }

  Widget _buildHistoryView() {
    if (_savedHistoryList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text("No chat history yet!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            const Text("Ask questions to Gemini to build your conversational history.", style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                "Saved Conversations (${_savedHistoryList.length})",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () async {
                  await PulseAIService.clearHistory();
                  setState(() => _savedHistoryList = []);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Chat history cleared")),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppColors.alert),
                label: const Text("Clear All", style: TextStyle(color: AppColors.alert, fontSize: 12)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            itemCount: _savedHistoryList.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = _savedHistoryList[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                leading: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceSecondary,
                  child: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.primary),
                ),
                title: Text(
                  item.query,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  item.reply,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
                onTap: () {
                  setState(() {
                    showHistoryView = false;
                  });
                  _handleQuery(item.query);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
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
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.88),
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
            if (msg.engine != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome_rounded, size: 12, color: Color(0xFF9B51E0)),
                  const SizedBox(width: 4),
                  Text(
                    msg.engine!,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF9B51E0)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              msg.text,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.8, height: 1.42),
            ),
            if (msg.actionType != null) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _executeAction(msg.actionType!, msg.payload),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(
                  _getActionLabel(msg.actionType!),
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
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
        return "Open Emergency SOS Speed-Dial";
      case "open_explore":
        return "View Locations on Explore Map";
      case "filter_category":
        return "Filter Feed Issues";
      case "open_events":
        return "Open Community Drives";
      case "open_report":
        return "Submit New Report Form";
      default:
        return "View Details";
    }
  }
}
