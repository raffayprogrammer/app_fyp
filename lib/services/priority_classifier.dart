class PriorityClassifier {
  static const Map<String, int> _categoryScores = {
    'Murder': 8,
    'Snatching': 6,
    'Robbery': 5,
    'Harassment': 4,
    'Corruption': 3,
    'Traffic Violation': 2,
    'Other': 1,
  };

  static const List<String> _highUrgencyKeywords = [
    'knife', 'gun', 'weapon', 'armed', 'pistol', 'blood', 'bleeding',
    'stab', 'shot', 'shoot', 'kill', 'murder', 'dying', 'unconscious',
    'attack', 'attacking', 'assault', 'rape', 'kidnap', 'abduct',
    'hostage', 'trapped', 'help me', 'save me', 'emergency',
  ];

  static const List<String> _timeSensitiveKeywords = [
    'right now', 'happening now', 'currently', 'just now', 'moments ago',
    'in progress', 'as we speak', 'this moment',
  ];

  static const List<String> _mediumUrgencyKeywords = [
    'stole', 'stolen', 'robbed', 'threatened', 'threat', 'followed',
    'following', 'chased', 'harass', 'groping', 'touched', 'inappropriate',
    'broke in', 'broke into', 'break-in', 'snatched', 'mugged',
  ];

  static const List<String> _lowUrgencyKeywords = [
    'noise', 'noisy', 'loud music', 'complaint', 'yesterday', 'last week',
    'last month', 'a while ago', 'minor', 'parking', 'littering',
    'suspicious behavior', 'concerned about',
  ];

  static String classify({
    required String category,
    required String title,
    required String description,
  }) {
    int score = _categoryScores[category] ?? 1;

    final text = '${title.toLowerCase()} ${description.toLowerCase()}';

    for (final keyword in _highUrgencyKeywords) {
      if (text.contains(keyword)) score += 3;
    }

    for (final keyword in _timeSensitiveKeywords) {
      if (text.contains(keyword)) score += 2;
    }

    for (final keyword in _mediumUrgencyKeywords) {
      if (text.contains(keyword)) score += 1;
    }

    for (final keyword in _lowUrgencyKeywords) {
      if (text.contains(keyword)) score -= 2;
    }

    if (score >= 7) return 'high';
    if (score >= 3) return 'medium';
    return 'low';
  }
}
