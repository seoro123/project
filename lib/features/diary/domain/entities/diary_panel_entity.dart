import '../../../../core/enums/diary_generation_status.dart';

class DiaryPanelEntity {
  const DiaryPanelEntity({
    required this.id,
    required this.diaryId,
    required this.panelOrder,
    required this.panelType,
    required this.imageUrl,
    required this.dialogue,
    required this.prompt,
    required this.seed,
    required this.generationStatus,
    required this.retryCount,
    required this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String diaryId;
  final int panelOrder;
  final String panelType;
  final String? imageUrl;
  final String? dialogue;
  final String? prompt;
  final int? seed;
  final DiaryGenerationStatus generationStatus;
  final int retryCount;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
}
