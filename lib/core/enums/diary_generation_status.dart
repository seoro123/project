enum DiaryGenerationStatus {
  queued('queued'),
  processing('processing'),
  completed('completed'),
  failed('failed');

  const DiaryGenerationStatus(this.value);

  final String value;

  static DiaryGenerationStatus fromValue(String value) {
    return DiaryGenerationStatus.values.firstWhere(
      (DiaryGenerationStatus status) => status.value == value,
      orElse: () => DiaryGenerationStatus.queued,
    );
  }
}
