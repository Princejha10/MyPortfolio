import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_avatar_controller.dart';

class AIAvatarWidget extends ConsumerStatefulWidget {
  const AIAvatarWidget({super.key});

  @override
  ConsumerState<AIAvatarWidget> createState() => _AIAvatarWidgetState();
}

class _AIAvatarWidgetState extends ConsumerState<AIAvatarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = ref.watch(aiAvatarControllerProvider);
    final theme = Theme.of(context);
    
    debugPrint("[LOG] Avatar loaded with animation: ${avatar.currentAnimation}");

    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient neon glow backdrop
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  theme.colorScheme.primary.withAlpha(30),
                  theme.colorScheme.primary.withAlpha(0),
                ],
              ),
            ),
          ),
          
          // Pure Flutter animated premium robot avatar body
          _buildBody(context, avatar.currentAnimation),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, String animation) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return AnimatedBuilder(
      animation: _floatAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Side ears / green accent lights
            Positioned(
              left: -6,
              top: 42,
              child: Container(
                width: 10,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.8),
                      blurRadius: 8,
                    )
                  ],
                ),
              ),
            ),
            Positioned(
              right: -6,
              top: 42,
              child: Container(
                width: 10,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.8),
                      blurRadius: 8,
                    )
                  ],
                ),
              ),
            ),
            
            // White rounded robot head body
            Container(
              width: 140,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: primaryColor.withOpacity(0.15), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Black screen display
                    Container(
                      width: 108,
                      height: 72,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E24),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Expressive Eye Screen
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: _buildEyes(animation),
                          ),
                          const SizedBox(height: 8),
                          // Small smile
                          _buildSmile(animation),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEyes(String animation) {
    // Look at chat (shift slightly to the right during Walking/thinking)
    final lookOffset = animation == 'Walking' ? const Offset(3, 0) : Offset.zero;

    if (animation == 'Dance' || animation == 'ThumbsUp' || animation == 'Wave') {
      // Happy eyes ^ ^
      return [
        Transform.translate(
          offset: lookOffset,
          child: const Text('^', style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold, height: 1.0)),
        ),
        Transform.translate(
          offset: lookOffset,
          child: const Text('^', style: TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold, height: 1.0)),
        ),
      ];
    } else if (animation == 'No') {
      // Concerned eyes > <
      return [
        Transform.translate(
          offset: lookOffset,
          child: const Text('>', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, height: 1.0)),
        ),
        Transform.translate(
          offset: lookOffset,
          child: const Text('<', style: TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold, height: 1.0)),
        ),
      ];
    } else if (animation == 'Walking') {
      // Thinking eyes (looking right)
      return [
        Transform.translate(
          offset: const Offset(4, 0),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
          ),
        ),
        Transform.translate(
          offset: const Offset(4, 0),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
          ),
        ),
      ];
    } else {
      // Idle breathing blinking eyes
      return [
        _BlinkingEye(),
        _BlinkingEye(),
      ];
    }
  }

  Widget _buildSmile(String animation) {
    if (animation == 'Dance' || animation == 'ThumbsUp' || animation == 'Wave') {
      // Curved happy smile
      return Container(
        width: 22,
        height: 6,
        decoration: const BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        ),
      );
    } else if (animation == 'No') {
      // Flat concerned line
      return Container(
        width: 18,
        height: 3,
        color: Colors.greenAccent,
      );
    } else {
      // Standard small smile
      return Container(
        width: 14,
        height: 4,
        decoration: const BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
      );
    }
  }
}

class _BlinkingEye extends StatefulWidget {
  @override
  State<_BlinkingEye> createState() => _BlinkingEyeState();
}

class _BlinkingEyeState extends State<_BlinkingEye> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _triggerPeriodicBlink();
  }

  void _triggerPeriodicBlink() async {
    while (mounted) {
      await Future.delayed(const Duration(milliseconds: 3200));
      if (mounted) {
        await _controller.forward();
        await _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1.0, end: 0.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 10,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.greenAccent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: Colors.greenAccent.withOpacity(0.6),
              blurRadius: 4,
            )
          ],
        ),
      ),
    );
  }
}
