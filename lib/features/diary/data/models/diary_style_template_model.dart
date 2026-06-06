import '../../../../core/enums/diary_art_style.dart';

class DiaryStyleTemplateModel {
  const DiaryStyleTemplateModel({
    required this.id,
    required this.name,
    required this.artStyle,
    required this.prompt,
    required this.sortOrder,
    this.description,
    this.artSubStyle,
    this.negativePrompt,
    this.previewImageUrl,
  });

  final String id;
  final String name;
  final String? description;
  final DiaryArtStyle artStyle;
  final String? artSubStyle;
  final String prompt;
  final String? negativePrompt;
  final String? previewImageUrl;
  final int sortOrder;

  factory DiaryStyleTemplateModel.fromJson(Map<String, dynamic> json) {
    return DiaryStyleTemplateModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      artStyle: DiaryArtStyle.fromValue(
        json['art_style'] as String? ?? DiaryArtStyle.comicsLd.value,
      ),
      artSubStyle: json['art_sub_style'] as String?,
      prompt: json['prompt'] as String? ?? '',
      negativePrompt: json['negative_prompt'] as String?,
      previewImageUrl: json['preview_image_url'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
