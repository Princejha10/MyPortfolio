class AvatarAnimationService {
  /// Maps active finance statistics and query state to one of the expressive
  /// animations inside RobotExpressive.glb.
  static String determineAnimation({
    required bool isThinking,
    required bool hasExpensesToday,
    required bool isOverspending,
    required bool isSavingsGoalAchieved,
    required bool isLowSpending,
  }) {
    if (isThinking) {
      return 'Walking'; // Pacing/thinking behavior
    }
    if (isSavingsGoalAchieved) {
      return 'Dance'; // High excitement/celebration
    }
    if (isOverspending) {
      return 'No'; // Concerned head shaking gesture
    }
    if (!hasExpensesToday) {
      return 'Wave'; // Waving hello
    }
    if (isLowSpending) {
      return 'ThumbsUp'; // Thumbs up/happy gesture
    }
    return 'Idle'; // Default breathing idle
  }
}
