import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/enums/diary_art_style.dart';
import '../../../../core/enums/diary_genre.dart';
import '../../../../core/enums/persona_input_mode.dart';
import '../models/persona_model.dart';

class PersonaDraftModel {
  const PersonaDraftModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.appearanceDescription,
    required this.inputMode,
    required this.appearanceTags,
    required this.templateVisibility,
    required this.createdAt,
    required this.updatedAt,
    this.referenceImageUrl,
  });

  final String id;
  final String userId;
  final String name;
  final String appearanceDescription;
  final PersonaInputMode inputMode;
  final List<String> appearanceTags;
  final String templateVisibility;
  final String? referenceImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PersonaDraftModel.fromJson(Map<String, dynamic> json) {
    return PersonaDraftModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String? ?? '나의 캐릭터',
      appearanceDescription: json['appearance_desc'] as String? ?? '',
      inputMode: PersonaInputMode.fromValue(
        json['input_mode'] as String? ?? PersonaInputMode.prose.value,
      ),
      appearanceTags: _draftTagsFromJson(json['appearance_tags']),
      templateVisibility: json['template_visibility'] as String? ?? 'public',
      referenceImageUrl: json['reference_image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static List<String> _draftTagsFromJson(dynamic value) {
    if (value == null) {
      return const <String>[];
    }
    if (value is List) {
      return value.map((dynamic item) => item.toString()).toList();
    }
    if (value is Map<String, dynamic>) {
      final tags = value['tags'];
      if (tags is List) {
        return tags.map((dynamic item) => item.toString()).toList();
      }
      return value.values.map((dynamic item) => item.toString()).toList();
    }
    return <String>[value.toString()];
  }
}

class SupabasePersonaRepository {
  const SupabasePersonaRepository(this._client);

  final SupabaseClient _client;

  /// 餓κ쑨? ?癒?뮉 ??볥젃 疫꿸퀡而??곗쨮 筌?Ŧ??怨? ???館釉?????筌왖 ??밴쉐 ??λ땾???紐꾪뀱??몃빍??
  Future<PersonaModel> createPersonaTemplate({
    required String userId,
    required String name,
    required String appearanceDescription,
    required int seed,
    required PersonaInputMode inputMode,
    List<String> appearanceTags = const <String>[],
    Map<String, String> emotionPrompts = const <String, String>{},
    Map<String, String> expressionLibrary = const <String, String>{},
    DiaryArtStyle defaultArtStyle = DiaryArtStyle.animeLd,
    DiaryGenre defaultGenre = DiaryGenre.dailyComic,
    bool isPublic = true,
    String templateVisibility = 'public',
    String? referenceImageUrl,
  }) async {
    await _deleteStaleFailedPersona(userId: userId, name: name);

    final row = await _client
        .from('personas')
        .insert(<String, dynamic>{
          'user_id': userId,
          'name': name,
          'appearance_desc': appearanceDescription,
          'emotion_prompts': emotionPrompts,
          'default_seed': seed,
          'default_art_style': defaultArtStyle.value,
          'default_genre': defaultGenre.value,
          'input_mode': inputMode.value,
          'appearance_tags': <String, dynamic>{'tags': appearanceTags},
          'expression_library': expressionLibrary,
          'base_image_url': referenceImageUrl,
          'template_visibility': templateVisibility,
          'is_public': isPublic,
        })
        .select()
        .single();

    var persona = PersonaModel.fromJson(row);

    try {
      final response = await _client.functions
          .invoke(
            'generate-persona-image',
            body: <String, dynamic>{
              'persona_id': persona.id,
              'force_regenerate': true,
            },
          )
          .timeout(const Duration(seconds: 120));
      if (response.status >= 400) {
        throw Exception(response.data);
      }

      final updatedRow = await _client
          .from('personas')
          .select()
          .eq('id', persona.id)
          .single();
      persona = PersonaModel.fromJson(updatedRow);
    } catch (error) {
      // ???筌왖 ??밴쉐????쎈솭??猷?筌?Ŧ???row???醫???????癒? ??쇰뻻 ??뺣즲??????뉗쓺 ??몃빍??
      final updatedRow = await _client
          .from('personas')
          .update(<String, dynamic>{
            'generation_status': 'failed',
            'error_message': error.toString(),
          })
          .eq('id', persona.id)
          .select()
          .single();
      persona = PersonaModel.fromJson(updatedRow);
    }

    return persona;
  }

  Future<void> _deleteStaleFailedPersona({
    required String userId,
    required String name,
  }) async {
    await _client
        .from('personas')
        .delete()
        .eq('user_id', userId)
        .eq('name', name)
        .eq('generation_status', 'failed');
  }

  /// ??筌?Ŧ??怨? ?⑤벀而?筌?Ŧ??怨? ??ｍ뜞 揶쎛?紐꾩긿??덈뼄.
  Future<List<PersonaModel>> fetchVisibleTemplates(String userId) async {
    final rows = await _client
        .from('personas')
        .select()
        .order('created_at', ascending: false);

    return rows
        .map<PersonaModel>(
          (dynamic row) => PersonaModel.fromJson(row as Map<String, dynamic>),
        )
        .toList();
  }

  /// 湲곕낯 罹먮┃???먮룞 ?앹꽦? ?쒓굅?덉뒿?덈떎.
  /// ?ъ슜?먭? 吏곸젒 留뚮뱺 罹먮┃?곕쭔 紐⑸줉怨??쇨린 ?앹꽦???ъ슜?⑸땲??
  Future<List<PersonaModel>> ensureStarterTemplates(String userId) async {
    return const <PersonaModel>[];
  }

  Future<void> deletePersonaTemplate(String personaId) async {
    await _client.from('personas').delete().eq('id', personaId);
  }

  Future<PersonaDraftModel?> fetchPersonaDraft(String userId) async {
    final rows = await _client
        .from('persona_drafts')
        .select()
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) {
      return null;
    }
    return PersonaDraftModel.fromJson(rows.first);
  }

  Future<PersonaDraftModel> upsertPersonaDraft({
    required String userId,
    required String name,
    required String appearanceDescription,
    required PersonaInputMode inputMode,
    required List<String> appearanceTags,
    required String templateVisibility,
    String? referenceImageUrl,
  }) async {
    final row = await _client
        .from('persona_drafts')
        .upsert(<String, dynamic>{
          'user_id': userId,
          'name': name.trim().isEmpty ? '나의 캐릭터' : name.trim(),
          'appearance_desc': appearanceDescription,
          'input_mode': inputMode.value,
          'appearance_tags': <String, dynamic>{'tags': appearanceTags},
          'template_visibility': templateVisibility,
          'reference_image_url': referenceImageUrl,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, onConflict: 'user_id')
        .select()
        .single();

    return PersonaDraftModel.fromJson(row);
  }

  Future<void> deletePersonaDraft(String userId) async {
    await _client.from('persona_drafts').delete().eq('user_id', userId);
  }
}
