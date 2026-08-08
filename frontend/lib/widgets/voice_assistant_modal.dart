import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../utils/app_colors.dart';
import 'emergency_sos_sheet.dart';

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

  bool isListening = false;
  bool isThinking = false;
  String aiResponse = "Hi! I'm PulseAI, your voice civic assistant. Tap the mic or type any civic inquiry below.";

  final List<String> samplePrompts = [
    "💧 Show water leaks",
    "🏥 Nearest hospital",
    "🚨 Emergency SOS",
    "🚧 Report road damage",
    "🌳 Tree plantation events",
    "⚡ Street light outage"
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
    super.dispose();
  }

  void _toggleListening() {
    if (isListening) {
      setState(() {
        isListening = false;
      });
      if (_queryController.text.trim().isNotEmpty) {
        _handleQuery(_queryController.text);
      }
    } else {
      setState(() {
        isListening = true;
        aiResponse = "🎙️ Listening... Speak your civic question (e.g. 'Nearest hospital', 'Water leaks', 'Emergency').";
      });

      // Interactive auto-listen simulate
      Future.delayed(const Duration(milliseconds: 2500), () {
        if (!mounted || !isListening) return;
        setState(() {
          isListening = false;
        });
        if (_queryController.text.trim().isEmpty) {
          _queryController.text = "Show water leaks in RS Puram";
        }
        _handleQuery(_queryController.text);
      });
    }
  }

  void _handleQuery(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      isThinking = true;
      isListening = false;
      aiResponse = "Analyzing civic query: '$text'...";
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      final res = PulseAIService.processQuery(text);
      if (!mounted) return;

      setState(() {
        aiResponse = res.text;
        isThinking = false;
      });

      Future.delayed(const Duration(milliseconds: 1100), () {
        if (!mounted) return;

        if (res.actionType == "open_emergency") {
          Navigator.pop(context);
          EmergencySOSSheet.show(context);
        } else if (res.actionType == "open_explore") {
          Navigator.pop(context);
          widget.onNavigateTab?.call(1, subType: res.payload); // Explore tab
        } else if (res.actionType == "filter_category" && res.payload != null) {
          Navigator.pop(context);
          widget.onFilterCategory?.call(res.payload!);
        } else if (res.actionType == "open_events") {
          Navigator.pop(context);
          widget.onNavigateTab?.call(3); // Events tab
        } else if (res.actionType == "open_report") {
          Navigator.pop(context);
          widget.onNavigateTab?.call(2); // Report tab
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 18),

          // Central Animated Microphone / Listening Waveform
          GestureDetector(
            onTap: _toggleListening,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final double scale = isListening ? 1.0 + (_pulseController.value * 0.22) : 1.0;
                final double glow = isListening ? 24 * _pulseController.value : 8;

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: isListening ? AppColors.alertGradient : AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (isListening ? AppColors.alert : AppColors.primary).withValues(alpha: 0.45),
                          blurRadius: 16 + glow,
                          spreadRadius: isListening ? 4 : 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          Text(
            isListening ? "Listening to your voice..." : "PulseAI Voice Assistant",
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: isListening ? AppColors.alert : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isListening ? "Tap the mic again to stop" : "Tap the mic to speak or select a suggestion",
            style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),

          // AI Response Bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: (isListening ? AppColors.alert : AppColors.primary).withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isListening ? Icons.hearing_rounded : Icons.auto_awesome,
                  color: isListening ? AppColors.alert : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    aiResponse,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isThinking ? AppColors.textMuted : AppColors.textPrimary,
                      fontWeight: isListening ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick Suggestion Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: samplePrompts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final prompt = samplePrompts[index];
                return ActionChip(
                  label: Text(prompt, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  backgroundColor: AppColors.surfaceSecondary,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onPressed: () {
                    final cleanQuery = prompt.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                    _queryController.text = cleanQuery;
                    _handleQuery(cleanQuery);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),

          // Query Input Box
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  onSubmitted: _handleQuery,
                  decoration: InputDecoration(
                    hintText: "Type or ask a civic question...",
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
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
              const SizedBox(width: 10),
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
}
