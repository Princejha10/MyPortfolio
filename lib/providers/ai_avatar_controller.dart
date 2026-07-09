import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/avatar_animation_service.dart';
import 'finance_provider.dart';

class AvatarState {
  final String currentAnimation;
  final String modelUrl;

  AvatarState({
    required this.currentAnimation,
    required this.modelUrl,
  });

  AvatarState copyWith({
    String? currentAnimation,
    String? modelUrl,
  }) {
    return AvatarState(
      currentAnimation: currentAnimation ?? this.currentAnimation,
      modelUrl: modelUrl ?? this.modelUrl,
    );
  }
}

class AIAvatarController extends StateNotifier<AvatarState> {
  AIAvatarController()
      : super(AvatarState(
          currentAnimation: 'Idle',
          modelUrl: 'https://modelviewer.dev/shared-assets/models/RobotExpressive.glb',
        ));

  void updateAnimation(String animationName) {
    if (state.currentAnimation != animationName) {
      state = state.copyWith(currentAnimation: animationName);
    }
  }

  void syncWithFinanceState({
    required bool isThinking,
    required FinanceProvider finance,
  }) {
    final hasExpensesToday = finance.todaySpent > 0;
    final isOverspending = finance.monthlySpent > finance.monthlyBudget;
    
    // Low spending if spent is less than 30% of budget
    final isLowSpending = finance.monthlySpent < (finance.monthlyBudget * 0.3);
    
    // Savings goal achieved: healthy balance increase
    final isSavingsGoalAchieved = finance.balance > 15000.0 && !isOverspending;

    final animation = AvatarAnimationService.determineAnimation(
      isThinking: isThinking,
      hasExpensesToday: hasExpensesToday,
      isOverspending: isOverspending,
      isSavingsGoalAchieved: isSavingsGoalAchieved,
      isLowSpending: isLowSpending,
    );

    updateAnimation(animation);
  }
}

final aiAvatarControllerProvider = StateNotifierProvider<AIAvatarController, AvatarState>((ref) {
  return AIAvatarController();
});
