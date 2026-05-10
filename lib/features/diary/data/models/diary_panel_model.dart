import '../../../../core/enums/diary_generation_status.dart';
import '../../domain/entities/diary_panel_entity.dart';

class DiaryPanelModel extends DiaryPanelEntity {
  const DiaryPanelModel({
    required super.id,
    required super.diaryId,
    required super.panelOrder,
    required super.panelType,
    required super.imageUrl,
    required super.dialogue,
    required super.prompt,
    required super.seed,
    required super.generationStatus,
    required super.retryCount,
    required super.errorMessage,
    required super.createdAt,
    required super.updatedAt,
  });

  /// diary_panels row를 컷 단위 재시도와 수정 UI에서 쓰는 모델로 변환합니다.
  factory DiaryPanelModel.fromJson(Map<String, dynamic> json) {
    return DiaryPanelModel(
      id: json['id'] as String,
      diaryId: json['diary_id'] as String,
      panelOrder: json['panel_order'] as int,
      panelType: json['panel_type'] as String,
      imageUrl: json['image_url'] as String?,
      dialogue: json['dialogue'] as String?,
      prompt: json['prompt'] as String?,
      seed: json['seed'] as int?,
      generationStatus: DiaryGenerationStatus.fromValue(
        json['generation_status'] as String? ??
            DiaryGenerationStatus.queued.value,
      ),
      retryCount: (json['retry_count'] as int?) ?? 0,
      errorMessage: json['error_message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'diary_id': diaryId,
      'panel_order': panelOrder,
      'panel_type': panelType,
      'image_url': imageUrl,
      'dialogue': dialogue,
      'prompt': prompt,
      'seed': seed,
      'generation_status': generationStatus.value,
      'retry_count': retryCount,
      'error_message': errorMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
