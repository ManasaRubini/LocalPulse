import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../utils/app_colors.dart';
import 'emergency_sos_sheet.dart';

class VoiceAssistantModal extends StatefulWidget {
  final Function(String category)? onFilterCategory;
  final Function(int tabIndex)? onNavigateTab;

  const VoiceAssistantModal({
    super.key,
    this.onFilterCategory,
    this.onNavigateTab,
  });

  static void show(BuildContext context, {Function(String category)? onFilterCategory, Function(int tabIndex)? onNavigateTab}) {
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
  
  String aiResponse = "Hi! I'm PulseAI, your civic assistant. Ask me about local water issues, road repairs, events, or emergency helplines.";
  bool isThinking = false;

  final List<String> samplePrompts = [
    "💧 Show water issues",
    "🚨 Emergency Police & Ambulance",
    "🌳 Tree plantation events",
    "🚧 Report road damage",
    "🏥 Nearest hospital"
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  void _handleQuery(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      isThinking = true;
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      final res = PulseAIService.processQuery(text);
      if (!mounted) return;

      setState(() {
        aiResponse = res.text;
        isThinking = false;
      });

      if (res.actionType == "open_emergency") {
        Navigator.pop(context);
        EmergencySOSSheet.show(context);
      } else if (res.actionType == "filter_category" && res.payload != null) {
        widget.onFilterCategory?.call(res.payload!);
      } else if (res.actionType == "open_events") {
        widget.onNavigateTab?.call(3); // Events tab
      } else if (res.actionType == "open_report") {
        widget.onNavigateTab?.call(2); // Report tab
      }
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
          const SizedBox(height: 20),

          // Glowing Waveform / Mic Animation
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.12);
              final glow = _pulseController.value * 18;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.primaryGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 12 + glow,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, color: Colors.white, size: 38),
                ),
              );
            },
          ),
          const SizedBox(height: 18),

          const Text(
            "PulseAI Civic Assistant",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // Response Bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    aiResponse,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isThinking ? AppColors.textMuted : AppColors.textPrimary,
                      fontStyle: isThinking ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

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
                    _queryController.text = prompt.replaceAll(RegExp(r'[^\w\s]'), '').trim();
                    _handleQuery(_queryController.text);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),

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
