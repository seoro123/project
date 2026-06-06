// ignore_for_file: unused_element, unused_element_parameter

part of '../pinterest_home_screen.dart';

class _DiaryPage extends StatefulWidget {
  const _DiaryPage({required this.onSharedDiaryCreated});

  final VoidCallback onSharedDiaryCreated;

  @override
  State<_DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<_DiaryPage> {
  static const List<String> _defaultAlbumTitles = <String>[
    '\uBE44\uACF5\uAC1C',
    '\uC77C\uC0C1',
    '\uC18C\uC911\uD55C \uC21C\uAC04',
  ];

  static const List<DiaryStyleTemplateModel>
  _fallbackStyleTemplates = <DiaryStyleTemplateModel>[
    DiaryStyleTemplateModel(
      id: 'semi_realistic_daily',
      name: '\uADF9\uD654\uD615 \uC77C\uAE30',
      description:
          '\uD45C\uC815\uACFC \uC7A5\uBA74\uC744 \uC12C\uC138\uD558\uAC8C \uC0B4\uB9AC\uB294 LD',
      artStyle: DiaryArtStyle.comicsLd,
      artSubStyle: '\uADF9\uD654\uD615 (Semi-Realistic)',
      prompt:
          'Semi-realistic Korean diary webtoon style, believable stylized anatomy, firm contour lines, expressive face planes, clear hands, cinematic daily lighting, dramatic but readable single vertical card panel.',
      sortOrder: 10,
    ),
    DiaryStyleTemplateModel(
      id: 'graphic_anime_daily',
      name: '\uC560\uB2C8\uD615 \uADF8\uB798\uD53D',
      description:
          '\uAE54\uB054\uD55C \uC120\uACFC \uC140 \uC250\uC774\uB529 \uC911\uC2EC',
      artStyle: DiaryArtStyle.animeLd,
      artSubStyle: '\uC560\uB2C8\uD615 (Graphic)',
      prompt:
          'Graphic anime diary webtoon style, clean stylized linework, crisp cel shading, expressive animated eyes, smooth hair clumps, controlled color blocks, clear emotional acting.',
      sortOrder: 20,
    ),
    DiaryStyleTemplateModel(
      id: 'casual_cartoon_daily',
      name: '\uCE90\uC8FC\uC5BC \uB9CC\uD654',
      description:
          '\uC6C3\uAE34 \uD45C\uC815\uACFC \uACFC\uC7A5\uB41C \uC561\uC158\uC5D0 \uC801\uD569',
      artStyle: DiaryArtStyle.comicsSd,
      artSubStyle: '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615 (Cartoon)',
      prompt:
          'Casual cartoon diary style, simplified cute proportions, bouncy shapes, exaggerated comedy expressions, bright flat color blocks, sweat drops, motion marks, playful daily gag timing.',
      sortOrder: 30,
    ),
    DiaryStyleTemplateModel(
      id: 'simple_character_daily',
      name: '\uC2EC\uD50C \uCE90\uB9AD\uD130',
      description:
          '\uC544\uC774\uCF58\uCC98\uB7FC \uC77D\uD788\uB294 \uB2E8\uC21C\uD55C SD',
      artStyle: DiaryArtStyle.simple2d,
      artSubStyle: '\uCE90\uB9AD\uD130\uD615 (Simple Character)',
      prompt:
          'Simple character diary style, mascot-like 2D silhouette, minimal facial features, rounded body, clean outlines, flat pastel fills, readable props, calm negative space.',
      sortOrder: 40,
    ),
    DiaryStyleTemplateModel(
      id: 'soft_3d_daily',
      name: '\uC18C\uD504\uD2B8 3D',
      description:
          '\uC785\uCCB4\uAC10\uACFC \uBE5B\uC774 \uBCF4\uC774\uB294 3D',
      artStyle: DiaryArtStyle.realistic3d,
      artSubStyle: '\uC785\uCCB4 \uB80C\uB354\uB9C1 (3D Style)',
      prompt:
          'Stylized 3D animated diary scene, volumetric rounded character, sculpted hair, soft materials, ambient occlusion, cast shadows, cozy miniature daily environment, no flat 2D line art.',
      sortOrder: 50,
    ),
  ];

  final PageController _controller = PageController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _albumController = TextEditingController();
  final Map<String, String> _albumIdsByTitle = <String, String>{};
  final Map<String, String> _templateIdsByName = <String, String>{};
  final List<PersonaModel> _diaryPersonas = <PersonaModel>[];
  final List<DiaryStyleTemplateModel> _styleTemplates =
      <DiaryStyleTemplateModel>[];
  final Map<String, int> _albumDiaryCounts = <String, int>{};
  final Map<String, List<DiaryModel>> _albumDiariesByTitle =
      <String, List<DiaryModel>>{};
  final List<DiaryPanelModel> _generatedPanels = <DiaryPanelModel>[];
  final List<String> _generatedImageUrls = <String>[];

  int _page = 0;
  String _template = '';
  String _selectedPersonaId = '';
  String _album = '\uC77C\uC0C1 \uAE30\uB85D';
  String _weather = 'sunny';
  String _saveMode = 'archive';
  String _artStyle = '\uC0AC\uC2E4\uC801 \uC2A4\uD0C0\uC77C (LD)';
  String _artSubStyle = '\uADF9\uD654\uD615 (Semi-Realistic)';
  String _styleTemplateId = '';
  String _genre = '\uC720\uCF8C\uD558\uACE0 \uC6C3\uAE34 \uB0A0';
  String _genreSubtype = '';
  int _targetCutCount = 0;
  bool _isSaving = false;
  bool _isLoadingArchive = false;
  bool _isLoadingTemplates = false;
  int _finalMobileFlowKey = 0;
  String? _selectedArchiveAlbum;

  final List<String> _albums = <String>[..._defaultAlbumTitles];
  final List<String> _templates = <String>[];

  @override
  void initState() {
    super.initState();
    unawaited(_loadAlbums());
    unawaited(_loadDiaryTemplates());
    unawaited(_loadStyleTemplates());
  }

  @override
  void dispose() {
    _controller.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    _tagController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 4 : 12,
        mobile ? 4 : 10,
        mobile ? 4 : 12,
        mobile ? 8 : 14,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: mobile ? double.infinity : 1240,
          ),
          child: _DiaryFigmaFrame(
            title: _title,
            pageIndex: _page,
            bookChrome: true,
            onClose: () => _go(0),
            child: PageView(
              controller: _controller,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (int value) => setState(() => _page = value),
              children: <Widget>[
                _DiaryOpenPage(
                  onArchive: () {
                    unawaited(_loadAlbums());
                    _go(2);
                  },
                  onStart: () {
                    setState(() => _finalMobileFlowKey++);
                    _go(1);
                  },
                ),
                _DiaryFinalScreen(
                  key: ValueKey<int>(_finalMobileFlowKey),
                  templates: _templates,
                  selectedPersonaId: _selectedPersonaId,
                  personas: _diaryPersonas,
                  titleController: _titleController,
                  bodyController: _bodyController,
                  tagController: _tagController,
                  titleText: _titleController.text,
                  weather: _weather,
                  artStyle: _artStyle,
                  artSubStyle: _artSubStyle,
                  selectedStyleTemplateId: _styleTemplateId,
                  styleTemplates: _styleTemplates,
                  genre: _genre,
                  genreSubtype: _genreSubtype,
                  targetCutCount: _targetCutCount,
                  artSubStyleOptions: _artSubStyleCards
                      .map((_FigmaCardData item) => item.label)
                      .toList(),
                  genreSubtypeOptions: _genreSubtypeCards
                      .map((_FigmaCardData item) => item.label)
                      .toList(),
                  keywordTags: _keywordTags(),
                  isSaving: _isSaving,
                  onArtStyleChanged: _selectArtStyle,
                  onArtSubStyleChanged: (String value) {
                    setState(() => _artSubStyle = value);
                  },
                  onStyleTemplateChanged: _selectStyleTemplate,
                  onGenreChanged: _selectGenre,
                  onGenreSubtypeChanged: (String value) {
                    setState(() => _genreSubtype = value);
                  },
                  onTargetCutCountChanged: (int value) {
                    setState(() => _targetCutCount = value);
                  },
                  onTemplateChanged: (String value) {
                    setState(() {
                      _selectedPersonaId = value;
                      PersonaModel? persona;
                      for (final item in _diaryPersonas) {
                        if (item.id == value) {
                          persona = item;
                          break;
                        }
                      }
                      if (persona != null) {
                        _template = persona.name;
                      }
                    });
                  },
                  onDraftChanged: () => setState(() {}),
                  onWeatherChanged: (String value) {
                    setState(() => _weather = value);
                  },
                  onGenerate: () => unawaited(_showDiaryPublishSettings()),
                  onBack: () => _go(0),
                  isLoadingTemplates: _isLoadingTemplates,
                  previewImageUrls: _generatedImageUrls,
                ),
                _ArchiveScreen(
                  albums: _albums,
                  albumDiaryCounts: _albumDiaryCounts,
                  albumDiariesByTitle: _albumDiariesByTitle,
                  selectedAlbum: _selectedArchiveAlbum,
                  isLoading: _isLoadingArchive,
                  controller: _albumController,
                  onBack: () => _go(0),
                  onCreateAlbum: _createAlbum,
                  onAlbumSelected: (String title) {
                    setState(() => _selectedArchiveAlbum = title);
                  },
                  onDeleteAlbum: _deleteAlbum,
                  onOpenDiary: _showArchivedDiary,
                  onRemoveDiary: _removeDiaryFromAlbum,
                  onDeleteDiary: _deleteArchivedDiary,
                  onRefresh: _loadAlbums,
                ),
                _GeneratedDiarySlideScreen(
                  panels: _generatedPanels,
                  imageUrls: _generatedImageUrls,
                  onBack: () => _go(1),
                  onRetryPanel: _retryGeneratedPanel,
                  onDone: () {
                    if (_saveMode == 'share') {
                      widget.onSharedDiaryCreated();
                      _go(0);
                    } else {
                      _go(2);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    return switch (_page) {
      0 => '\uC77C\uAE30',
      1 => '\uC77C\uAE30(\uC124\uC815)',
      2 => '\uC544\uCE74\uC774\uBE0C',
      3 => '\uC77C\uAE30(\uC0DD\uC131 \uACB0\uACFC)',
      _ => '\uC77C\uAE30',
    };
  }

  Future<void> _loadAlbums() async {
    if (!SupabaseRuntime.isConfigured) {
      return;
    }

    setState(() => _isLoadingArchive = true);

    try {
      final user = await _ensureSupabaseUserProfile();
      final repository = SupabaseDiaryRepository(Supabase.instance.client);
      var albums = await repository.fetchMyAlbums(user.id);
      if (albums.isEmpty) {
        for (final title in _defaultAlbumTitles) {
          await repository.createAlbum(userId: user.id, title: title);
        }
        albums = await repository.fetchMyAlbums(user.id);
      }
      if (!mounted) {
        return;
      }
      if (albums.isEmpty) {
        if (mounted) {
          setState(() {
            _albums
              ..clear()
              ..addAll(_defaultAlbumTitles);
            _albumIdsByTitle.clear();
            _albumDiaryCounts.clear();
            _albumDiariesByTitle.clear();
            _album = _albums.first;
            _selectedArchiveAlbum ??= _albums.first;
            _isLoadingArchive = false;
          });
        }
        return;
      }

      final albumDiaries = <String, List<DiaryModel>>{};
      for (final album in albums) {
        albumDiaries[album.title] = await repository.fetchAlbumDiaries(
          album.id,
        );
      }

      setState(() {
        _albums
          ..clear()
          ..addAll(albums.map((DiaryAlbumModel album) => album.title));
        _albumIdsByTitle
          ..clear()
          ..addEntries(
            albums.map(
              (DiaryAlbumModel album) => MapEntry(album.title, album.id),
            ),
          );
        _albumDiaryCounts
          ..clear()
          ..addEntries(
            albums.map((DiaryAlbumModel album) {
              final diaries = albumDiaries[album.title] ?? const <DiaryModel>[];
              return MapEntry(album.title, diaries.length);
            }),
          );
        _albumDiariesByTitle
          ..clear()
          ..addAll(albumDiaries);
        if (!_albums.contains(_album)) {
          _album = _albums.first;
        }
        if (_selectedArchiveAlbum == null ||
            !_albums.contains(_selectedArchiveAlbum)) {
          _selectedArchiveAlbum = _albums.first;
        }
        _isLoadingArchive = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingArchive = false);
      }
    }
  }

  Future<void> _loadDiaryTemplates() async {
    if (!SupabaseRuntime.isConfigured) {
      return;
    }

    setState(() => _isLoadingTemplates = true);

    try {
      final user = await _ensureSupabaseUserProfile();
      final repository = SupabasePersonaRepository(Supabase.instance.client);
      final visibleTemplates = await repository.fetchVisibleTemplates(user.id);

      if (!mounted) {
        return;
      }

      setState(() {
        _diaryPersonas
          ..clear()
          ..addAll(visibleTemplates);
        _templates
          ..clear()
          ..addAll(
            visibleTemplates
                .map((PersonaModel template) => template.name)
                .toSet(),
          );
        _templateIdsByName
          ..clear()
          ..addEntries(
            visibleTemplates.map(
              (PersonaModel template) => MapEntry(template.name, template.id),
            ),
          );
        if (_diaryPersonas.isEmpty) {
          _template = '';
          _selectedPersonaId = '';
        } else if (!_diaryPersonas.any(
          (PersonaModel item) => item.id == _selectedPersonaId,
        )) {
          final firstMine = _diaryPersonas
              .where((PersonaModel item) => item.userId == user.id)
              .toList();
          final selected = firstMine.isNotEmpty
              ? firstMine.first
              : _diaryPersonas.first;
          _selectedPersonaId = selected.id;
          _template = selected.name;
        }
        _isLoadingTemplates = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _diaryPersonas.clear();
          _templates.clear();
          _templateIdsByName.clear();
          _template = '';
          _selectedPersonaId = '';
          _isLoadingTemplates = false;
        });
      }
    }
  }

  Future<void> _loadStyleTemplates() async {
    if (!SupabaseRuntime.isConfigured) {
      setState(() {
        _styleTemplates
          ..clear()
          ..addAll(_fallbackStyleTemplates);
        _applyStyleTemplate(_styleTemplates.first);
      });
      return;
    }

    try {
      final templates = await SupabaseDiaryRepository(
        Supabase.instance.client,
      ).fetchStyleTemplates();
      if (!mounted) {
        return;
      }
      setState(() {
        _styleTemplates
          ..clear()
          ..addAll(templates.isEmpty ? _fallbackStyleTemplates : templates);
        _applyStyleTemplate(_styleTemplates.first);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _styleTemplates
            ..clear()
            ..addAll(_fallbackStyleTemplates);
          _applyStyleTemplate(_styleTemplates.first);
        });
      }
    }
  }

  void _createAlbum(String title) {
    unawaited(_createAlbumAsync(title));
  }

  Future<void> _showArchivedDiary(DiaryModel diary) async {
    final panels = SupabaseRuntime.isConfigured
        ? await SupabaseDiaryRepository(
            Supabase.instance.client,
          ).fetchDiaryPanels(diary.id)
        : const <DiaryPanelModel>[];
    final imageUrls = panels.isEmpty
        ? _diaryImageUrlsReadingOrder(diary.imageUrls)
        : _diaryPanelImageUrlsReadingOrder(panels);
    if (!mounted) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.90,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              children: <Widget>[
                Text(
                  diary.title?.trim().isNotEmpty == true
                      ? diary.title!.trim()
                      : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: _ImageUrlSlideDeck(
                    imageUrls: imageUrls,
                    panels: panels,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _removeDiaryFromAlbum(
    String albumTitle,
    DiaryModel diary,
  ) async {
    final albumId = _albumIdsByTitle[albumTitle];
    if (albumId == null) {
      return;
    }
    await SupabaseDiaryRepository(
      Supabase.instance.client,
    ).removeDiaryFromAlbum(albumId: albumId, diaryId: diary.id);
    await _loadAlbums();
  }

  Future<void> _deleteArchivedDiary(String albumTitle, DiaryModel diary) async {
    await SupabaseDiaryRepository(
      Supabase.instance.client,
    ).deleteDiary(diary.id);
    await _loadAlbums();
    widget.onSharedDiaryCreated();
  }

  Future<void> _deleteAlbum(String albumTitle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('\uC568\uBC94 \uC0AD\uC81C'),
          content: Text(
            '\u2018$albumTitle\u2019 \uC568\uBC94\uC744 \uC0AD\uC81C\uD560\uAE4C\uC694?\n\uC568\uBC94\uB9CC \uC0AD\uC81C\uB418\uACE0 \uC77C\uAE30 \uC790\uCCB4\uB294 \uB0A8\uC544\uC788\uC2B5\uB2C8\uB2E4.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('\uCDE8\uC18C'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('\uC0AD\uC81C'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }

    final albumId = _albumIdsByTitle[albumTitle];
    if (SupabaseRuntime.isConfigured && albumId != null) {
      try {
        await SupabaseDiaryRepository(
          Supabase.instance.client,
        ).deleteAlbum(albumId);
      } catch (error) {
        if (mounted) {
          _showMessage(
            '\uC568\uBC94 \uC0AD\uC81C \uC2E4\uD328: ${_friendlyGenerationError(error)}',
          );
        }
        return;
      }
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _albums.remove(albumTitle);
      _albumIdsByTitle.remove(albumTitle);
      _albumDiaryCounts.remove(albumTitle);
      _albumDiariesByTitle.remove(albumTitle);
      if (_selectedArchiveAlbum == albumTitle) {
        _selectedArchiveAlbum = _albums.isEmpty ? null : _albums.first;
      }
      if (_album == albumTitle) {
        _album = _albums.isEmpty ? '' : _albums.first;
      }
    });
    _showMessage('\uC568\uBC94\uC744 \uC0AD\uC81C\uD588\uC2B5\uB2C8\uB2E4.');
  }

  Future<String?> _createAlbumAsync(String title) async {
    final normalized = title.trim();
    if (normalized.isEmpty) {
      return _albumIdsByTitle[normalized];
    }

    if (_albums.contains(normalized)) {
      setState(() => _album = normalized);
      return _albumIdsByTitle[normalized];
    }

    String? albumId;
    if (SupabaseRuntime.isConfigured) {
      try {
        final user = await _ensureSupabaseUserProfile();
        final repository = SupabaseDiaryRepository(Supabase.instance.client);
        final album = await repository.createAlbum(
          userId: user.id,
          title: normalized,
        );
        albumId = album.id;
      } catch (error) {
        if (mounted) {
          _showMessage(
            '\uC568\uBC94\uC740 \uD654\uBA74\uC5D0\uB9CC \uCD94\uAC00\uD588\uC2B5\uB2C8\uB2E4. DB \uC800\uC7A5 \uC2E4\uD328: ${_friendlyGenerationError(error)}',
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _albums.add(normalized);
        if (albumId != null) {
          _albumIdsByTitle[normalized] = albumId;
        }
        _albumDiaryCounts.putIfAbsent(normalized, () => 0);
        _albumDiariesByTitle.putIfAbsent(
          normalized,
          () => const <DiaryModel>[],
        );
        _album = normalized;
        _selectedArchiveAlbum = normalized;
        _albumController.clear();
      });
    }

    return albumId;
  }

  Future<void> _showDiaryPublishSettings() async {
    var draftSaveMode = _saveMode;
    var draftAlbum = _album;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('\uCD5C\uC885 \uBC1C\uD589 \uC124\uC815'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _SaveModeSelector(
                      selected: draftSaveMode,
                      onChanged: (String value) {
                        setDialogState(() => draftSaveMode = value);
                      },
                    ),
                    if (draftSaveMode == 'archive') ...<Widget>[
                      const Gap(16),
                      _FigmaDropdown(
                        label: '\uC18C\uC7A5\uD560 \uC568\uBC94',
                        value: draftAlbum,
                        values: _albums,
                        onChanged: (String value) {
                          setDialogState(() => draftAlbum = value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('\uCDE8\uC18C'),
                ),
                FilledButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  icon: const Icon(Icons.publish_rounded),
                  label: const Text(
                    '\uC774 \uC124\uC815\uC73C\uB85C \uBC1C\uD589',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _saveMode = draftSaveMode;
      _album = draftAlbum;
    });
    await _saveDiary();
  }

  Future<void> _saveDiary() async {
    if (_bodyController.text.trim().isEmpty) {
      _showMessage(
        '\uC77C\uAE30 \uB0B4\uC6A9\uC744 \uBA3C\uC800 \uC791\uC131\uD574 \uC8FC\uC138\uC694.',
      );
      return;
    }

    setState(() => _isSaving = true);
    setState(() {
      _generatedPanels.clear();
      _generatedImageUrls.clear();
    });

    try {
      final user = await _ensureSupabaseUserProfile();
      var personaId = _selectedPersonaId.isNotEmpty
          ? _selectedPersonaId
          : _templateIdsByName[_template];
      if (personaId == null) {
        await _loadDiaryTemplates();
        personaId = _selectedPersonaId.isNotEmpty
            ? _selectedPersonaId
            : _templateIdsByName[_template];
      }
      if (personaId == null) {
        _showMessage(
          '\uC120\uD0DD\uD55C \uCE90\uB9AD\uD130\uB97C DB\uC5D0\uC11C \uCC3E\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4. \uCE90\uB9AD\uD130 \uD0ED\uC744 \uD55C \uBC88 \uC5F4\uACE0 \uB2E4\uC2DC \uC2DC\uB3C4\uD574 \uC8FC\uC138\uC694.',
        );
        return;
      }
      final repository = SupabaseDiaryRepository(Supabase.instance.client);
      final diary = await repository.createDiary(
        userId: user.id,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        content: _bodyController.text.trim(),
        diaryAt: DateTime.now(),
        weather: WeatherType.fromValue(_weather),
        webtoonFormat: _selectedWebtoonFormat(),
        artStyle: _selectedArtStyle(),
        artSubStyle: _artSubStyle,
        styleTemplateId: _selectedStyleTemplate?.id,
        styleTemplatePrompt: _selectedStyleTemplate?.prompt,
        genre: _selectedGenre(),
        genreSubtype: _selectedGenreSubtype().isEmpty
            ? null
            : _selectedGenreSubtype(),
        keywordTags: _generationKeywordTags(),
        personaId: personaId,
        isPublic: _saveMode == 'share',
        visibility: _visibilityFromSaveMode(_saveMode),
      );
      var panels = await repository.fetchDiaryPanels(diary.id);
      panels = await _drawFinalSpeechBubbles(
        repository: repository,
        userId: user.id,
        diaryId: diary.id,
        panels: panels,
      );
      final finalImageUrls = _diaryPanelImageUrlsReadingOrder(panels);
      if (finalImageUrls.isNotEmpty) {
        await repository.updateDiaryImageUrls(
          diaryId: diary.id,
          imageUrls: finalImageUrls,
        );
      }

      if (_saveMode == 'archive') {
        var albumId = _albumIdsByTitle[_album];
        albumId ??= await _createAlbumAsync(_album);
        if (albumId != null) {
          await repository.addDiaryToAlbumAfterEnsuringPublic(
            userId: user.id,
            albumId: albumId,
            diaryId: diary.id,
          );
          _albumDiaryCounts[_album] = (_albumDiaryCounts[_album] ?? 0) + 1;
          _albumDiariesByTitle[_album] = <DiaryModel>[
            diary,
            ...(_albumDiariesByTitle[_album] ?? const <DiaryModel>[]),
          ];
          _selectedArchiveAlbum = _album;
          unawaited(_loadAlbums());
        }
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _generatedPanels
          ..clear()
          ..addAll(panels);
        _generatedImageUrls
          ..clear()
          ..addAll(
            finalImageUrls.isNotEmpty
                ? finalImageUrls
                : _diaryImageUrlsReadingOrder(
                    panels
                        .map((DiaryPanelModel panel) => panel.imageUrl)
                        .whereType<String>()
                        .toList(),
                  ),
          );
      });

      _showMessage(
        _saveMode == 'share'
            ? '\uACF5\uC720 \uC77C\uAE30\uB85C \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4. \uC18C\uC15C \uD53C\uB4DC\uC5D0 \uD45C\uC2DC\uB429\uB2C8\uB2E4.'
            : _saveMode == 'followers'
            ? '\uD314\uB85C\uC6CC \uACF5\uAC1C \uC77C\uAE30\uB85C \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4.'
            : '\uC77C\uAE30\uAC00 \uC568\uBC94\uC5D0 \uC18C\uC7A5\uB410\uC2B5\uB2C8\uB2E4.',
      );
      if (_saveMode == 'share' || _saveMode == 'followers') {
        widget.onSharedDiaryCreated();
      }
      _go(3);
    } catch (error) {
      if (mounted) {
        _showMessage(
          '\uC800\uC7A5 \uC2E4\uD328: ${_friendlyGenerationError(error)}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<List<DiaryPanelModel>> _drawFinalSpeechBubbles({
    required SupabaseDiaryRepository repository,
    required String userId,
    required String diaryId,
    required List<DiaryPanelModel> panels,
    Set<String>? onlyPanelIds,
  }) async {
    final renderedPanels = <DiaryPanelModel>[];
    for (final panel in panels) {
      if (onlyPanelIds != null && !onlyPanelIds.contains(panel.id)) {
        renderedPanels.add(panel);
        continue;
      }
      final imageUrl = panel.imageUrl;
      final dialogue = panel.dialogue?.trim();
      if (imageUrl == null ||
          imageUrl.isEmpty ||
          dialogue == null ||
          dialogue.isEmpty) {
        renderedPanels.add(panel);
        continue;
      }

      try {
        final sourceBytes = await _downloadDiaryAssetBytes(imageUrl);
        final textLayerBytes = await _drawWebtoonBubbleIntoImage(
          sourceBytes: sourceBytes,
          dialogue: dialogue,
          prompt: panel.prompt,
        );
        final path =
            '$userId/diaries/$diaryId/panel-${panel.panelOrder}-bubble-${DateTime.now().millisecondsSinceEpoch}.png';
        await Supabase.instance.client.storage
            .from('diary-assets')
            .uploadBinary(
              path,
              textLayerBytes,
              fileOptions: const FileOptions(
                contentType: 'image/png',
                upsert: true,
              ),
            );
        final publicUrl = Supabase.instance.client.storage
            .from('diary-assets')
            .getPublicUrl(path);
        renderedPanels.add(
          await repository.updateDiaryPanelImageUrl(
            panelId: panel.id,
            imageUrl: publicUrl,
          ),
        );
      } catch (_) {
        renderedPanels.add(panel);
      }
    }
    return renderedPanels;
  }

  Future<void> _retryGeneratedPanel(
    DiaryPanelModel panel,
    String retryFeedback,
  ) async {
    setState(() => _isSaving = true);
    try {
      final user = await _ensureSupabaseUserProfile();
      final repository = SupabaseDiaryRepository(Supabase.instance.client);
      await repository.retryDiaryPanel(
        diaryId: panel.diaryId,
        panelId: panel.id,
        retryFeedback: retryFeedback,
      );
      var panels = await repository.fetchDiaryPanels(panel.diaryId);
      panels = await _drawFinalSpeechBubbles(
        repository: repository,
        userId: user.id,
        diaryId: panel.diaryId,
        panels: panels,
        onlyPanelIds: <String>{panel.id},
      );
      final finalImageUrls = _diaryPanelImageUrlsReadingOrder(panels);
      if (finalImageUrls.isNotEmpty) {
        await repository.updateDiaryImageUrls(
          diaryId: panel.diaryId,
          imageUrls: finalImageUrls,
        );
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _generatedPanels
          ..clear()
          ..addAll(panels);
        _generatedImageUrls
          ..clear()
          ..addAll(finalImageUrls);
      });
      _showMessage(
        '\uC774\uBBF8\uC9C0 \uC0DD\uC131\uC744 \uC694\uCCAD\uD588\uC2B5\uB2C8\uB2E4.',
      );
    } catch (error) {
      if (mounted) {
        _showMessage('\uC774\uBBF8\uC9C0 \uC0DD\uC131 \uC2E4\uD328: ');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<Uint8List> _downloadDiaryAssetBytes(String imageUrl) async {
    final storagePath = _storagePathFromDiaryAssetPublicUrl(imageUrl);
    if (storagePath != null) {
      return Supabase.instance.client.storage
          .from('diary-assets')
          .download(storagePath);
    }

    final data = await NetworkAssetBundle(Uri.parse(imageUrl)).load(imageUrl);
    return data.buffer.asUint8List();
  }

  Future<Uint8List> _drawWebtoonBubbleIntoImage({
    required Uint8List sourceBytes,
    required String dialogue,
    required String? prompt,
  }) async {
    final codec = await instantiateImageCodec(sourceBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(image, Offset.zero, Paint());

    final text = _normalizeDialogueForBubble(dialogue);
    final initialTextRect = _dialogueTextRect(
      width: width,
      height: height,
      prompt: prompt,
      text: text,
    );
    final bubbleRect = initialTextRect
        .inflate(width * 0.055)
        .intersect(
          Rect.fromLTWH(
            width * 0.02,
            height * 0.02,
            width * 0.96,
            height * 0.94,
          ),
        );
    final textRect = _insetForText(bubbleRect, width);
    final bubbleRadius = Radius.circular(width * 0.055);
    final bubbleFill = Paint()..color = Colors.white.withValues(alpha: 0.96);
    final bubbleBorder = Paint()
      ..color = const Color(0xFF22262E).withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = width * 0.006;
    final bubbleShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.10)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    final bubbleRRect = RRect.fromRectAndRadius(bubbleRect, bubbleRadius);
    canvas.drawRRect(
      bubbleRRect.shift(Offset(width * 0.006, height * 0.006)),
      bubbleShadow,
    );
    canvas.drawRRect(bubbleRRect, bubbleFill);
    canvas.drawRRect(bubbleRRect, bubbleBorder);

    final tail = _dialogueBubbleTail(
      bubbleRect: bubbleRect,
      prompt: prompt,
      width: width,
      height: height,
    );
    canvas.drawPath(
      tail.shift(Offset(width * 0.006, height * 0.006)),
      bubbleShadow,
    );
    canvas.drawPath(tail, bubbleFill);
    canvas.drawPath(tail, bubbleBorder);

    final fontSize = _fitDialogueFontSize(
      text: text,
      maxWidth: textRect.width,
      maxHeight: textRect.height,
      imageWidth: width,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFF1E2430),
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1.18,
          letterSpacing: 0,
          fontFamily: GoogleFonts.notoSansKr().fontFamily,
          shadows: <Shadow>[
            Shadow(
              color: Colors.white.withValues(alpha: 0.82),
              blurRadius: 1.5,
            ),
          ],
          fontFamilyFallback: const <String>[
            'Noto Sans KR',
            'Malgun Gothic',
            'Apple SD Gothic Neo',
            'Arial Unicode MS',
            'sans-serif',
          ],
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 6,
    );
    painter.layout(maxWidth: textRect.width);
    painter.paint(
      canvas,
      Offset(
        textRect.left + (textRect.width - painter.width) / 2,
        textRect.top + (textRect.height - painter.height) / 2,
      ),
    );

    final picture = recorder.endRecording();
    final result = await picture.toImage(image.width, image.height);
    final byteData = await result.toByteData(format: ImageByteFormat.png);
    image.dispose();
    result.dispose();
    return byteData!.buffer.asUint8List();
  }

  Rect _dialogueTextRect({
    required double width,
    required double height,
    required String? prompt,
    required String text,
  }) {
    final value = (prompt ?? '').toLowerCase();
    final candidates = _dialogueTextCandidates(
      width: width,
      height: height,
      text: text,
    );
    return _insetForText(_preferredDialogueCandidate(value, candidates), width);
  }

  List<Rect> _dialogueTextCandidates({
    required double width,
    required double height,
    required String text,
  }) {
    final lengthFactor = (text.length / 42).clamp(0.0, 1.0);
    final bubbleWidth = width * (0.56 + lengthFactor * 0.22);
    final bubbleHeight = height * (0.15 + lengthFactor * 0.13);
    final marginX = width * 0.06;
    final topY = height * 0.045;
    final sideY = height * 0.32;
    final bottomY = height * 0.68;
    return <Rect>[
      Rect.fromLTWH(marginX, topY, bubbleWidth, bubbleHeight),
      Rect.fromLTWH(
        width - bubbleWidth - marginX,
        topY,
        bubbleWidth,
        bubbleHeight,
      ),
      Rect.fromLTWH((width - bubbleWidth) / 2, topY, bubbleWidth, bubbleHeight),
      Rect.fromLTWH(marginX, sideY, bubbleWidth, bubbleHeight),
      Rect.fromLTWH(
        width - bubbleWidth - marginX,
        sideY,
        bubbleWidth,
        bubbleHeight,
      ),
      Rect.fromLTWH(marginX, bottomY, bubbleWidth, bubbleHeight),
      Rect.fromLTWH(
        width - bubbleWidth - marginX,
        bottomY,
        bubbleWidth,
        bubbleHeight,
      ),
      Rect.fromLTWH(
        (width - bubbleWidth) / 2,
        bottomY,
        bubbleWidth,
        bubbleHeight,
      ),
    ];
  }

  Rect _preferredDialogueCandidate(String prompt, List<Rect> candidates) {
    if (prompt.contains('upper_left')) {
      return candidates[0];
    }
    if (prompt.contains('upper_right')) {
      return candidates[1];
    }
    if (prompt.contains('center_top')) {
      return candidates[2];
    }
    if (prompt.contains('left_side')) {
      return candidates[0];
    }
    if (prompt.contains('right_side')) {
      return candidates[1];
    }
    if (prompt.contains('bottom_left')) {
      return candidates[5];
    }
    if (prompt.contains('bottom_right')) {
      return candidates[6];
    }
    return candidates[0];
  }

  Rect _insetForText(Rect bubbleRect, double imageWidth) {
    final horizontalInset = imageWidth * 0.052;
    final verticalInset = imageWidth * 0.026;
    return Rect.fromLTRB(
      bubbleRect.left + horizontalInset,
      bubbleRect.top + verticalInset,
      bubbleRect.right - horizontalInset,
      bubbleRect.bottom - verticalInset,
    );
  }

  Path _dialogueBubbleTail({
    required Rect bubbleRect,
    required String? prompt,
    required double width,
    required double height,
  }) {
    final value = (prompt ?? '').toLowerCase();
    final tailWidth = width * 0.06;
    final tailHeight = height * 0.032;
    final towardRight =
        value.contains('right') || bubbleRect.center.dx < width / 2;
    final anchorX = towardRight
        ? bubbleRect.left + bubbleRect.width * 0.68
        : bubbleRect.left + bubbleRect.width * 0.32;
    final anchorY = bubbleRect.bottom - 1;
    final tipX = towardRight ? anchorX + tailWidth : anchorX - tailWidth;
    final tipY = (anchorY + tailHeight).clamp(0, height - 2).toDouble();

    return Path()
      ..moveTo(anchorX - tailWidth * 0.42, anchorY)
      ..quadraticBezierTo(tipX, tipY, anchorX + tailWidth * 0.42, anchorY)
      ..close();
  }

  String _normalizeDialogueForBubble(String value) {
    final cleaned = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('"', '')
        .replaceAll("'", '')
        .trim();
    return cleaned.replaceAll(RegExp(r'\.{3,}$'), '').trim();
  }

  double _fitDialogueFontSize({
    required String text,
    required double maxWidth,
    required double maxHeight,
    required double imageWidth,
  }) {
    final base = text.length > 42 ? imageWidth * 0.050 : imageWidth * 0.056;
    for (var size = base; size >= imageWidth * 0.026; size -= 0.8) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w900,
            height: 1.18,
            fontFamily: GoogleFonts.notoSansKr().fontFamily,
            fontFamilyFallback: const <String>[
              'Noto Sans KR',
              'Malgun Gothic',
              'Apple SD Gothic Neo',
              'Arial Unicode MS',
              'sans-serif',
            ],
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        maxLines: 6,
      )..layout(maxWidth: maxWidth);
      if (painter.height <= maxHeight && !painter.didExceedMaxLines) {
        return size;
      }
    }
    return imageWidth * 0.026;
  }

  List<String> _keywordTags() {
    return const <String>[];
  }

  List<String> _generationKeywordTags() {
    return <String>[
      ..._keywordTags(),
      if (_targetCutCount > 0) '__cut_count_$_targetCutCount',
    ];
  }

  WebtoonFormat _selectedWebtoonFormat() {
    // The final output always uses the selected card slide format.
    return WebtoonFormat.cardSlide;
  }

  DiaryArtStyle _selectedArtStyle() {
    final template = _selectedStyleTemplate;
    if (template != null) {
      return template.artStyle;
    }
    return switch (_artSubStyle) {
      '\uC560\uB2C8\uD615 (Graphic)' => DiaryArtStyle.animeLd,
      '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615 (Cartoon)' =>
        DiaryArtStyle.comicsSd,
      '\uCE90\uB9AD\uD130\uD615 (Simple Character)' => DiaryArtStyle.simple2d,
      '\uC785\uCCB4 \uB80C\uB354\uB9C1 (3D Style)' => DiaryArtStyle.realistic3d,
      _ => DiaryArtStyle.comicsLd,
    };
  }

  DiaryStyleTemplateModel? get _selectedStyleTemplate {
    for (final template in _styleTemplates) {
      if (template.id == _styleTemplateId) {
        return template;
      }
    }
    return _styleTemplates.isEmpty ? null : _styleTemplates.first;
  }

  DiaryGenre _selectedGenre() {
    return switch (_genre) {
      '\uC9C4\uC9C0\uD558\uACE0 \uCC28\uBD84\uD55C \uB0A0' =>
        DiaryGenre.serious,
      '\uB530\uB73B\uD558\uACE0 \uD589\uBCF5\uD55C \uB0A0' =>
        DiaryGenre.healingRomance,
      '\uBFCC\uB73B\uD558\uACE0 \uC131\uCDE8\uAC10 \uC788\uB294 \uB0A0' =>
        DiaryGenre.growth,
      '\uD798\uB4E4\uACE0 \uC9C0\uCE5C \uB0A0' => DiaryGenre.hardDay,
      _ => DiaryGenre.dailyComic,
    };
  }

  String _selectedGenreSubtype() {
    return switch (_genreSubtype) {
      '' => '',
      '\uC77C\uC0C1' => 'daily',
      '\uAC1C\uADF8' => 'gag',
      '\uB0B4\uBA74' => 'inner',
      '\uC131\uCC30' => 'reflection',
      '\uAC10\uC131' => 'warm_emotion',
      '\uCCAD\uCD98' => 'youth',
      '\uC131\uC7A5' => 'growth',
      '\uC5F4\uC815' => 'passion',
      '\uCE58\uC720' => 'healing',
      '\uACF5\uAC10' => 'empathy',
      _ => _genreSubtype,
    };
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, textAlign: TextAlign.center)),
    );
  }

  List<_FigmaCardData> get _artSubStyleCards {
    return switch (_artStyle) {
      '\uB2E8\uC21C\uD654 \uC2A4\uD0C0\uC77C (SD)' => const <_FigmaCardData>[
        _FigmaCardData(
          '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615 (Cartoon)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uD45C\uC815\uACFC \uB3D9\uC791\uC774 \uD06C\uAC8C \uC77D\uD788\uB294 \uB9CC\uD654\uD615',
        ),
        _FigmaCardData(
          '\uCE90\uB9AD\uD130\uD615 (Simple Character)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uC120\uACFC \uC0C9\uC744 \uB2E8\uC21C\uD654\uD574 \uCE90\uB9AD\uD130\uC131\uC744 \uAC15\uC870',
        ),
      ],
      '\uC785\uCCB4\uD615 \uC2A4\uD0C0\uC77C (3D)' => const <_FigmaCardData>[
        _FigmaCardData(
          '\uC785\uCCB4 \uB80C\uB354\uB9C1 (3D Style)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uC870\uBA85\uACFC \uC7AC\uC9C8\uAC10\uC774 \uC0B4\uC544\uC788\uB294 3D \uB80C\uB354',
        ),
      ],
      _ => const <_FigmaCardData>[
        _FigmaCardData(
          '\uADF9\uD654\uD615 (Semi-Realistic)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uAC10\uC815\uC120\uC740 \uB9CC\uD654\uCC98\uB7FC, \uC7A5\uBA74\uC740 \uB354 \uC12C\uC138\uD558\uAC8C',
        ),
        _FigmaCardData(
          '\uC560\uB2C8\uD615 (Graphic)',
          '\uC608\uC2DC \uC774\uBBF8\uC9C0',
          description:
              '\uC120\uBA85\uD55C \uC120\uACFC \uC0C9\uAC10\uC73C\uB85C \uC6F9\uD230\uCC98\uB7FC',
        ),
      ],
    };
  }

  List<_FigmaCardData> get _genreSubtypeCards {
    return switch (_genre) {
      '\uC9C4\uC9C0\uD558\uACE0 \uCC28\uBD84\uD55C \uB0A0' =>
        const <_FigmaCardData>[
          _FigmaCardData('\uB0B4\uBA74', 'inner'),
          _FigmaCardData('\uC131\uCC30', 'reflect'),
        ],
      '\uB530\uB73B\uD558\uACE0 \uD589\uBCF5\uD55C \uB0A0' =>
        const <_FigmaCardData>[
          _FigmaCardData('\uAC10\uC131', 'warm'),
          _FigmaCardData('\uCCAD\uCD98', 'youth'),
        ],
      '\uBFCC\uB73B\uD558\uACE0 \uC131\uCDE8\uAC10 \uC788\uB294 \uB0A0' =>
        const <_FigmaCardData>[
          _FigmaCardData('\uC131\uC7A5', 'growth'),
          _FigmaCardData('\uC5F4\uC815', 'passion'),
        ],
      '\uD798\uB4E4\uACE0 \uC9C0\uCE5C \uB0A0' => const <_FigmaCardData>[
        _FigmaCardData('\uCE58\uC720', 'heal'),
        _FigmaCardData('\uACF5\uAC10', 'empathy'),
      ],
      _ => const <_FigmaCardData>[
        _FigmaCardData('\uC77C\uC0C1', 'daily'),
        _FigmaCardData('\uAC1C\uADF8', 'gag'),
      ],
    };
  }

  void _selectArtStyle(String value) {
    setState(() {
      _artStyle = value;
      _artSubStyle = _artSubStyleCards.first.label;
    });
  }

  void _selectStyleTemplate(String value) {
    final template = _styleTemplates.firstWhere(
      (DiaryStyleTemplateModel item) => item.id == value,
      orElse: () => _styleTemplates.isEmpty
          ? _fallbackStyleTemplates.first
          : _styleTemplates.first,
    );
    setState(() => _applyStyleTemplate(template));
  }

  void _applyStyleTemplate(DiaryStyleTemplateModel template) {
    _styleTemplateId = template.id;
    _artStyle = _styleNameFromTemplate(template);
    _artSubStyle = template.artSubStyle ?? template.name;
  }

  String _styleNameFromTemplate(DiaryStyleTemplateModel template) {
    return switch (template.artStyle) {
      DiaryArtStyle.realistic3d => '\uC785\uCCB4\uD615 \uC2A4\uD0C0\uC77C (3D)',
      DiaryArtStyle.simple2d ||
      DiaryArtStyle.comicsSd ||
      DiaryArtStyle.animeSd => '\uB2E8\uC21C\uD654 \uC2A4\uD0C0\uC77C (SD)',
      _ => '\uC0AC\uC2E4\uC801 \uC2A4\uD0C0\uC77C (LD)',
    };
  }

  void _selectGenre(String value) {
    setState(() {
      _genre = value;
      _genreSubtype = '';
    });
  }

  void _go(int page) {
    Feedback.forTap(context);
    SystemSound.play(SystemSoundType.click);
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeInOutCubic,
    );
  }
}

class _DiaryFigmaFrame extends StatelessWidget {
  const _DiaryFigmaFrame({
    required this.title,
    required this.child,
    required this.onClose,
    this.pageIndex = 0,
    this.bookChrome = false,
  });

  final String title;
  final int pageIndex;
  final Widget child;
  final VoidCallback onClose;
  final bool bookChrome;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    if (mobile && bookChrome && pageIndex < 0) {
      final pageNumber = (pageIndex + 1).clamp(1, 4);
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFEAF2FF),
              Color(0xFFF7FAFF),
              Color(0xFFDCEAFF),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                top: 14,
                bottom: 94,
                width: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        Color(0xFF7EA4F5),
                        Color(0xFFAFC9FF),
                        Color(0xFFE4EEFF),
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(20),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF7EA4F5).withValues(alpha: 0.28),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 18,
                top: 22,
                bottom: 102,
                width: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                left: 29,
                top: 22,
                bottom: 102,
                width: 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.tacticalBlue.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Positioned(
                right: 2,
                top: 24,
                bottom: 98,
                width: 18,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        const Color(0xFFE8F0FF).withValues(alpha: 0.98),
                        const Color(0xFFBFD3FF).withValues(alpha: 0.92),
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(18),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 7,
                top: 42,
                bottom: 116,
                width: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ),
              Positioned(
                right: 11,
                top: 48,
                bottom: 122,
                width: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.50),
                  ),
                ),
              ),
              Positioned(
                left: 23,
                right: 9,
                top: 0,
                bottom: 86,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E5FF).withValues(alpha: 0.62),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
              ),
              Positioned(
                left: 26,
                right: 9,
                top: 0,
                bottom: 92,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: <Color>[
                        Color(0xFFE9F2FF),
                        Color(0xFFFFFEFF),
                        Color(0xFFF7FAFF),
                      ],
                      stops: <double>[0, 0.16, 1],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFBFD3FF).withValues(alpha: 0.86),
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.tacticalBlue.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 13),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.86),
                        blurRadius: 0,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: <Color>[
                                  const Color(
                                    0xFF8FB3FA,
                                  ).withValues(alpha: 0.28),
                                  const Color(
                                    0xFFDCEAFF,
                                  ).withValues(alpha: 0.22),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 36,
                          right: 16,
                          top: 84,
                          child: Column(
                            children: List<Widget>.generate(
                              7,
                              (int index) => Padding(
                                padding: const EdgeInsets.only(bottom: 33),
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF9EB9F6,
                                    ).withValues(alpha: 0.14),
                                  ),
                                  child: const SizedBox(height: 1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 9,
                          top: 58,
                          bottom: 18,
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF9EB9F6,
                              ).withValues(alpha: 0.20),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 14,
                          top: 64,
                          bottom: 22,
                          width: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF9EB9F6,
                              ).withValues(alpha: 0.12),
                            ),
                          ),
                        ),
                        Column(
                          children: <Widget>[
                            SizedBox(
                              height: 48,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 24,
                                  right: 7,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFCFE0FF),
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              bottom: Radius.circular(7),
                                            ),
                                        border: Border.all(
                                          color: AppTheme.ink.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          8,
                                          6,
                                          8,
                                          7,
                                        ),
                                        child: Text(
                                          'p.$pageNumber',
                                          style: TextStyle(
                                            color: AppTheme.ink.withValues(
                                              alpha: 0.62,
                                            ),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Gap(10),
                                    Expanded(
                                      child: Text(
                                        title,
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppTheme.ink,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (title != '\uC77C\uAE30')
                                      IconButton(
                                        onPressed: onClose,
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 20,
                                        ),
                                        color: AppTheme.ink.withValues(
                                          alpha: 0.62,
                                        ),
                                        tooltip: '\uB2EB\uAE30',
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(child: const SizedBox.shrink()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 32,
                right: 18,
                bottom: 86,
                height: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.66),
                        const Color(0xFFC8D9FF).withValues(alpha: 0.42),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                left: 36,
                right: 18,
                top: 48,
                bottom: 0,
                child: child,
              ),
            ],
          ),
        ),
      );
    }

    if (mobile && bookChrome && pageIndex < 0) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFFF6FAFF),
              Color(0xFFEAF3FF),
              Color(0xFFF9FBFF),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: child,
        ),
      );
    }

    if (!mobile && bookChrome) {
      return _DesktopDiaryBinderFrame(
        title: title,
        pageIndex: pageIndex,
        onClose: onClose,
        child: child,
      );
    }

    if (mobile && bookChrome) {
      return child;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: mobile ? Colors.transparent : const Color(0xFFFBFEFF),
        border: mobile
            ? null
            : Border.all(color: const Color(0xFFD2E3FA), width: 1.8),
        borderRadius: BorderRadius.circular(mobile ? 0 : 8),
        boxShadow: mobile
            ? const <BoxShadow>[]
            : <BoxShadow>[
                BoxShadow(
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.13),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFEAF4FF).withValues(alpha: 0.96),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ],
      ),
      child: Stack(
        children: <Widget>[
          if (!mobile) const Positioned.fill(child: _FigmaPastelWash()),
          if (!mobile)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      Colors.white.withValues(alpha: 0.72),
                      Colors.transparent,
                      const Color(0xFFEAF6FF).withValues(alpha: 0.22),
                    ],
                  ),
                ),
              ),
            ),
          Column(
            children: <Widget>[
              SizedBox(
                height: mobile ? 38 : 42,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: mobile
                              ? Colors.transparent
                              : AppTheme.tacticalBlue,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                          border: mobile
                              ? null
                              : Border(
                                  bottom: BorderSide(
                                    color: AppTheme.tacticalBlue.withValues(
                                      alpha: 0.54,
                                    ),
                                  ),
                                ),
                          boxShadow: mobile
                              ? const <BoxShadow>[]
                              : <BoxShadow>[
                                  BoxShadow(
                                    color: AppTheme.tacticalBlue.withValues(
                                      alpha: 0.20,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                        ),
                      ),
                    ),
                    if (mobile)
                      Positioned(
                        left: 14,
                        right: 14,
                        bottom: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: AppTheme.tacticalBlue.withValues(
                                  alpha: 0.16,
                                ),
                              ),
                            ),
                          ),
                          child: const SizedBox(height: 1),
                        ),
                      ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mobile
                                ? AppTheme.tacticalBlue
                                : Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: mobile ? 13 : null,
                            shadows: const <Shadow>[
                              Shadow(
                                color: Color(0x447890DE),
                                blurRadius: 7,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (title != '\uC77C\uAE30')
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.cancel_rounded),
                          color: mobile ? AppTheme.tacticalBlue : Colors.white,
                          tooltip: '\uB2EB\uAE30',
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopDiaryBinderFrame extends StatelessWidget {
  const _DesktopDiaryBinderFrame({
    required this.title,
    required this.pageIndex,
    required this.onClose,
    required this.child,
  });

  final String title;
  final int pageIndex;
  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFF4F8FF),
            Color(0xFFEAF3FF),
            Color(0xFFF9FBFF),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4FA), width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF7388C4).withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: <Widget>[
            Positioned(
              left: 18,
              right: 18,
              top: 16,
              bottom: 16,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE7F0FF)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.ink.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryOpenPage extends StatelessWidget {
  const _DiaryOpenPage({required this.onArchive, required this.onStart});

  final VoidCallback onArchive;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 14 : 48,
        mobile ? 12 : 28,
        mobile ? 14 : 48,
        mobile ? 12 : 34,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 620;
          final mobileCardHeight = ((constraints.maxHeight - 18) / 2).clamp(
            108.0,
            132.0,
          );
          final cards = <Widget>[
            _FigmaGradientButton(
              title: '\uBCF4\uAD00\uD568',
              subtitle: '\uADF8\uB3D9\uC548\uC758 \uAE30\uB85D',
              colors: const <Color>[Color(0xFFF09AB8), Color(0xFFFFC7B0)],
              icon: Icons.inventory_2_rounded,
              onTap: onArchive,
            ),
            _FigmaGradientButton(
              title: '\uC0C8 \uC77C\uAE30',
              subtitle: '\uC77C\uAE30 \uC791\uC131 \uC2DC\uC791',
              colors: const <Color>[Color(0xFF8FB8F8), Color(0xFF8FE0A1)],
              icon: Icons.edit_note_rounded,
              onTap: onStart,
            ),
          ];

          if (mobile) {
            final gridWidth = min(constraints.maxWidth, 620.0);
            return _DiaryCoverMobile(
              width: gridWidth,
              onStart: onStart,
              onArchive: onArchive,
            );
          }

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: mobile ? mobileCardHeight : 118,
                  child: cards.last,
                ),
                Gap(mobile ? 10 : 12),
                SizedBox(
                  height: mobile ? mobileCardHeight : 118,
                  child: cards.first,
                ),
              ],
            );
          }

          return _DiaryClosedCoverDesktop(
            onStart: onStart,
            onArchive: onArchive,
          );
        },
      ),
    );
  }
}

class _DiaryClosedCoverDesktop extends StatelessWidget {
  const _DiaryClosedCoverDesktop({
    required this.onStart,
    required this.onArchive,
  });

  final VoidCallback onStart;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.62,
        child: _DiaryClosedCover(
          onStart: onStart,
          onArchive: onArchive,
          compact: false,
        ),
      ),
    );
  }
}

class _DiaryClosedCover extends StatelessWidget {
  const _DiaryClosedCover({
    required this.onStart,
    required this.onArchive,
    required this.compact,
  });

  final VoidCallback onStart;
  final VoidCallback onArchive;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(compact ? 22 : 28);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(
          child: ClipRRect(
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Color(0xFFD9E6FF),
                    Color(0xFFC3D6FA),
                    Color(0xFFB4C9EF),
                  ],
                ),
                borderRadius: radius,
                border: Border.all(
                  color: const Color(0xFFF2F7FF).withValues(alpha: 0.98),
                  width: compact ? 1.6 : 2.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.18),
                    blurRadius: compact ? 18 : 30,
                    offset: Offset(0, compact ? 10 : 18),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.54),
                    blurRadius: 0,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  const Positioned.fill(child: _DiaryStripePattern()),
                  Positioned(
                    left: compact ? 52 : 92,
                    right: compact ? 16 : 30,
                    top: compact ? 14 : 22,
                    height: compact ? 34 : 48,
                    child: _DiaryLaceTrim(compact: compact),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: compact ? 16 : 34,
          top: compact ? 18 : 28,
          bottom: compact ? 18 : 28,
          width: compact ? 34 : 64,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF9DB4E2),
              borderRadius: BorderRadius.circular(compact ? 22 : 32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.34)),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.ink.withValues(alpha: 0.16),
                  blurRadius: 16,
                  offset: const Offset(4, 0),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: compact ? 2 : 8,
          top: compact ? 46 : 58,
          bottom: compact ? 46 : 58,
          width: compact ? 74 : 146,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List<Widget>.generate(
              compact ? 5 : 6,
              (int index) => _DiarySpringLoop(compact: compact),
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 58 : 146,
              compact ? 26 : 46,
              compact ? 12 : 52,
              compact ? 24 : 48,
            ),
            child: _DiaryCoverContent(
              compact: compact,
              onArchive: onArchive,
              onStart: onStart,
            ),
          ),
        ),
      ],
    );
  }
}

class _DiarySpringLoop extends StatelessWidget {
  const _DiarySpringLoop({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = compact ? 62.0 : 122.0;
    final height = compact ? 24.0 : 40.0;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.centerLeft,
        children: <Widget>[
          Positioned(
            left: compact ? 17 : 25,
            right: 0,
            child: Container(
              height: compact ? 15 : 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: const Color(0xFFF8FAFF),
                  width: compact ? 4 : 7,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.24),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            child: Container(
              width: compact ? 31 : 43,
              height: compact ? 31 : 43,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: <Color>[
                    Color(0xFFFFFFFF),
                    Color(0xFFE5EAF4),
                    Color(0xFFA8B5CA),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.20),
                    blurRadius: 7,
                    offset: const Offset(1, 3),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: compact ? 8 : 12,
            child: Container(
              width: compact ? 14 : 19,
              height: compact ? 14 : 19,
              decoration: BoxDecoration(
                color: const Color(0xFF9DB4E2),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.ink.withValues(alpha: 0.10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCoverContent extends StatelessWidget {
  const _DiaryCoverContent({
    required this.compact,
    required this.onArchive,
    required this.onStart,
  });

  final bool compact;
  final VoidCallback onArchive;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Align(
          alignment: const Alignment(0.86, -0.88),
          child: _DiaryMoonSticker(compact: compact),
        ),
        Align(
          alignment: const Alignment(-0.86, -0.82),
          child: _DiaryBalloonSticker(compact: compact),
        ),
        Align(
          alignment: const Alignment(0.04, -0.36),
          child: Transform.rotate(
            angle: 0.08,
            child: _DiaryCoverMemoCard(compact: compact),
          ),
        ),
        Align(
          alignment: const Alignment(-0.58, -0.22),
          child: Transform.rotate(
            angle: -0.04,
            child: _DiaryDateLabel(compact: compact),
          ),
        ),
        Align(
          alignment: const Alignment(0.30, -0.02),
          child: Transform.rotate(
            angle: 0.10,
            child: _DiaryPhotoPocket(compact: compact),
          ),
        ),
        Align(
          alignment: const Alignment(-0.16, 0.40),
          child: Transform.rotate(
            angle: -0.07,
            child: _DiaryWashiTape(compact: compact),
          ),
        ),
        Align(
          alignment: const Alignment(-0.66, 0.10),
          child: _DiaryStickerCluster(compact: compact),
        ),
        Align(
          alignment: const Alignment(-0.50, -0.48),
          child: Transform.rotate(
            angle: -0.10,
            child: _DiaryRibbonBow(compact: compact),
          ),
        ),
        Align(
          alignment: const Alignment(0.80, 0.20),
          child: _DiarySoftBadge(
            icon: Icons.favorite_rounded,
            compact: compact,
          ),
        ),
        Column(
          children: <Widget>[
            const Spacer(flex: 1),
            _DiaryCoverTitlePlate(compact: compact),
            SizedBox(height: compact ? 8 : 16),
            Expanded(
              flex: compact ? 6 : 6,
              child: Center(
                child: Opacity(
                  opacity: 0.62,
                  child: Transform.translate(
                    offset: Offset(compact ? 18 : 30, compact ? 18 : 28),
                    child: Transform.scale(
                      scale: compact ? 0.74 : 0.78,
                      child: _DiaryCatSticker(compact: compact),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: compact ? 6 : 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _DiaryCoverActionPill(
                  icon: Icons.inventory_2_rounded,
                  label: '\uBCF4\uAD00\uD568',
                  onTap: onArchive,
                  compact: compact,
                ),
                Gap(compact ? 8 : 18),
                _DiaryCoverActionPill(
                  icon: Icons.edit_note_rounded,
                  label: '\uC0C8 \uC77C\uAE30',
                  onTap: onStart,
                  compact: compact,
                ),
              ],
            ),
            const Spacer(flex: 1),
          ],
        ),
      ],
    );
  }
}

class _DiaryStripePattern extends StatelessWidget {
  const _DiaryStripePattern();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _DiaryStripePainter());
  }
}

class _DiaryLaceTrim extends StatelessWidget {
  const _DiaryLaceTrim({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DiaryLacePainter(compact: compact));
  }
}

class _DiaryCloudSticker extends StatelessWidget {
  const _DiaryCloudSticker({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 120 : 190,
      height: compact ? 78 : 118,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned.fill(
            child: CustomPaint(painter: const _DiaryCloudPainter()),
          ),
          Positioned(
            left: compact ? 22 : 34,
            top: compact ? 25 : 40,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: AppTheme.tacticalBlue.withValues(alpha: 0.68),
              size: compact ? 16 : 22,
            ),
          ),
          Positioned(
            right: compact ? 23 : 38,
            bottom: compact ? 20 : 30,
            child: Icon(
              Icons.star_rounded,
              color: const Color(0xFFFFD86E).withValues(alpha: 0.90),
              size: compact ? 17 : 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCoverTitlePlate extends StatelessWidget {
  const _DiaryCoverTitlePlate({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF8EB9EF), width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.14),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 18 : 30,
          vertical: compact ? 8 : 12,
        ),
        child: Text(
          'Mood diary',
          style: TextStyle(
            color: const Color(0xFF68A3DD),
            fontSize: compact ? 22 : 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
            shadows: <Shadow>[
              Shadow(
                color: Colors.white.withValues(alpha: 0.95),
                blurRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryMoonSticker extends StatelessWidget {
  const _DiaryMoonSticker({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 42.0 : 66.0;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: <Widget>[
          Icon(
            Icons.nightlight_round,
            size: size,
            color: const Color(0xFFFFDF68),
          ),
          Positioned(
            right: 0,
            top: size * 0.08,
            child: Icon(
              Icons.star_rounded,
              size: size * 0.26,
              color: Colors.white.withValues(alpha: 0.94),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryBalloonSticker extends StatelessWidget {
  const _DiaryBalloonSticker({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 58.0;
    return SizedBox(
      width: size,
      height: size * 1.45,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFBFD0).withValues(alpha: 0.78),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: SizedBox(width: size, height: size),
          ),
          Positioned(
            top: size * 0.88,
            child: Container(
              width: 1.4,
              height: size * 0.50,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCoverMemoCard extends StatelessWidget {
  const _DiaryCoverMemoCard({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD5C6B6)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        width: compact ? 78 : 130,
        height: compact ? 54 : 88,
        child: CustomPaint(painter: const _DiaryPaperLinesPainter()),
      ),
    );
  }
}

class _DiaryDateLabel extends StatelessWidget {
  const _DiaryDateLabel({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF).withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: const Color(0xFFB8CDEB), width: 1.2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: compact ? 84 : 134,
        height: compact ? 48 : 72,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            compact ? 9 : 14,
            compact ? 7 : 10,
            compact ? 9 : 14,
            compact ? 7 : 10,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: List<Widget>.generate(
                  4,
                  (int index) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 3 ? 0 : 3),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCEBFF),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: SizedBox(height: compact ? 4 : 6),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'today',
                style: TextStyle(
                  color: const Color(0xFF6B9FD5),
                  fontSize: compact ? 11 : 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              SizedBox(height: compact ? 3 : 5),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: SizedBox(width: compact ? 46 : 72, height: 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryPhotoPocket extends StatelessWidget {
  const _DiaryPhotoPocket({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 74 : 116,
      height: compact ? 64 : 98,
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            top: compact ? 7 : 10,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFEFA).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFD2EA)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.08),
                    blurRadius: 9,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: CustomPaint(painter: const _DiaryPhotoPocketPainter()),
            ),
          ),
          Positioned(
            left: compact ? 12 : 20,
            right: compact ? 12 : 20,
            top: 0,
            height: compact ? 13 : 18,
            child: _DiaryPocketTape(compact: compact),
          ),
        ],
      ),
    );
  }
}

class _DiaryWashiTape extends StatelessWidget {
  const _DiaryWashiTape({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 88 : 138,
      height: compact ? 22 : 34,
      child: CustomPaint(painter: const _DiaryWashiTapePainter()),
    );
  }
}

class _DiaryPocketTape extends StatelessWidget {
  const _DiaryPocketTape({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4ED).withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _DiarySoftBadge extends StatelessWidget {
  const _DiarySoftBadge({required this.icon, required this.compact});

  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 38.0 : 58.0;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBFF),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFC5D6F2)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: size * 0.42,
          color: AppTheme.tacticalBlue.withValues(alpha: 0.64),
        ),
      ),
    );
  }
}

class _DiaryRibbonBow extends StatelessWidget {
  const _DiaryRibbonBow({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 46.0 : 72.0;
    return SizedBox(
      width: size,
      height: size * 0.78,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Transform.rotate(
            angle: -0.46,
            child: _DiaryBowLoop(width: size * 0.48, compact: compact),
          ),
          Transform.rotate(
            angle: 0.46,
            child: _DiaryBowLoop(width: size * 0.48, compact: compact),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFC8D8F2)),
            ),
            child: SizedBox(width: size * 0.18, height: size * 0.18),
          ),
          Positioned(
            left: size * 0.32,
            bottom: 0,
            child: Transform.rotate(
              angle: 0.14,
              child: Container(
                width: size * 0.12,
                height: size * 0.38,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            right: size * 0.32,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.14,
              child: Container(
                width: size * 0.12,
                height: size * 0.38,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E7FF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryBowLoop extends StatelessWidget {
  const _DiaryBowLoop({required this.width, required this.compact});

  final double width;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF).withValues(alpha: 0.92),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(width),
          bottomLeft: Radius.circular(width),
          topRight: Radius.circular(compact ? 6 : 9),
          bottomRight: Radius.circular(compact ? 6 : 9),
        ),
        border: Border.all(color: const Color(0xFFC4D4EE)),
      ),
      child: SizedBox(width: width, height: compact ? 22 : 34),
    );
  }
}

class _DiaryStickerCluster extends StatelessWidget {
  const _DiaryStickerCluster({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 76 : 122,
      height: compact ? 80 : 128,
      child: Stack(
        children: <Widget>[
          Positioned(
            left: 0,
            top: compact ? 8 : 12,
            child: _DiaryRoundSticker(
              color: const Color(0xFFF9FBFF),
              size: compact ? 34 : 52,
              icon: Icons.auto_awesome_rounded,
            ),
          ),
          Positioned(
            right: compact ? 5 : 8,
            top: 0,
            child: _DiaryRoundSticker(
              color: const Color(0xFFDDEAFF),
              size: compact ? 28 : 42,
              icon: Icons.favorite_rounded,
            ),
          ),
          Positioned(
            left: compact ? 22 : 36,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.12,
              child: _DiaryMiniTicket(compact: compact),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryCatSticker extends StatelessWidget {
  const _DiaryCatSticker({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 138.0 : 218.0;
    return SizedBox(
      width: size,
      height: size * 0.82,
      child: CustomPaint(painter: _DiaryCatStickerPainter(compact: compact)),
    );
  }
}

class _DiaryFloppyEar extends StatelessWidget {
  const _DiaryFloppyEar({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF88B8EE), width: 2),
      ),
      child: SizedBox(width: width, height: height),
    );
  }
}

class _DiaryCloudBase extends StatelessWidget {
  const _DiaryCloudBase({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(painter: const _DiaryCloudBasePainter()),
    );
  }
}

class _DiaryCheek extends StatelessWidget {
  const _DiaryCheek({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFBFD0).withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: size, height: size * 0.72),
    );
  }
}

class _DiaryMascotPaw extends StatelessWidget {
  const _DiaryMascotPaw({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF88B8EE), width: 1.5),
      ),
      child: SizedBox(width: size, height: size * 0.86),
    );
  }
}

class _DiaryCatStickerPainter extends CustomPainter {
  const _DiaryCatStickerPainter({required this.compact});

  final bool compact;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final blue = const Color(0xFF7DB5EC);
    final paleBlue = const Color(0xFFEAF5FF);
    final ink = const Color(0xFF5B9FDC);
    final cheek = const Color(0xFFFFBCD1);
    final yellow = const Color(0xFFFFD86E);
    final white = const Color(0xFFFFFEFA);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.13, h * 0.18, w * 0.74, h * 0.70),
        Radius.circular(w * 0.18),
      ),
      Paint()
        ..color = AppTheme.ink.withValues(alpha: 0.10)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final cloud = Path()
      ..moveTo(w * 0.08, h * 0.66)
      ..cubicTo(w * 0.02, h * 0.50, w * 0.17, h * 0.40, w * 0.29, h * 0.47)
      ..cubicTo(w * 0.34, h * 0.28, w * 0.55, h * 0.29, w * 0.60, h * 0.47)
      ..cubicTo(w * 0.74, h * 0.38, w * 0.92, h * 0.48, w * 0.88, h * 0.66)
      ..cubicTo(w * 0.95, h * 0.76, w * 0.82, h * 0.88, w * 0.67, h * 0.82)
      ..cubicTo(w * 0.55, h * 0.95, w * 0.34, h * 0.90, w * 0.31, h * 0.78)
      ..cubicTo(w * 0.20, h * 0.84, w * 0.07, h * 0.78, w * 0.08, h * 0.66)
      ..close();
    final fill = Paint()
      ..color = white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 2.0 : 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(cloud, fill);
    canvas.drawPath(cloud, stroke);

    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.55),
        width: w * 0.28,
        height: h * 0.28,
      ),
      Radius.circular(w * 0.15),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke);

    void drawEar({required Offset center, required bool flip}) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      if (flip) {
        canvas.scale(-1, 1);
      }
      final ear = Path()
        ..moveTo(-w * 0.095, h * 0.055)
        ..cubicTo(-w * 0.078, -h * 0.025, -w * 0.018, -h * 0.085, 0, -h * 0.095)
        ..cubicTo(
          w * 0.022,
          -h * 0.070,
          w * 0.085,
          -h * 0.006,
          w * 0.100,
          h * 0.060,
        )
        ..cubicTo(
          w * 0.050,
          h * 0.040,
          -w * 0.042,
          h * 0.040,
          -w * 0.095,
          h * 0.055,
        )
        ..close();
      canvas.drawPath(ear, fill);
      canvas.drawPath(ear, stroke);
      final inner = Path()
        ..moveTo(-w * 0.040, h * 0.030)
        ..cubicTo(
          -w * 0.025,
          -h * 0.015,
          -w * 0.005,
          -h * 0.038,
          w * 0.010,
          -h * 0.048,
        )
        ..cubicTo(
          w * 0.030,
          -h * 0.020,
          w * 0.052,
          h * 0.012,
          w * 0.058,
          h * 0.036,
        )
        ..close();
      canvas.drawPath(
        inner,
        Paint()..color = const Color(0xFFFFDCE7).withValues(alpha: 0.82),
      );
      canvas.restore();
    }

    drawEar(center: Offset(w * 0.38, h * 0.23), flip: false);
    drawEar(center: Offset(w * 0.62, h * 0.23), flip: true);

    final head = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.34),
        width: w * 0.40,
        height: h * 0.34,
      ),
      Radius.circular(w * 0.17),
    );
    canvas.drawRRect(head, fill);
    canvas.drawRRect(head, stroke);

    final blushPaint = Paint()
      ..color = cheek.withValues(alpha: 0.76)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.39, h * 0.38),
        width: w * 0.07,
        height: h * 0.045,
      ),
      blushPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.61, h * 0.38),
        width: w * 0.07,
        height: h * 0.045,
      ),
      blushPaint,
    );

    final facePaint = Paint()
      ..color = ink
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.43, h * 0.32), w * 0.018, facePaint);
    canvas.drawCircle(Offset(w * 0.57, h * 0.32), w * 0.018, facePaint);

    final mouthPaint = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = compact ? 1.8 : 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final nosePaint = Paint()
      ..color = ink
      ..style = PaintingStyle.fill;
    final nose = Path()
      ..moveTo(w * 0.50, h * 0.354)
      ..lineTo(w * 0.478, h * 0.372)
      ..quadraticBezierTo(w * 0.50, h * 0.389, w * 0.522, h * 0.372)
      ..close();
    canvas.drawPath(nose, nosePaint);
    canvas.drawLine(
      Offset(w * 0.50, h * 0.382),
      Offset(w * 0.50, h * 0.410),
      mouthPaint,
    );
    final leftMouth = Path()
      ..moveTo(w * 0.50, h * 0.410)
      ..cubicTo(
        w * 0.488,
        h * 0.438,
        w * 0.452,
        h * 0.434,
        w * 0.444,
        h * 0.402,
      );
    final rightMouth = Path()
      ..moveTo(w * 0.50, h * 0.410)
      ..cubicTo(
        w * 0.512,
        h * 0.438,
        w * 0.548,
        h * 0.434,
        w * 0.556,
        h * 0.402,
      );
    canvas.drawPath(leftMouth, mouthPaint);
    canvas.drawPath(rightMouth, mouthPaint);

    for (final center in <Offset>[
      Offset(w * 0.38, h * 0.56),
      Offset(w * 0.62, h * 0.56),
    ]) {
      final paw = Rect.fromCenter(
        center: center,
        width: w * 0.085,
        height: h * 0.11,
      );
      canvas.drawOval(paw, fill);
      canvas.drawOval(paw, stroke);
    }

    final starPath = Path()
      ..moveTo(w * 0.50, h * 0.47)
      ..lineTo(w * 0.535, h * 0.535)
      ..lineTo(w * 0.61, h * 0.545)
      ..lineTo(w * 0.555, h * 0.595)
      ..lineTo(w * 0.57, h * 0.67)
      ..lineTo(w * 0.50, h * 0.635)
      ..lineTo(w * 0.43, h * 0.67)
      ..lineTo(w * 0.445, h * 0.595)
      ..lineTo(w * 0.39, h * 0.545)
      ..lineTo(w * 0.465, h * 0.535)
      ..close();
    canvas.drawPath(starPath, Paint()..color = yellow);
    canvas.drawPath(
      starPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.86)
        ..style = PaintingStyle.stroke
        ..strokeWidth = compact ? 1.0 : 1.4,
    );

    _drawSparkle(
      canvas,
      Offset(w * 0.23, h * 0.62),
      w * 0.035,
      Paint()..color = paleBlue,
    );
    _drawSparkle(
      canvas,
      Offset(w * 0.76, h * 0.60),
      w * 0.028,
      Paint()..color = paleBlue,
    );
    _drawSparkle(
      canvas,
      Offset(w * 0.72, h * 0.76),
      w * 0.025,
      Paint()..color = yellow,
    );
  }

  @override
  bool shouldRepaint(covariant _DiaryCatStickerPainter oldDelegate) {
    return oldDelegate.compact != compact;
  }
}

class _DiaryCatEar extends StatelessWidget {
  const _DiaryCatEar({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: const _DiaryCatEarPainter(),
    );
  }
}

class _DiaryCatEye extends StatelessWidget {
  const _DiaryCatEye({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.ink.withValues(alpha: 0.72),
        shape: BoxShape.circle,
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _DiaryWhiskers extends StatelessWidget {
  const _DiaryWhiskers({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: width * 0.34,
      child: CustomPaint(painter: const _DiaryWhiskerPainter()),
    );
  }
}

class _DiaryRoundSticker extends StatelessWidget {
  const _DiaryRoundSticker({
    required this.color,
    required this.size,
    required this.icon,
  });

  final Color color;
  final double size;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Icon(
          icon,
          size: size * 0.46,
          color: AppTheme.tacticalBlue.withValues(alpha: 0.70),
        ),
      ),
    );
  }
}

class _DiaryMiniTicket extends StatelessWidget {
  const _DiaryMiniTicket({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDF7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB9CBE9)),
      ),
      child: SizedBox(
        width: compact ? 48 : 74,
        height: compact ? 22 : 32,
        child: Center(
          child: Container(
            width: compact ? 22 : 36,
            height: 2,
            color: const Color(0xFFC8D8F2),
          ),
        ),
      ),
    );
  }
}

class _DiaryPressedFlower extends StatelessWidget {
  const _DiaryPressedFlower({required this.color, required this.compact});

  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: compact ? 42 : 68,
      height: compact ? 76 : 120,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: <Widget>[
          Positioned(
            bottom: 0,
            child: Container(
              width: 2,
              height: compact ? 56 : 92,
              color: color.withValues(alpha: 0.56),
            ),
          ),
          for (var index = 0; index < 5; index++)
            Positioned(
              bottom: compact ? 17.0 + index * 8 : 26.0 + index * 13,
              left: index.isEven ? (compact ? 12 : 18) : (compact ? 21 : 34),
              child: Transform.rotate(
                angle: index.isEven ? -0.62 : 0.62,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.32),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: SizedBox(
                    width: compact ? 20 : 32,
                    height: compact ? 8 : 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DiaryCoverActionPill extends StatelessWidget {
  const _DiaryCoverActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final maxLabelWidth = compact ? 56.0 : 96.0;
    return _PressableScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF6FAFF),
          borderRadius: BorderRadius.circular(compact ? 9 : 10),
          border: Border.all(color: const Color(0xFF9FB9E6), width: 1.2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.80),
              blurRadius: 0,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 17,
            vertical: compact ? 7 : 11,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: AppTheme.tacticalBlue, size: compact ? 15 : 20),
              Gap(compact ? 4 : 7),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxLabelWidth),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink,
                    fontSize: compact ? 11 : 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiaryPageStamp extends StatelessWidget {
  const _DiaryPageStamp({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFFFF2F6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE9B5C6)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Icon(icon, color: const Color(0xFFD783A5), size: 20),
          ),
        ),
        const Gap(10),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.64),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _DiaryHandNote extends StatelessWidget {
  const _DiaryHandNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6CC).withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEDC8A)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.72),
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1.28,
          ),
        ),
      ),
    );
  }
}

class _DiaryCoverMobile extends StatelessWidget {
  const _DiaryCoverMobile({
    required this.width,
    required this.onStart,
    required this.onArchive,
  });

  final double width;
  final VoidCallback onStart;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final size = _mobileDiaryBookSize(context, width);
    return Center(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: _DiaryClosedCover(
          onStart: onStart,
          onArchive: onArchive,
          compact: true,
        ),
      ),
    );
  }
}

Size _mobileDiaryBookSize(BuildContext context, double availableWidth) {
  final screenSize = MediaQuery.sizeOf(context);
  final screenWidth = screenSize.width;
  final screenHeight = screenSize.height;
  final bookWidth = min(max(availableWidth, 290.0), screenWidth - 36);
  final maxBookHeight = max(360.0, screenHeight - 96);
  final bookHeight = min(maxBookHeight, max(430.0, bookWidth * 1.48));
  return Size(bookWidth, bookHeight);
}

class _DiaryCoverActionCard extends StatelessWidget {
  const _DiaryCoverActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.paperColor,
    required this.stickerColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color paperColor;
  final Color stickerColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            top: 8,
            left: 6,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: paperColor.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.38),
                  width: 1.2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.tacticalBlue.withValues(alpha: 0.14),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  Positioned(
                    left: 11,
                    right: 11,
                    top: 44,
                    child: Column(
                      children: List<Widget>.generate(
                        4,
                        (int index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.14),
                            ),
                            child: const SizedBox(height: 1),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 9,
                    top: 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: stickerColor.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.80),
                        ),
                      ),
                      child: const SizedBox(width: 18, height: 18),
                    ),
                  ),
                  Positioned(
                    right: 9,
                    top: 9,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: accentColor.withValues(alpha: 0.72),
                    ),
                  ),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 24, 10, 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.16),
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(9),
                              child: Icon(
                                icon,
                                size: 24,
                                color: AppTheme.tacticalBlue.withValues(
                                  alpha: 0.72,
                                ),
                              ),
                            ),
                          ),
                          const Gap(14),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.tacticalBlue,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Gap(8),
                          Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.72,
                              ),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              height: 1.24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: -10,
            child: Transform.rotate(
              angle: -0.03,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.42),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.70),
                  ),
                ),
                child: const SizedBox(height: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryBinderHole extends StatelessWidget {
  const _DiaryBinderHole();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.14),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.10),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        width: 13,
        height: 13,
        child: Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.tacticalBlue.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const SizedBox(width: 5, height: 5),
          ),
        ),
      ),
    );
  }
}

class _DiaryMiniMemo extends StatelessWidget {
  const _DiaryMiniMemo();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D8).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List<Widget>.generate(
            3,
            (int index) => Padding(
              padding: EdgeInsets.only(bottom: index == 2 ? 0 : 5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.18),
                ),
                child: SizedBox(width: index == 2 ? 28 : 42, height: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DiaryTapeStrip extends StatelessWidget {
  const _DiaryTapeStrip({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
      ),
      child: SizedBox(width: width, height: 20),
    );
  }
}

class _DiaryStickerDot extends StatelessWidget {
  const _DiaryStickerDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.86),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
      ),
      child: SizedBox(width: size, height: size),
    );
  }
}

class _DiaryStickerStar extends StatelessWidget {
  const _DiaryStickerStar();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      size: 24,
      color: const Color(0xFFFFD36A).withValues(alpha: 0.92),
    );
  }
}

class _DiaryWriteScreen extends StatelessWidget {
  const _DiaryWriteScreen({
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.weather,
    required this.onWeatherChanged,
    required this.onBack,
    required this.onNext,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String weather;
  final ValueChanged<String> onWeatherChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 7 : 16,
        mobile ? 7 : 10,
        mobile ? 7 : 16,
        mobile ? 7 : 12,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compact = constraints.maxWidth < 760;
          final contentWidth = constraints.maxWidth > 1540
              ? 1540.0
              : constraints.maxWidth;

          return Column(
            children: <Widget>[
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: contentWidth,
                    child: compact
                        ? Column(
                            children: <Widget>[
                              Expanded(
                                child: _DiaryLogPanel(
                                  titleController: titleController,
                                  bodyController: bodyController,
                                ),
                              ),
                              Gap(mobile ? 8 : 12),
                              SizedBox(
                                height: mobile ? 194 : 330,
                                child: _DiaryMetaPanel(
                                  tagController: tagController,
                                  weather: weather,
                                  onWeatherChanged: onWeatherChanged,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Expanded(
                                flex: 8,
                                child: _DiaryLogPanel(
                                  titleController: titleController,
                                  bodyController: bodyController,
                                ),
                              ),
                              const Gap(28),
                              Expanded(
                                flex: 5,
                                child: _DiaryMetaPanel(
                                  tagController: tagController,
                                  weather: weather,
                                  onWeatherChanged: onWeatherChanged,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const Gap(8),
              Center(
                child: SizedBox(
                  width: contentWidth,
                  child: _DiaryWriteFooter(onBack: onBack, onNext: onNext),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiaryLogPanel extends StatelessWidget {
  const _DiaryLogPanel({
    required this.titleController,
    required this.bodyController,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;

  @override
  Widget build(BuildContext context) {
    return _RaisedDiaryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const _FigmaTinyTag(text: 'DIARY LOG'),
          const Gap(10),
          TextField(
            controller: titleController,
            textAlign: TextAlign.center,
            decoration: _figmaField(
              '\uC791\uD488 \uC81C\uBAA9\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694',
            ),
          ),
          const Gap(10),
          Expanded(
            child: TextField(
              controller: bodyController,
              expands: true,
              maxLines: null,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.top,
              decoration: _figmaField(
                '\uC624\uB298\uC758 \uC7A5\uBA74\uC740 50\uAE00\uC790 \uC774\uC0C1\uC5D0 \uAC10\uC815\uD45C\uD604\uC744 2\uAC1C \uC774\uC0C1 \uC11E\uC5B4\uC918\uC57C \uD6A8\uACFC\uC801\uC785\uB2C8\uB2E4.',
              ).copyWith(contentPadding: const EdgeInsets.all(16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryMetaPanel extends StatelessWidget {
  const _DiaryMetaPanel({
    required this.tagController,
    required this.weather,
    required this.onWeatherChanged,
  });

  final TextEditingController tagController;
  final String weather;
  final ValueChanged<String> onWeatherChanged;

  @override
  Widget build(BuildContext context) {
    return _RaisedDiaryPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          const _FigmaTinyTag(text: 'SCENE META'),
          const Gap(10),
          _WeatherIconSelector(selected: weather, onChanged: onWeatherChanged),
          const Gap(8),
          Expanded(
            child: TextField(
              controller: tagController,
              expands: true,
              maxLines: null,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.top,
              decoration: _figmaField(
                '\uD504\uB86C\uD504\uD2B8 \uACE0\uC815 \uD0A4\uC6CC\uB4DC',
              ).copyWith(contentPadding: const EdgeInsets.all(16)),
            ),
          ),
          const Gap(8),
          SizedBox(
            height: 44,
            child: Center(
              child: Text(
                '\uC5EC\uAE30\uC5D0 \uC801\uC740 \uB2E8\uC5B4\uB294 \uD53C\uB4DC \uD0DC\uADF8\uAC00 \uC544\uB2C8\uB77C AI\uAC00 \uAF2D \uBC18\uC601\uD574\uC57C \uD560 \uC694\uC18C\uC785\uB2C8\uB2E4.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5B7FB7).withValues(alpha: 0.82),
                  height: 1.25,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiaryWriteFooter extends StatelessWidget {
  const _DiaryWriteFooter({required this.onBack, required this.onNext});

  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: <Widget>[
          _FigmaBackButton(onTap: onBack),
          const Spacer(),
          _FigmaNextButton(onTap: onNext),
        ],
      ),
    );
  }
}

class _FigmaBackButton extends StatefulWidget {
  const _FigmaBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_FigmaBackButton> createState() => _FigmaBackButtonState();
}

class _FigmaBackButtonState extends State<_FigmaBackButton> {
  @override
  Widget build(BuildContext context) {
    return _FigmaMotionButton(
      label: '\uC774\uC804',
      icon: Icons.arrow_back_ios_new_rounded,
      onTap: widget.onTap,
      filled: false,
      iconOnRight: false,
    );
  }
}

class _FigmaNextButton extends StatelessWidget {
  const _FigmaNextButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FigmaMotionButton(
      label: '\uB2E4\uC74C',
      icon: Icons.arrow_forward_rounded,
      onTap: onTap,
      filled: true,
      iconOnRight: true,
    );
  }
}

class _FigmaSkipButton extends StatelessWidget {
  const _FigmaSkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FigmaMotionButton(
      label: '\uAC74\uB108\uB6F0\uAE30',
      icon: Icons.double_arrow_rounded,
      onTap: onTap,
      filled: false,
      iconOnRight: true,
    );
  }
}

class _FigmaMotionButton extends StatefulWidget {
  const _FigmaMotionButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.filled,
    required this.iconOnRight,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;
  final bool iconOnRight;

  @override
  State<_FigmaMotionButton> createState() => _FigmaMotionButtonState();
}

class _FigmaMotionButtonState extends State<_FigmaMotionButton> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _pressed || _hovered;
    final foreground = widget.filled
        ? Colors.white
        : (isActive ? const Color(0xFF5F82D9) : const Color(0xFF7897DF));
    final background = widget.filled
        ? (isActive ? const Color(0xFF83A4EF) : const Color(0xFF9AB3F3))
        : Colors.white.withValues(alpha: _pressed ? 0.96 : 0.9);
    final iconOffset = widget.iconOnRight
        ? (_pressed
              ? const Offset(0.08, 0)
              : (_hovered ? const Offset(0.04, 0) : Offset.zero))
        : (_pressed
              ? const Offset(-0.08, 0)
              : (_hovered ? const Offset(-0.04, 0) : Offset.zero));

    final icon = AnimatedSlide(
      offset: iconOffset,
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: widget.filled
              ? Colors.white.withValues(alpha: 0.2)
              : const Color(0xFFEAF2FF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.filled
                ? Colors.white.withValues(alpha: 0.45)
                : const Color(0xFFB9CCFA),
            width: 1.2,
          ),
        ),
        child: Icon(widget.icon, size: 18, color: foreground),
      ),
    );

    final label = Text(
      widget.label,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: foreground,
        fontWeight: FontWeight.w900,
        fontSize: 16,
        height: 1,
      ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          Feedback.forTap(context);
          SystemSound.play(SystemSoundType.click);
          widget.onTap();
        },
        child: AnimatedScale(
          scale: _pressed ? 0.955 : (_hovered ? 1.025 : 1),
          duration: const Duration(milliseconds: 150),
          curve: _pressed ? Curves.easeOutCubic : Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            height: 52,
            constraints: const BoxConstraints(minWidth: 126),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: background,
              border: Border.all(
                color: widget.filled
                    ? Colors.white.withValues(alpha: 0.72)
                    : (isActive
                          ? const Color(0xFF7FA4F2)
                          : const Color(0xFF9CB7F0)),
                width: isActive ? 2 : 1.5,
              ),
              borderRadius: BorderRadius.circular(999),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color:
                      (widget.filled
                              ? const Color(0xFF6F8FE2)
                              : const Color(0xFF83A5F2))
                          .withValues(alpha: _pressed ? 0.14 : 0.25),
                  blurRadius: _pressed ? 8 : 18,
                  offset: _pressed ? const Offset(0, 3) : const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(
                    alpha: widget.filled ? 0.36 : 0.95,
                  ),
                  blurRadius: 0,
                  spreadRadius: 2,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.iconOnRight
                  ? <Widget>[label, const Gap(8), icon]
                  : <Widget>[icon, const Gap(8), label],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeatherIconSelector extends StatelessWidget {
  const _WeatherIconSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  static const List<_WeatherOption> _options = <_WeatherOption>[
    _WeatherOption('sunny', Icons.wb_sunny_rounded, '\uB9D1\uC74C'),
    _WeatherOption('cloudy', Icons.cloud_rounded, '\uD750\uB9BC'),
    _WeatherOption('rainy', Icons.grain_rounded, '\uBE44'),
    _WeatherOption('snowy', Icons.ac_unit_rounded, '\uB208'),
    _WeatherOption('foggy', Icons.foggy, '\uC548\uAC1C'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        const _FigmaTinyTag(text: '\uB0A0\uC528'),
        const Gap(8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _options.map((_WeatherOption option) {
            final isSelected = selected == option.value;
            return Tooltip(
              message: option.label,
              child: _PressableScale(
                onTap: () => onChanged(option.value),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEAF3FF)
                        : Colors.white.withValues(alpha: 0.84),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8EAEEB)
                          : const Color(0xFFC3DAFF),
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 46,
                    height: 42,
                    child: Icon(
                      option.icon,
                      color: isSelected ? const Color(0xFF6F92DA) : null,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _WeatherOption {
  const _WeatherOption(this.value, this.icon, this.label);

  final String value;
  final IconData icon;
  final String label;
}

class _DiaryTagScreen extends StatelessWidget {
  const _DiaryTagScreen({
    required this.topLabel,
    required this.bottomLabel,
    required this.cards,
    required this.onBack,
    required this.onNext,
    this.onSelected,
    this.showSkip = false,
  });

  final String topLabel;
  final String bottomLabel;
  final List<_FigmaCardData> cards;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final ValueChanged<String>? onSelected;
  final bool showSkip;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 8 : 28,
        mobile ? 8 : 8,
        mobile ? 8 : 28,
        mobile ? 10 : 14,
      ),
      child: Column(
        children: <Widget>[
          _FigmaPill(text: topLabel),
          Gap(mobile ? 10 : 16),
          Expanded(
            child: mobile
                ? GridView.builder(
                    padding: EdgeInsets.zero,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.88,
                        ),
                    itemCount: cards.length,
                    itemBuilder: (BuildContext context, int index) {
                      final data = cards[index];
                      return _PressableScale(
                        onTap: () {
                          onSelected?.call(data.label);
                          onNext();
                        },
                        child: _FigmaEmptyCard(data: data),
                      );
                    },
                  )
                : Row(
                    children: cards.map((_FigmaCardData data) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: _PressableScale(
                            onTap: () {
                              onSelected?.call(data.label);
                              onNext();
                            },
                            child: _FigmaEmptyCard(data: data),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          Gap(mobile ? 6 : 8),
          Row(
            children: <Widget>[
              _FigmaBackButton(onTap: onBack),
              const Gap(8),
              Expanded(
                child: Center(child: _FigmaTinyTag(text: bottomLabel)),
              ),
              if (showSkip)
                _FigmaSkipButton(onTap: onNext)
              else
                const SizedBox(width: 126),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiaryFinalScreen extends StatelessWidget {
  const _DiaryFinalScreen({
    super.key,
    required this.templates,
    required this.selectedPersonaId,
    required this.personas,
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.titleText,
    required this.weather,
    required this.artStyle,
    required this.artSubStyle,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.targetCutCount,
    required this.artSubStyleOptions,
    required this.genreSubtypeOptions,
    required this.keywordTags,
    required this.isSaving,
    required this.onArtStyleChanged,
    required this.onArtSubStyleChanged,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onTargetCutCountChanged,
    required this.onTemplateChanged,
    required this.onGenerate,
    required this.onBack,
    required this.isLoadingTemplates,
    required this.previewImageUrls,
    required this.onDraftChanged,
    required this.onWeatherChanged,
  });

  final List<String> templates;
  final String selectedPersonaId;
  final List<PersonaModel> personas;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String titleText;
  final String weather;
  final String artStyle;
  final String artSubStyle;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final int targetCutCount;
  final List<String> artSubStyleOptions;
  final List<String> genreSubtypeOptions;
  final List<String> keywordTags;
  final bool isSaving;
  final bool isLoadingTemplates;
  final List<String> previewImageUrls;
  final ValueChanged<String> onArtStyleChanged;
  final ValueChanged<String> onArtSubStyleChanged;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final ValueChanged<int> onTargetCutCountChanged;
  final ValueChanged<String> onTemplateChanged;
  final VoidCallback onDraftChanged;
  final ValueChanged<String> onWeatherChanged;
  final VoidCallback onGenerate;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final hasTemplates = templates.isNotEmpty;
    final mobile = _isMobileLayout(context);

    if (mobile) {
      return _FinalMobilePager(
        hasTemplates: hasTemplates,
        selectedPersonaId: selectedPersonaId,
        personas: personas,
        titleController: titleController,
        bodyController: bodyController,
        tagController: tagController,
        weather: weather,
        selectedStyleTemplateId: selectedStyleTemplateId,
        styleTemplates: styleTemplates,
        genre: genre,
        genreSubtype: genreSubtype,
        targetCutCount: targetCutCount,
        genreSubtypeOptions: genreSubtypeOptions,
        keywordTags: keywordTags,
        isSaving: isSaving,
        isLoadingTemplates: isLoadingTemplates,
        previewImageUrls: previewImageUrls,
        onWeatherChanged: onWeatherChanged,
        onStyleTemplateChanged: onStyleTemplateChanged,
        onGenreChanged: onGenreChanged,
        onGenreSubtypeChanged: onGenreSubtypeChanged,
        onTargetCutCountChanged: onTargetCutCountChanged,
        onTemplateChanged: onTemplateChanged,
        onDraftChanged: onDraftChanged,
        onGenerate: onGenerate,
        onBack: onBack,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 8 : 28,
        mobile ? 8 : 8,
        mobile ? 8 : 28,
        mobile ? 10 : 14,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final canvasWidth = 1480.0;
          final canvasHeight = 650.0;

          return Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: Column(
                  children: <Widget>[
                    const _FigmaPill(
                      text: '\uC77C\uAE30 \uCD5C\uC885 \uC124\uC815',
                    ),
                    const Gap(12),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Expanded(
                            flex: 7,
                            child: _FinalGlassPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  _FinalSummaryStrip(
                                    titleText: titleController.text,
                                    weather: weather,
                                    artStyle: artStyle,
                                    artSubStyle: artSubStyle,
                                    selectedStyleTemplateId:
                                        selectedStyleTemplateId,
                                    styleTemplates: styleTemplates,
                                    genre: genre,
                                    genreSubtype: genreSubtype,
                                    keywordCount: keywordTags.length,
                                  ),
                                  const Gap(14),
                                  Expanded(
                                    child: _FinalLiveDiaryEditor(
                                      titleController: titleController,
                                      bodyController: bodyController,
                                      tagController: tagController,
                                      weather: weather,
                                      artStyle: artStyle,
                                      artSubStyle: artSubStyle,
                                      selectedStyleTemplateId:
                                          selectedStyleTemplateId,
                                      styleTemplates: styleTemplates,
                                      genre: genre,
                                      genreSubtype: genreSubtype,
                                      artSubStyleOptions: artSubStyleOptions,
                                      genreSubtypeOptions: genreSubtypeOptions,
                                      onWeatherChanged: onWeatherChanged,
                                      onArtStyleChanged: onArtStyleChanged,
                                      onArtSubStyleChanged:
                                          onArtSubStyleChanged,
                                      onStyleTemplateChanged:
                                          onStyleTemplateChanged,
                                      onGenreChanged: onGenreChanged,
                                      onGenreSubtypeChanged:
                                          onGenreSubtypeChanged,
                                      onChanged: onDraftChanged,
                                      mobile: false,
                                    ),
                                  ),
                                  const Gap(14),
                                  _DiaryFinalActionBar(
                                    hasTemplates: hasTemplates,
                                    isSaving: isSaving,
                                    onBack: onBack,
                                    onGenerate: onGenerate,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const Gap(18),
                          Expanded(
                            flex: 5,
                            child: _FinalGlassPanel(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: <Widget>[
                                  Expanded(
                                    child: _TemplateChoiceSelector(
                                      selectedPersonaId: selectedPersonaId,
                                      personas: personas,
                                      onChanged: onTemplateChanged,
                                      isLoading: isLoadingTemplates,
                                    ),
                                  ),
                                  const Gap(14),
                                  SizedBox(
                                    height: 184,
                                    child: _DiaryWebtoonPreviewCard(
                                      imageUrls: previewImageUrls,
                                      isLoading: isSaving,
                                      title: titleController.text,
                                      body: bodyController.text,
                                      weather: weather,
                                      genre: genre,
                                      genreSubtype: genreSubtype,
                                      keywordTags: keywordTags,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FinalGlassPanel extends StatelessWidget {
  const _FinalGlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFA).withValues(alpha: 0.96),
        border: Border.all(color: const Color(0xFFB9CDEB), width: 1.6),
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.10),
            blurRadius: 18,
            offset: const Offset(0, 9),
          ),
          BoxShadow(
            color: const Color(0xFFEAF3FF).withValues(alpha: 0.70),
            blurRadius: 0,
            spreadRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: const _DiaryPaperLinesPainter()),
            ),
            Padding(padding: const EdgeInsets.all(20), child: child),
          ],
        ),
      ),
    );
  }
}

class _FinalSummaryStrip extends StatelessWidget {
  const _FinalSummaryStrip({
    required this.titleText,
    required this.weather,
    required this.artStyle,
    required this.artSubStyle,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.keywordCount,
  });

  final String titleText;
  final String weather;
  final String artStyle;
  final String artSubStyle;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final int keywordCount;

  @override
  Widget build(BuildContext context) {
    final title = titleText.trim().isEmpty
        ? '\uC81C\uBAA9 \uC5C6\uC74C'
        : titleText.trim();
    final selectedTemplate = styleTemplates.where(
      (DiaryStyleTemplateModel item) => item.id == selectedStyleTemplateId,
    );
    final templateName = selectedTemplate.isEmpty
        ? artSubStyle
        : selectedTemplate.first.name;
    final details = <String>[
      _weatherLabel(weather),
      '\uD15C\uD50C\uB9BF: $templateName',
      '$genre / $genreSubtype',
      if (keywordCount > 0) '\uD0A4\uC6CC\uB4DC $keywordCount\uAC1C',
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF).withValues(alpha: 0.96),
        border: Border.all(color: const Color(0xFFAFC5EA), width: 1.2),
        borderRadius: BorderRadius.circular(10),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.auto_stories_rounded,
                  color: Color(0xFF6EA3FF),
                  size: 22,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: details.map((String item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.42),
                    ),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(
                      color: AppTheme.ink.withValues(alpha: 0.86),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalPublishHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.pastelBlue.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.tacticalBlue,
              size: 20,
            ),
            Gap(8),
            Expanded(
              child: Text(
                '\uACF5\uAC1C \uBC94\uC704\uC640 \uC18C\uC7A5 \uC704\uCE58\uB294 \uCD5C\uC885 \uBC1C\uD589\uD560 \uB54C \uC120\uD0DD\uD574\uC694.',
                style: TextStyle(
                  color: AppTheme.tacticalBlue,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalMobilePager extends StatefulWidget {
  const _FinalMobilePager({
    required this.hasTemplates,
    required this.selectedPersonaId,
    required this.personas,
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.weather,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.targetCutCount,
    required this.genreSubtypeOptions,
    required this.keywordTags,
    required this.isSaving,
    required this.isLoadingTemplates,
    required this.previewImageUrls,
    required this.onWeatherChanged,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onTargetCutCountChanged,
    required this.onTemplateChanged,
    required this.onDraftChanged,
    required this.onGenerate,
    required this.onBack,
  });

  final bool hasTemplates;
  final String selectedPersonaId;
  final List<PersonaModel> personas;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String weather;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final int targetCutCount;
  final List<String> genreSubtypeOptions;
  final List<String> keywordTags;
  final bool isSaving;
  final bool isLoadingTemplates;
  final List<String> previewImageUrls;
  final ValueChanged<String> onWeatherChanged;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final ValueChanged<int> onTargetCutCountChanged;
  final ValueChanged<String> onTemplateChanged;
  final VoidCallback onDraftChanged;
  final VoidCallback onGenerate;
  final VoidCallback onBack;

  @override
  State<_FinalMobilePager> createState() => _FinalMobilePagerState();
}

class _FinalMobilePagerState extends State<_FinalMobilePager> {
  int _step = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _turnTo(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = widget.hasTemplates && !widget.isSaving;
    PersonaModel? selectedPersona;
    for (final persona in widget.personas) {
      if (persona.id == widget.selectedPersonaId) {
        selectedPersona = persona;
        break;
      }
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final bookSize = _mobileDiaryBookSize(context, availableWidth);
        return Center(
          child: SizedBox(
            width: bookSize.width,
            height: bookSize.height,
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (BuildContext context, Widget? child) {
                final page = _pageController.hasClients
                    ? (_pageController.page ?? _step.toDouble())
                    : _step.toDouble();
                return _DiaryWritingBookFrame(
                  page: page,
                  step: _step,
                  isSaving: widget.isSaving,
                  canPublish: canPublish,
                  onBack: _step == 0
                      ? widget.onBack
                      : () {
                          _turnTo(0);
                        },
                  onNext: _step == 0
                      ? () {
                          _turnTo(1);
                        }
                      : widget.onGenerate,
                  child: child!,
                );
              },
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) => setState(() => _step = page),
                children: <Widget>[
                  _DiaryTurningPage(
                    controller: _pageController,
                    index: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
                      child: _FinalMobileDiaryStep(
                        key: const ValueKey<String>('final-diary-step'),
                        titleController: widget.titleController,
                        bodyController: widget.bodyController,
                        weather: widget.weather,
                        selectedPersonaId: widget.selectedPersonaId,
                        personas: widget.personas,
                        isLoadingTemplates: widget.isLoadingTemplates,
                        onWeatherChanged: widget.onWeatherChanged,
                        onTemplateChanged: widget.onTemplateChanged,
                        onChanged: widget.onDraftChanged,
                      ),
                    ),
                  ),
                  _DiaryTurningPage(
                    controller: _pageController,
                    index: 1,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 14, 16),
                      child: _FinalMobileSceneStep(
                        key: const ValueKey<String>('final-scene-step'),
                        title: widget.titleController.text,
                        body: widget.bodyController.text,
                        weather: widget.weather,
                        selectedStyleTemplateId: widget.selectedStyleTemplateId,
                        styleTemplates: widget.styleTemplates,
                        genre: widget.genre,
                        genreSubtype: widget.genreSubtype,
                        targetCutCount: widget.targetCutCount,
                        genreSubtypeOptions: widget.genreSubtypeOptions,
                        keywordTags: widget.keywordTags,
                        isSaving: widget.isSaving,
                        previewImageUrls: widget.previewImageUrls,
                        previewPersonaName: selectedPersona?.name,
                        previewPersonaImageUrl:
                            selectedPersona?.imageUrl ??
                            selectedPersona?.baseImageUrl,
                        onStyleTemplateChanged: widget.onStyleTemplateChanged,
                        onGenreChanged: widget.onGenreChanged,
                        onGenreSubtypeChanged: widget.onGenreSubtypeChanged,
                        onTargetCutCountChanged: widget.onTargetCutCountChanged,
                        onChanged: widget.onDraftChanged,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FinalMobileDiaryStep extends StatelessWidget {
  const _FinalMobileDiaryStep({
    super.key,
    required this.titleController,
    required this.bodyController,
    required this.weather,
    required this.selectedPersonaId,
    required this.personas,
    required this.isLoadingTemplates,
    required this.onWeatherChanged,
    required this.onTemplateChanged,
    required this.onChanged,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final String weather;
  final String selectedPersonaId;
  final List<PersonaModel> personas;
  final bool isLoadingTemplates;
  final ValueChanged<String> onWeatherChanged;
  final ValueChanged<String> onTemplateChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _FinalMobileCard(
      title: '\uC124\uC815',
      subtitle: '1/2 \uC77C\uAE30\uC640 \uB0A0\uC528',
      pageNumber: 1,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final compactHeight = constraints.maxHeight < 360;
          final bodyHeight = compactHeight ? 112.0 : 142.0;
          final personaHeight = compactHeight ? 86.0 : 108.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const _FinalMobileLabel(
                icon: Icons.edit_note_rounded,
                text: '\uC77C\uAE30',
              ),
              Gap(compactHeight ? 6 : 9),
              SizedBox(
                height: 42,
                child: TextField(
                  controller: titleController,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.left,
                  onChanged: (_) => onChanged(),
                  decoration: _finalMobileFlatField(
                    '\uC791\uD488 \uC81C\uBAA9',
                  ),
                ),
              ),
              Gap(compactHeight ? 7 : 10),
              SizedBox(
                height: bodyHeight,
                child: TextField(
                  controller: bodyController,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    height: 1.38,
                  ),
                  expands: true,
                  maxLines: null,
                  textAlign: TextAlign.left,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => onChanged(),
                  decoration: _finalMobileFlatField(
                    '\uC624\uB298\uC758 \uC7A5\uBA74',
                  ),
                ),
              ),
              Gap(compactHeight ? 8 : 12),
              const _FinalMobileLabel(
                icon: Icons.wb_sunny_rounded,
                text: '\uB0A0\uC528',
              ),
              Gap(compactHeight ? 6 : 8),
              _FinalMobileWeatherPicker(
                selected: weather,
                onChanged: (String value) {
                  onWeatherChanged(value);
                  onChanged();
                },
              ),
              Gap(compactHeight ? 9 : 14),
              const _FinalMobileLabel(
                icon: Icons.face_retouching_natural_rounded,
                text: '\uCE90\uB9AD\uD130',
              ),
              Gap(compactHeight ? 6 : 8),
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: personaHeight),
                  child: _TemplateChoiceSelector(
                    selectedPersonaId: selectedPersonaId,
                    personas: personas,
                    onChanged: onTemplateChanged,
                    isLoading: isLoadingTemplates,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DiaryTurningPage extends StatelessWidget {
  const _DiaryTurningPage({
    required this.controller,
    required this.index,
    required this.child,
  });

  final PageController controller;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final current = controller.hasClients
            ? (controller.page ?? controller.initialPage.toDouble())
            : controller.initialPage.toDouble();
        final delta = (current - index).clamp(-1.0, 1.0);
        final turn = delta.abs();
        final matrix = Matrix4.identity()
          ..setEntry(3, 2, 0.0012)
          ..rotateY(delta * -0.18)
          ..setTranslationRaw(delta * 10.0, 0, 0);
        return Opacity(
          opacity: (1 - turn * 0.08).clamp(0.0, 1.0),
          child: Transform(
            alignment: delta >= 0
                ? Alignment.centerLeft
                : Alignment.centerRight,
            transform: matrix,
            child: Transform.scale(scale: 1 - turn * 0.018, child: child),
          ),
        );
      },
      child: child,
    );
  }
}

class _DiaryWritingBookFrame extends StatelessWidget {
  const _DiaryWritingBookFrame({
    required this.page,
    required this.step,
    required this.isSaving,
    required this.canPublish,
    required this.onBack,
    required this.onNext,
    required this.child,
  });

  final double page;
  final int step;
  final bool isSaving;
  final bool canPublish;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final turnAmount = (sin((page % 1) * pi)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.all(0),
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFC7D8F8),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.70),
                  width: 1.4,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppTheme.ink.withValues(alpha: 0.13),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
            ),
          ),
          for (var index = 0; index < 3; index++)
            Positioned(
              top: 22.0 + index * 7,
              bottom: 24.0 - index * 2,
              right: 10.0 + index * 5,
              width: 24,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFEAF3FF,
                  ).withValues(alpha: 0.48 - index * 0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFD5E4FA).withValues(alpha: 0.70),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            left: 30,
            right: 10,
            top: 12,
            bottom: 72,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFEFA),
                  border: Border.all(color: const Color(0xFFC8D8F2)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.ink.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Stack(
                  children: <Widget>[
                    child,
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _DiaryTurnShadowPainter(
                            turnAmount: turnAmount,
                            page: page,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 2,
            top: 54,
            bottom: 88,
            width: 66,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List<Widget>.generate(
                5,
                (int index) => _DiarySpringLoop(compact: true),
              ),
            ),
          ),
          Positioned(
            left: 64,
            right: 48,
            bottom: 20,
            height: 44,
            child: _DiaryBookNavigationTabs(
              step: step,
              isSaving: isSaving,
              canPublish: canPublish,
              onBack: onBack,
              onNext: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalMobileSceneStep extends StatelessWidget {
  const _FinalMobileSceneStep({
    super.key,
    required this.title,
    required this.body,
    required this.weather,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.targetCutCount,
    required this.genreSubtypeOptions,
    required this.keywordTags,
    required this.isSaving,
    required this.previewImageUrls,
    required this.previewPersonaName,
    required this.previewPersonaImageUrl,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onTargetCutCountChanged,
    required this.onChanged,
  });

  final String title;
  final String body;
  final String weather;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final int targetCutCount;
  final List<String> genreSubtypeOptions;
  final List<String> keywordTags;
  final bool isSaving;
  final List<String> previewImageUrls;
  final String? previewPersonaName;
  final String? previewPersonaImageUrl;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final ValueChanged<int> onTargetCutCountChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _FinalMobileCard(
      title: '\uC124\uC815',
      subtitle: '2/2 \uC7A5\uBA74\uACFC \uCEF7\uC218',
      pageNumber: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const _FinalMobileLabel(
            icon: Icons.tune_rounded,
            text: '\uC7A5\uBA74',
          ),
          const Gap(10),
          _FinalStyleControls(
            genre: genre,
            genreSubtype: genreSubtype,
            targetCutCount: targetCutCount,
            genreSubtypeOptions: genreSubtypeOptions,
            onGenreChanged: (String value) {
              onGenreChanged(value);
              onChanged();
            },
            onGenreSubtypeChanged: (String value) {
              onGenreSubtypeChanged(value);
              onChanged();
            },
            onTargetCutCountChanged: (int value) {
              onTargetCutCountChanged(value);
              onChanged();
            },
          ),
          const Gap(12),
          _FinalStyleTemplateSelector(
            selectedId: selectedStyleTemplateId,
            templates: styleTemplates,
            onChanged: (String value) {
              onStyleTemplateChanged(value);
              onChanged();
            },
          ),
          const Gap(12),
          SizedBox(
            height: 156,
            child: _DiaryWebtoonPreviewCard(
              imageUrls: previewImageUrls,
              isLoading: isSaving,
              title: title,
              body: body,
              weather: weather,
              genre: genre,
              genreSubtype: genreSubtype,
              keywordTags: keywordTags,
              personaName: previewPersonaName,
              personaImageUrl: previewPersonaImageUrl,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinalMobileWeatherPicker extends StatelessWidget {
  const _FinalMobileWeatherPicker({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _WeatherIconSelector._options.map((_WeatherOption option) {
          final isSelected = selected == option.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: option.label,
              child: _PressableScale(
                onTap: () => onChanged(option.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 46,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFEAF3FF)
                        : Colors.white.withValues(alpha: 0.78),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: AppTheme.tacticalBlue, width: 1.5)
                        : null,
                  ),
                  child: Icon(
                    option.icon,
                    size: 22,
                    color: isSelected
                        ? AppTheme.tacticalBlue
                        : AppTheme.ink.withValues(alpha: 0.68),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FinalMobileCard extends StatelessWidget {
  const _FinalMobileCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.pageNumber,
    required this.child,
  });

  final String title;
  final String subtitle;
  final int pageNumber;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 8, 2, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFA).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFC6D8F4)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(painter: const _DiaryPaperLinesPainter()),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 28,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFFE7F1FF).withValues(alpha: 0.72),
                  border: Border(
                    right: BorderSide(
                      color: const Color(0xFFC7D9F5).withValues(alpha: 0.80),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 10,
              top: 22,
              bottom: 22,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List<Widget>.generate(
                  5,
                  (int index) => DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFADC4EB)),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppTheme.ink.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const SizedBox(width: 10, height: 10),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 0,
              top: 0,
              child: CustomPaint(
                size: const Size(38, 38),
                painter: const _DiaryPageCornerPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(42, 13, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF3FF),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: const Color(0xFFC2D5F4)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          child: Text(
                            'p.$pageNumber',
                            style: const TextStyle(
                              color: Color(0xFF6D91D6),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          title,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 34),
                    ],
                  ),
                  const Gap(16),
                  child,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinalMobileStepBar extends StatelessWidget {
  const _FinalMobileStepBar({
    required this.step,
    required this.isSaving,
    required this.canPublish,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool isSaving;
  final bool canPublish;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isPublishStep = step == 1;
    final label = isPublishStep
        ? isSaving
              ? '\uC774\uBBF8\uC9C0 \uC0DD\uC131 \uC911...'
              : '\uBC1C\uD589 \uC124\uC815\uD558\uAE30'
        : '\uB2E4\uC74C';
    return Row(
      children: <Widget>[
        SizedBox(
          width: 60,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE6F0F1),
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppTheme.ink.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: AppTheme.ink.withValues(alpha: 0.72),
              tooltip: '\uC774\uC804',
            ),
          ),
        ),
        const Gap(10),
        Expanded(
          child: SizedBox(
            height: 60,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF90A9EE).withValues(alpha: 0.36),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF96ACEF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(
                    0xFFB6C2DE,
                  ).withValues(alpha: 0.76),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.72),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isPublishStep && !canPublish ? null : onNext,
                icon: Icon(
                  isPublishStep
                      ? Icons.publish_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiaryBookNavigationTabs extends StatelessWidget {
  const _DiaryBookNavigationTabs({
    required this.step,
    required this.isSaving,
    required this.canPublish,
    required this.onBack,
    required this.onNext,
  });

  final int step;
  final bool isSaving;
  final bool canPublish;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isPublishStep = step == 1;
    final label = isPublishStep
        ? isSaving
              ? '\uC0DD\uC131 \uC911'
              : '\uBC1C\uD589\uD558\uAE30'
        : '\uB2E4\uC74C';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _DiaryBookTabButton(
          icon: Icons.chevron_left_rounded,
          label: step == 0 ? '\uD45C\uC9C0' : 'p.1',
          onTap: onBack,
          tone: _DiaryBookButtonTone.light,
          width: 76,
        ),
        const Gap(8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(
            2,
            (int index) => Padding(
              padding: EdgeInsets.only(left: index == 0 ? 0 : 5),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: index == step
                      ? const Color(0xFF8FB2EA)
                      : Colors.white.withValues(alpha: 0.84),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFAFC5EA)),
                ),
                child: const SizedBox(width: 7, height: 7),
              ),
            ),
          ),
        ),
        const Gap(8),
        _DiaryBookTabButton(
          icon: isPublishStep
              ? Icons.ios_share_rounded
              : Icons.chevron_right_rounded,
          label: label,
          onTap: isPublishStep && !canPublish ? null : onNext,
          tone: _DiaryBookButtonTone.primary,
          iconOnRight: !isPublishStep,
          width: 96,
        ),
      ],
    );
  }
}

enum _DiaryBookButtonTone { light, primary }

class _DiaryBookTabButton extends StatelessWidget {
  const _DiaryBookTabButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.tone,
    required this.width,
    this.iconOnRight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final _DiaryBookButtonTone tone;
  final double width;
  final bool iconOnRight;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final isPrimary = tone == _DiaryBookButtonTone.primary;
    final bg = isPrimary ? const Color(0xFFF9FBFF) : const Color(0xFFF6FAFF);
    final border = isPrimary
        ? const Color(0xFF8FB2EA)
        : const Color(0xFFAFC5EA);
    final fg = isPrimary ? const Color(0xFF638BD6) : AppTheme.tacticalBlue;
    final iconWidget = Icon(icon, size: 17, color: fg.withValues(alpha: 0.92));
    final labelWidget = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: fg.withValues(alpha: enabled ? 1 : 0.68),
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
      ),
    );
    return _PressableScale(
      onTap: enabled ? onTap! : () {},
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg.withValues(alpha: enabled ? 0.96 : 0.72),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled ? border : const Color(0xFFC7D2E6),
            width: isPrimary ? 1.5 : 1.2,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.80),
              blurRadius: 0,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: SizedBox(
          width: width,
          height: 38,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: iconOnRight
                  ? <Widget>[labelWidget, const Gap(6), iconWidget]
                  : <Widget>[iconWidget, const Gap(6), labelWidget],
            ),
          ),
        ),
      ),
    );
  }
}

class _FinalMobileSetupPanel extends StatelessWidget {
  const _FinalMobileSetupPanel({
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.weather,
    required this.artStyle,
    required this.artSubStyle,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.artSubStyleOptions,
    required this.genreSubtypeOptions,
    required this.onWeatherChanged,
    required this.onArtStyleChanged,
    required this.onArtSubStyleChanged,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onChanged,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String weather;
  final String artStyle;
  final String artSubStyle;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final List<String> artSubStyleOptions;
  final List<String> genreSubtypeOptions;
  final ValueChanged<String> onWeatherChanged;
  final ValueChanged<String> onArtStyleChanged;
  final ValueChanged<String> onArtSubStyleChanged;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final diaryFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _FinalMobileLabel(
          icon: Icons.edit_note_rounded,
          text: '\uC77C\uAE30',
        ),
        const Gap(5),
        SizedBox(
          height: 38,
          child: TextField(
            controller: titleController,
            textAlign: TextAlign.left,
            onChanged: (_) => onChanged(),
            decoration: _finalMobileField('\uC791\uD488 \uC81C\uBAA9'),
          ),
        ),
        const Gap(6),
        SizedBox(
          height: 142,
          child: TextField(
            controller: bodyController,
            expands: true,
            maxLines: null,
            textAlign: TextAlign.left,
            textAlignVertical: TextAlignVertical.top,
            onChanged: (_) => onChanged(),
            decoration: _finalMobileField('\uC624\uB298\uC758 \uC7A5\uBA74'),
          ),
        ),
        const Gap(5),
        Text(
          '\uC624\uB298\uC758 \uC7A5\uBA74\uC740 50\uAE00\uC790 \uC774\uC0C1\uC5D0 \uAC10\uC815\uD45C\uD604\uC744 2\uAC1C \uC774\uC0C1 \uC11E\uC5B4\uC918\uC57C \uD6A8\uACFC\uC801\uC785\uB2C8\uB2E4.',
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.70),
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
      ],
    );

    final sceneFields = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _FinalMobileLabel(icon: Icons.tune_rounded, text: '\uC7A5\uBA74'),
        const Gap(5),
        Row(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _WeatherIconSelector._options.map((
                    _WeatherOption option,
                  ) {
                    final selected = weather == option.value;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Tooltip(
                        message: option.label,
                        child: _PressableScale(
                          onTap: () {
                            onWeatherChanged(option.value);
                            onChanged();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 42,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFFEAF3FF)
                                  : Colors.white.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(9),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.tacticalBlue
                                    : const Color(0xFFC3DAFF),
                                width: selected ? 1.8 : 1,
                              ),
                              boxShadow: selected
                                  ? <BoxShadow>[
                                      BoxShadow(
                                        color: AppTheme.tacticalBlue.withValues(
                                          alpha: 0.16,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : const <BoxShadow>[],
                            ),
                            child: Icon(
                              option.icon,
                              size: 21,
                              color: selected
                                  ? AppTheme.tacticalBlue
                                  : AppTheme.ink.withValues(alpha: 0.82),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final styleFields = _FinalStyleTemplateSelector(
      selectedId: selectedStyleTemplateId,
      templates: styleTemplates,
      onChanged: (String value) {
        onStyleTemplateChanged(value);
        onChanged();
      },
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Text(
                '\uCD5C\uC885 \uC124\uC815',
                style: TextStyle(
                  color: AppTheme.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              '\uBC1C\uD589 \uC804 \uD655\uC778',
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.68),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Gap(8),
        diaryFields,
        const Gap(10),
        sceneFields,
        const Gap(10),
        styleFields,
      ],
    );
  }
}

class _FinalMobileLabel extends StatelessWidget {
  const _FinalMobileLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 17, color: AppTheme.tacticalBlue),
        const Gap(7),
        Text(
          text,
          style: const TextStyle(
            color: AppTheme.ink,
            fontSize: 15.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _FinalStyleTemplateSelector extends StatelessWidget {
  const _FinalStyleTemplateSelector({
    required this.selectedId,
    required this.templates,
    required this.onChanged,
  });

  final String selectedId;
  final List<DiaryStyleTemplateModel> templates;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final values = templates.isEmpty
        ? _DiaryPageState._fallbackStyleTemplates
        : templates;
    final selected =
        values.any((DiaryStyleTemplateModel item) => item.id == selectedId)
        ? selectedId
        : values.first.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _FinalMobileLabel(
          icon: Icons.style_rounded,
          text: '\uADF8\uB9BC\uCCB4 \uD15C\uD50C\uB9BF',
        ),
        const Gap(6),
        SizedBox(
          height: mobile ? 44 : 48,
          child: DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            decoration: _finalMobileFlatField(
              '\uD15C\uD50C\uB9BF \uC120\uD0DD',
            ),
            items: values.map((DiaryStyleTemplateModel item) {
              return DropdownMenuItem<String>(
                value: item.id,
                child: Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                onChanged(value);
              }
            },
          ),
        ),
        if (!mobile) ...<Widget>[
          const Gap(6),
          _StyleTemplateImageSlot(
            template: values.firstWhere(
              (DiaryStyleTemplateModel item) => item.id == selected,
              orElse: () => values.first,
            ),
          ),
        ],
      ],
    );
  }
}

class _StyleTemplateImageSlot extends StatelessWidget {
  const _StyleTemplateImageSlot({required this.template});

  final DiaryStyleTemplateModel template;

  @override
  Widget build(BuildContext context) {
    final imageUrl = template.previewImageUrl;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 104,
          child: imageUrl == null || imageUrl.trim().isEmpty
              ? const SizedBox.expand()
              : _StorageAwareImage(url: imageUrl),
        ),
      ),
    );
  }
}

class _FinalStyleControls extends StatelessWidget {
  const _FinalStyleControls({
    required this.genre,
    required this.genreSubtype,
    required this.targetCutCount,
    required this.genreSubtypeOptions,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onTargetCutCountChanged,
  });

  final String genre;
  final String genreSubtype;
  final int targetCutCount;
  final List<String> genreSubtypeOptions;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final ValueChanged<int> onTargetCutCountChanged;

  static const List<String> _genres = <String>[
    '\uC720\uCF8C\uD558\uACE0 \uC6C3\uAE34 \uB0A0',
    '\uC9C4\uC9C0\uD558\uACE0 \uCC28\uBD84\uD55C \uB0A0',
    '\uB530\uB73B\uD558\uACE0 \uD589\uBCF5\uD55C \uB0A0',
    '\uBFCC\uB73B\uD558\uACE0 \uC131\uCDE8\uAC10 \uC788\uB294 \uB0A0',
    '\uD798\uB4E4\uACE0 \uC9C0\uCE5C \uB0A0',
  ];

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final genreDropdown = _FinalCompactDropdown(
      label: '\uC0C1\uC704 \uC5F0\uCD9C',
      value: genre,
      values: _genres,
      onChanged: onGenreChanged,
    );
    final genreControls = mobile
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFA).withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.ink.withValues(alpha: 0.08)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 8, 9, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  genreDropdown,
                  const Gap(7),
                  _FinalSubtypeChecklist(
                    selected: genreSubtype,
                    options: genreSubtypeOptions,
                    onChanged: onGenreSubtypeChanged,
                  ),
                ],
              ),
            ),
          )
        : Row(
            children: <Widget>[
              Expanded(child: genreDropdown),
              const Gap(8),
              Expanded(
                child: _FinalSubtypeChecklist(
                  selected: genreSubtype,
                  options: genreSubtypeOptions,
                  onChanged: onGenreSubtypeChanged,
                ),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _FinalMobileLabel(
          icon: Icons.movie_filter_rounded,
          text: '\uC5F0\uCD9C',
        ),
        const Gap(6),
        genreControls,
        const Gap(8),
        _FinalCutCountControl(
          value: targetCutCount,
          onChanged: onTargetCutCountChanged,
        ),
      ],
    );
  }
}

class _FinalSubtypeChecklist extends StatelessWidget {
  const _FinalSubtypeChecklist({
    required this.selected,
    required this.options,
    required this.onChanged,
  });

  final String selected;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.checklist_rounded,
              size: 14,
              color: AppTheme.ink.withValues(alpha: 0.50),
            ),
            const Gap(5),
            Text(
              '\uC138\uBD80 \uB290\uB08C',
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.58),
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '\uC120\uD0DD \uC548 \uD574\uB3C4 \uB428',
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.38),
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const Gap(6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: options.map((String option) {
            final checked = selected == option;
            return _DiaryPaperChoiceChip(
              label: option,
              selected: checked,
              onTap: () {
                onChanged(checked ? '' : option);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _FinalCutCountControl extends StatelessWidget {
  const _FinalCutCountControl({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const values = <int>[0, 1, 4, 8, 16];
    return Row(
      children: <Widget>[
        Text(
          '\uCEF7 \uC218',
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.74),
            fontSize: 12.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Gap(8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: values.map((int item) {
                final selected = (values.contains(value) ? value : 0) == item;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _DiaryPaperChoiceChip(
                    label: item == 0 ? 'AI' : '$item',
                    selected: selected,
                    onTap: () => onChanged(item),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiaryPaperChoiceChip extends StatelessWidget {
  const _DiaryPaperChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFEAF3FF).withValues(alpha: 0.96)
              : const Color(0xFFFFFEFA).withValues(alpha: 0.86),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: selected ? const Color(0xFF8EAEEB) : const Color(0xFFD6E2F5),
            width: selected ? 1.3 : 1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: selected ? 0.08 : 0.04),
              blurRadius: selected ? 7 : 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: selected ? const Color(0xFF638BD6) : AppTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _FinalCompactDropdown extends StatelessWidget {
  const _FinalCompactDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: DropdownButtonFormField<String>(
        initialValue: values.contains(value) ? value : values.first,
        isExpanded: true,
        decoration: _finalMobileField(
          label,
        ).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 10)),
        items: values.map((String item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          );
        }).toList(),
        onChanged: (String? value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}

InputDecoration _finalMobileField(String hintText) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.36),
    hintStyle: TextStyle(
      color: AppTheme.ink.withValues(alpha: 0.48),
      fontSize: 15,
      fontWeight: FontWeight.w800,
    ),
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
    border: UnderlineInputBorder(
      borderSide: BorderSide(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.26),
        width: 1.2,
      ),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.26),
        width: 1.2,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.72),
        width: 1.5,
      ),
    ),
  );
}

InputDecoration _finalMobileFlatField(String hintText) {
  return InputDecoration(
    hintText: hintText,
    filled: true,
    fillColor: const Color(0xFFFFFEFA).withValues(alpha: 0.34),
    hintStyle: TextStyle(
      color: AppTheme.ink.withValues(alpha: 0.55),
      fontSize: 15,
      fontWeight: FontWeight.w900,
    ),
    alignLabelWithHint: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
    border: UnderlineInputBorder(
      borderSide: BorderSide(
        color: const Color(0xFF9FB9E6).withValues(alpha: 0.54),
        width: 1.2,
      ),
    ),
    enabledBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: const Color(0xFF9FB9E6).withValues(alpha: 0.54),
        width: 1.2,
      ),
    ),
    focusedBorder: UnderlineInputBorder(
      borderSide: BorderSide(
        color: AppTheme.tacticalBlue.withValues(alpha: 0.74),
        width: 1.5,
      ),
    ),
  );
}

class _FinalLiveDiaryEditor extends StatelessWidget {
  const _FinalLiveDiaryEditor({
    required this.titleController,
    required this.bodyController,
    required this.tagController,
    required this.weather,
    required this.artStyle,
    required this.artSubStyle,
    required this.selectedStyleTemplateId,
    required this.styleTemplates,
    required this.genre,
    required this.genreSubtype,
    required this.artSubStyleOptions,
    required this.genreSubtypeOptions,
    required this.onWeatherChanged,
    required this.onArtStyleChanged,
    required this.onArtSubStyleChanged,
    required this.onStyleTemplateChanged,
    required this.onGenreChanged,
    required this.onGenreSubtypeChanged,
    required this.onChanged,
    required this.mobile,
  });

  final TextEditingController titleController;
  final TextEditingController bodyController;
  final TextEditingController tagController;
  final String weather;
  final String artStyle;
  final String artSubStyle;
  final String selectedStyleTemplateId;
  final List<DiaryStyleTemplateModel> styleTemplates;
  final String genre;
  final String genreSubtype;
  final List<String> artSubStyleOptions;
  final List<String> genreSubtypeOptions;
  final ValueChanged<String> onWeatherChanged;
  final ValueChanged<String> onArtStyleChanged;
  final ValueChanged<String> onArtSubStyleChanged;
  final ValueChanged<String> onStyleTemplateChanged;
  final ValueChanged<String> onGenreChanged;
  final ValueChanged<String> onGenreSubtypeChanged;
  final VoidCallback onChanged;
  final bool mobile;

  @override
  Widget build(BuildContext context) {
    final wideMobile = mobile && MediaQuery.sizeOf(context).width >= 520;
    final logPanel = _FinalEditorSection(
      title: '\uC77C\uAE30 \uB0B4\uC6A9',
      icon: Icons.edit_note_rounded,
      child: Column(
        children: <Widget>[
          SizedBox(
            height: mobile ? 44 : 44,
            child: TextField(
              controller: titleController,
              textAlign: TextAlign.center,
              onChanged: (_) => onChanged(),
              decoration: _figmaField(
                '\uC791\uD488 \uC81C\uBAA9\uC744 \uC785\uB825\uD574 \uC8FC\uC138\uC694',
              ),
            ),
          ),
          const Gap(8),
          SizedBox(
            height: wideMobile ? 58 : (mobile ? 78 : 112),
            child: TextField(
              controller: bodyController,
              expands: true,
              maxLines: null,
              textAlign: TextAlign.center,
              textAlignVertical: TextAlignVertical.top,
              onChanged: (_) => onChanged(),
              decoration: _figmaField(
                '\uC624\uB298\uC758 \uC7A5\uBA74\uC744 \uC801\uC5B4 \uC8FC\uC138\uC694',
              ).copyWith(contentPadding: const EdgeInsets.all(14)),
            ),
          ),
        ],
      ),
    );

    final metaPanel = _FinalEditorSection(
      title: '\uC7A5\uBA74 \uC124\uC815',
      icon: Icons.tune_rounded,
      child: Column(
        children: <Widget>[
          _WeatherIconSelector(
            selected: weather,
            onChanged: (String value) {
              onWeatherChanged(value);
              onChanged();
            },
          ),
          const Gap(8),
          _FinalStyleTemplateSelector(
            selectedId: selectedStyleTemplateId,
            templates: styleTemplates,
            onChanged: (String value) {
              onStyleTemplateChanged(value);
              onChanged();
            },
          ),
        ],
      ),
    );

    if (mobile) {
      return Column(children: <Widget>[logPanel, const Gap(8), metaPanel]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(flex: 6, child: logPanel),
        const Gap(12),
        Expanded(flex: 4, child: metaPanel),
      ],
    );
  }
}

class _FinalEditorSection extends StatelessWidget {
  const _FinalEditorSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: mobile
            ? Colors.white.withValues(alpha: 0.90)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(mobile ? 10 : 12),
        border: Border.all(
          color: const Color(0xFFB8D2FF).withValues(alpha: mobile ? 0.70 : 1),
          width: mobile ? 1 : 1.3,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 8 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Icon(icon, size: 18, color: AppTheme.tacticalBlue),
                const Gap(7),
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            Gap(mobile ? 7 : 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _DiaryFinalActionBar extends StatelessWidget {
  const _DiaryFinalActionBar({
    required this.hasTemplates,
    required this.isSaving,
    required this.onBack,
    required this.onGenerate,
    this.compact = false,
  });

  final bool hasTemplates;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onGenerate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = !hasTemplates
        ? '\uCE90\uB9AD\uD130\uB97C \uBA3C\uC800 \uC120\uD0DD\uD574 \uC8FC\uC138\uC694'
        : isSaving
        ? '\uC774\uBBF8\uC9C0 \uC0DD\uC131 \uC911...'
        : '\uCD5C\uC885 \uBC1C\uD589 \uC124\uC815\uD558\uAE30';

    if (compact) {
      return Row(
        children: <Widget>[
          SizedBox(
            width: 48,
            height: 54,
            child: IconButton.filledTonal(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              tooltip: '\uC774\uC804',
            ),
          ),
          const Gap(8),
          Expanded(
            child: SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: isSaving || !hasTemplates ? null : onGenerate,
                icon: const Icon(Icons.publish_rounded),
                label: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7FA8FF), width: 1.5),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 12),
        child: Row(
          children: <Widget>[
            if (!compact) ...<Widget>[
              _FigmaBackButton(onTap: onBack),
              const Gap(12),
            ] else ...<Widget>[
              IconButton.filledTonal(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                tooltip: '\uC774\uC804',
              ),
              const Gap(8),
            ],
            Expanded(
              child: SizedBox(
                height: compact ? 52 : 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isSaving || !hasTemplates
                        ? const <BoxShadow>[]
                        : <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.26,
                              ),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                  ),
                  child: FilledButton.icon(
                    onPressed: isSaving || !hasTemplates ? null : onGenerate,
                    icon: const Icon(Icons.publish_rounded),
                    label: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiaryWebtoonPreviewCard extends StatelessWidget {
  const _DiaryWebtoonPreviewCard({
    required this.imageUrls,
    required this.isLoading,
    required this.title,
    required this.body,
    required this.weather,
    required this.genre,
    required this.genreSubtype,
    required this.keywordTags,
    this.personaName,
    this.personaImageUrl,
  });

  final List<String> imageUrls;
  final bool isLoading;
  final String title;
  final String body;
  final String weather;
  final String genre;
  final String genreSubtype;
  final List<String> keywordTags;
  final String? personaName;
  final String? personaImageUrl;

  @override
  Widget build(BuildContext context) {
    final imageUrl = imageUrls.isEmpty ? null : imageUrls.first;
    final mobile = _isMobileLayout(context);
    final ready = body.trim().isNotEmpty;
    final displayTitle = title.trim().isEmpty
        ? '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30'
        : title.trim();
    final displayBody = body.trim().isEmpty
        ? '\uC77C\uAE30 \uB0B4\uC6A9\uC744 \uC785\uB825\uD558\uBA74 \uC774 \uBBF8\uB9AC\uBCF4\uAE30\uC5D0 \uBC14\uB85C \uBC18\uC601\uB429\uB2C8\uB2E4.'
        : body.trim();
    final personaUrl = personaImageUrl?.trim();
    final hasPersonaImage = personaUrl != null && personaUrl.isNotEmpty;
    final personaLabel = personaName?.trim().isNotEmpty == true
        ? personaName!.trim()
        : '\uC120\uD0DD \uCE90\uB9AD\uD130';
    final tagWidgets = <Widget>[
      _PreviewTag(text: genre),
      if (!mobile && genreSubtype.trim().isNotEmpty)
        _PreviewTag(text: genreSubtype),
      if (!mobile && keywordTags.isNotEmpty)
        _PreviewTag(text: '#${keywordTags.first}'),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        border: Border.all(color: const Color(0xFF8FB6FF), width: 1.2),
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (imageUrl != null)
              _StorageAwareImage(url: imageUrl)
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      const Color(0xFFF9FCFF),
                      AppTheme.pastelBlue.withValues(alpha: 0.26),
                      AppTheme.pastelRose.withValues(alpha: 0.10),
                    ],
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(mobile ? 12 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            ready
                                ? Icons.auto_awesome_motion_rounded
                                : Icons.edit_note_rounded,
                            size: 18,
                            color: ready
                                ? AppTheme.tacticalBlue
                                : AppTheme.ink.withValues(alpha: 0.72),
                          ),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              ready
                                  ? '\uC0DD\uC131 \uBBF8\uB9AC\uBCF4\uAE30'
                                  : '\uC77C\uAE30\uB97C \uC785\uB825\uD574 \uC8FC\uC138\uC694',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          _StatusChip(
                            icon: _weatherIcon(weather),
                            label: _weatherLabel(weather),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    displayTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF4E6FD0),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16.5,
                                    ),
                                  ),
                                  const Gap(6),
                                  Expanded(
                                    child: Text(
                                      displayBody,
                                      maxLines: mobile ? 2 : 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppTheme.ink.withValues(
                                          alpha: 0.88,
                                        ),
                                        height: 1.44,
                                        fontSize: mobile ? 12.8 : 12.8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Gap(10),
                            SizedBox(
                              width: mobile ? 58 : 86,
                              child: Column(
                                children: <Widget>[
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.74,
                                          ),
                                          border: Border.all(
                                            color: AppTheme.tacticalBlue
                                                .withValues(alpha: 0.18),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: hasPersonaImage
                                            ? _StorageAwareImage(
                                                url: personaUrl,
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons
                                                      .face_retouching_natural_rounded,
                                                  color: AppTheme.tacticalBlue
                                                      .withValues(alpha: 0.70),
                                                  size: 30,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ),
                                  const Gap(4),
                                  Text(
                                    personaLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppTheme.ink.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 10.8,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!mobile) ...<Widget>[
                        const Gap(8),
                        Wrap(spacing: 6, runSpacing: 5, children: tagWidgets),
                      ],
                    ],
                  ),
                ),
              ),
            if (imageUrl != null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: _PreviewImageOverlay(
                  title: displayTitle,
                  weather: weather,
                  tags: tagWidgets.take(mobile ? 3 : 4).toList(),
                ),
              ),
            if (isLoading)
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      CircularProgressIndicator(strokeWidth: 2),
                      Gap(12),
                      Text(
                        '\uC6F9\uD230 \uC774\uBBF8\uC9C0 \uC0DD\uC131 \uC911...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF75A8FF),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (imageUrls.length > 1)
              Positioned(
                left: 8,
                top: 8,
                child: _StatusChip(
                  icon: Icons.view_carousel_rounded,
                  label: '${imageUrls.length} CUTS',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTag extends StatelessWidget {
  const _PreviewTag({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 150),
          child: Text(
            text,
            softWrap: true,
            style: const TextStyle(
              color: AppTheme.tacticalBlue,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewImageOverlay extends StatelessWidget {
  const _PreviewImageOverlay({
    required this.title,
    required this.weather,
    required this.tags,
  });

  final String title;
  final String weather;
  final List<Widget> tags;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.72)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Gap(6),
                    Icon(
                      _weatherIcon(weather),
                      size: 15,
                      color: AppTheme.tacticalBlue,
                    ),
                  ],
                ),
                if (tags.isNotEmpty) ...<Widget>[
                  const Gap(6),
                  Wrap(spacing: 5, runSpacing: 4, children: tags),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GeneratedDiarySlideScreen extends StatefulWidget {
  const _GeneratedDiarySlideScreen({
    required this.panels,
    required this.imageUrls,
    required this.onBack,
    required this.onRetryPanel,
    required this.onDone,
  });

  final List<DiaryPanelModel> panels;
  final List<String> imageUrls;
  final VoidCallback onBack;
  final Future<void> Function(DiaryPanelModel panel, String retryFeedback)
  onRetryPanel;
  final VoidCallback onDone;

  @override
  State<_GeneratedDiarySlideScreen> createState() =>
      _GeneratedDiarySlideScreenState();
}

class _GeneratedDiarySlideScreenState
    extends State<_GeneratedDiarySlideScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  String? _retryingPanelId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToSlide(int target, int length) {
    if (target < 0 || target >= length) {
      return;
    }
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _PanelSlideData.fromPanels(
      panels: widget.panels,
      fallbackImageUrls: widget.imageUrls,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(44, 12, 44, 20),
      child: Column(
        children: <Widget>[
          const _FigmaPill(text: 'GENERATED DIARY'),
          const Gap(14),
          Expanded(
            child: slides.isEmpty
                ? const Center(
                    child: Text(
                      '\uC544\uC9C1 \uC0DD\uC131\uB41C \uC774\uBBF8\uC9C0\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      PageView.builder(
                        controller: _controller,
                        onPageChanged: (int value) {
                          setState(() => _index = value);
                        },
                        itemCount: slides.length,
                        itemBuilder: (BuildContext context, int index) {
                          return Center(
                            child: AspectRatio(
                              aspectRatio: 2 / 3,
                              child: _WebtoonPanelCard(slide: slides[index]),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
          ),
          const Gap(12),
          if (slides.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                _SlideStepButton(
                  icon: Icons.chevron_left_rounded,
                  label: '\uC774\uC804 \uCEF7',
                  enabled: _index > 0,
                  onTap: () => _goToSlide(_index - 1, slides.length),
                ),
                const Gap(12),
                ...List<Widget>.generate(slides.length, (int index) {
                  final selected = index == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: selected ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.tacticalBlue
                          : AppTheme.pastelBlue.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
                const Gap(12),
                _SlideStepButton(
                  icon: Icons.chevron_right_rounded,
                  label: '\uB2E4\uC74C \uCEF7',
                  enabled: _index < slides.length - 1,
                  onTap: () => _goToSlide(_index + 1, slides.length),
                ),
              ],
            ),
          if (slides.isNotEmpty && slides[_index].panel != null) ...<Widget>[
            const Gap(10),
            _PressableScale(
              onTap: () async {
                if (_retryingPanelId != null) {
                  return;
                }
                final panel = slides[_index].panel!;
                final retryFeedback = await _askRetryFeedback(context);
                if (retryFeedback == null) {
                  return;
                }
                setState(() => _retryingPanelId = panel.id);
                try {
                  await widget.onRetryPanel(panel, retryFeedback);
                } finally {
                  if (mounted) {
                    setState(() => _retryingPanelId = null);
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF9FB9F6)),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    if (_retryingPanelId == slides[_index].panel!.id)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.refresh_rounded, size: 20),
                    const Gap(8),
                    Text(
                      _retryingPanelId == slides[_index].panel!.id
                          ? '\uC774\uBBF8\uC9C0 \uC7AC\uC0DD\uC131 \uC911...'
                          : '\uC774\uBBF8\uC9C0 \uC7AC\uC0DD\uC131',
                      style: const TextStyle(
                        color: Color(0xFF5B78D6),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const Gap(12),
          Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: widget.onBack,
                child: const Text('\uC774\uC804'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: widget.onDone,
                child: const Text('\uC644\uB8CC'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _askRetryFeedback(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('\uCE90\uB9AD\uD130 \uC218\uC815'),
          content: TextField(
            controller: controller,
            autofocus: true,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText:
                  '\uBC14\uAFB8\uACE0 \uC2F6\uC740 \uC810\uC744 \uC801\uC5B4 \uC8FC\uC138\uC694. \uC608: \uD45C\uC815\uC740 \uBC1D\uAC8C, \uBC30\uACBD\uC740 \uAD50\uC2E4\uB85C',
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('\uCDE8\uC18C'),
            ),
            FilledButton.icon(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('\uC218\uC815'),
            ),
          ],
        );
      },
    );
  }
}

class _PanelSlideData {
  const _PanelSlideData({
    required this.imageUrl,
    required this.index,
    this.panel,
    this.panelType,
    this.dialogue,
    this.prompt,
    this.tags = const <String>[],
  });

  final String imageUrl;
  final int index;
  final DiaryPanelModel? panel;
  final String? panelType;
  final String? dialogue;
  final String? prompt;
  final List<String> tags;

  static List<_PanelSlideData> fromPanels({
    required List<DiaryPanelModel> panels,
    required List<String> fallbackImageUrls,
  }) {
    final slides = _diaryPanelsReadingOrder(panels)
        .map(
          (DiaryPanelModel panel) => _PanelSlideData(
            imageUrl: panel.imageUrl!,
            index: panel.panelOrder,
            panel: panel,
            panelType: panel.panelType,
            dialogue: panel.dialogue,
            prompt: panel.prompt,
            tags: _extractPanelTags(panel.prompt),
          ),
        )
        .toList();

    if (slides.isNotEmpty) {
      return slides;
    }

    return _diaryImageUrlsReadingOrder(fallbackImageUrls)
        .asMap()
        .entries
        .map(
          (MapEntry<int, String> entry) =>
              _PanelSlideData(imageUrl: entry.value, index: entry.key),
        )
        .toList();
  }
}

List<String> _extractPanelTags(String? prompt) {
  if (prompt == null || prompt.trim().isEmpty) {
    return const <String>[];
  }

  final matches = RegExp(r'#([^\s,;|]+)').allMatches(prompt);
  return matches
      .map((RegExpMatch match) => match.group(1))
      .whereType<String>()
      .where((String tag) => tag.trim().isNotEmpty)
      .toSet()
      .take(4)
      .toList();
}

class _WebtoonPanelCard extends StatelessWidget {
  const _WebtoonPanelCard({required this.slide});

  final _PanelSlideData slide;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.tacticalBlue, width: 1.6),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _StorageAwareImage(url: slide.imageUrl),
      ),
    );
  }
}

class _ImageUrlSlideDeck extends StatefulWidget {
  const _ImageUrlSlideDeck({required this.imageUrls, this.panels = const []});

  final List<String> imageUrls;
  final List<DiaryPanelModel> panels;

  @override
  State<_ImageUrlSlideDeck> createState() => _ImageUrlSlideDeckState();
}

class _ImageUrlSlideDeckState extends State<_ImageUrlSlideDeck> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToSlide(int target, int length) {
    if (target < 0 || target >= length) {
      return;
    }
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = _PanelSlideData.fromPanels(
      panels: widget.panels,
      fallbackImageUrls: widget.imageUrls,
    );

    if (slides.isEmpty) {
      return const Center(
        child: Text(
          '\uD45C\uC2DC\uD560 \uC774\uBBF8\uC9C0\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: <Widget>[
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              PageView.builder(
                controller: _controller,
                onPageChanged: (int value) => setState(() => _index = value),
                itemCount: slides.length,
                itemBuilder: (BuildContext context, int index) {
                  return Center(
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: _WebtoonPanelCard(slide: slides[index]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Gap(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            _SlideStepButton(
              icon: Icons.chevron_left_rounded,
              label: '\uC774\uC804 \uCEF7',
              enabled: _index > 0,
              onTap: () => _goToSlide(_index - 1, slides.length),
            ),
            const Gap(12),
            ...List<Widget>.generate(slides.length, (int index) {
              final selected = index == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: selected ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.tacticalBlue
                      : AppTheme.pastelBlue.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }),
            const Gap(12),
            _SlideStepButton(
              icon: Icons.chevron_right_rounded,
              label: '\uB2E4\uC74C \uCEF7',
              enabled: _index < slides.length - 1,
              onTap: () => _goToSlide(_index + 1, slides.length),
            ),
          ],
        ),
      ],
    );
  }
}

class _SlideStepButton extends StatelessWidget {
  const _SlideStepButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.36,
      child: FilledButton.tonalIcon(
        onPressed: enabled ? onTap : null,
        icon: Icon(icon, size: 20),
        label: Text(label, textAlign: TextAlign.center),
        style: FilledButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.92),
          foregroundColor: AppTheme.tacticalBlue,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.66),
          disabledForegroundColor: AppTheme.ink.withValues(alpha: 0.34),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          minimumSize: const Size(84, 40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
            side: BorderSide(
              color: AppTheme.tacticalBlue.withValues(alpha: 0.42),
            ),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class _StorageAwareImage extends StatelessWidget {
  const _StorageAwareImage({
    required this.url,
    this.fallback = const _PostImageFallback(),
    this.fit = BoxFit.cover,
  });

  final String url;
  final Widget fallback;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return fallback;
    }

    return Image.network(
      url,
      fit: fit,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        final storagePath = _storagePathFromPublicUrl(url);
        if (storagePath == null || !SupabaseRuntime.isConfigured) {
          return fallback;
        }

        return FutureBuilder<Uint8List>(
          future: Supabase.instance.client.storage
              .from('diary-assets')
              .download(storagePath),
          builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }
            final bytes = snapshot.data;
            if (bytes == null || bytes.isEmpty) {
              return fallback;
            }
            return Image.memory(bytes, fit: fit);
          },
        );
      },
    );
  }

  String? _storagePathFromPublicUrl(String imageUrl) {
    final uri = Uri.tryParse(imageUrl);
    if (uri == null) {
      return null;
    }

    const marker = '/storage/v1/object/public/diary-assets/';
    final index = uri.path.indexOf(marker);
    if (index < 0) {
      return null;
    }

    final encodedPath = uri.path.substring(index + marker.length);
    return Uri.decodeComponent(encodedPath);
  }
}

String? _storagePathFromDiaryAssetPublicUrl(String imageUrl) {
  final uri = Uri.tryParse(imageUrl);
  if (uri == null) {
    return null;
  }

  const marker = '/storage/v1/object/public/diary-assets/';
  final index = uri.path.indexOf(marker);
  if (index < 0) {
    return null;
  }

  final encodedPath = uri.path.substring(index + marker.length);
  return Uri.decodeComponent(encodedPath);
}

class _TemplateChoiceSelector extends StatefulWidget {
  const _TemplateChoiceSelector({
    required this.selectedPersonaId,
    required this.personas,
    required this.onChanged,
    this.isLoading = false,
  });

  final String selectedPersonaId;
  final List<PersonaModel> personas;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  @override
  State<_TemplateChoiceSelector> createState() =>
      _TemplateChoiceSelectorState();
}

class _TemplateChoiceSelectorState extends State<_TemplateChoiceSelector> {
  String _scope = 'mine';

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final scopedPersonas = widget.personas.where((PersonaModel persona) {
      if (_scope == 'mine') {
        return persona.userId == currentUserId;
      }
      return persona.userId != currentUserId &&
          (persona.isPublic || persona.templateVisibility == 'followers');
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (!mobile) ...<Widget>[
          const _FigmaTinyTag(text: '\uCE90\uB9AD\uD130 \uC120\uD0DD'),
          const Gap(6),
        ],
        SegmentedButtonTheme(
          data: SegmentedButtonThemeData(
            style: ButtonStyle(
              textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
              ),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? AppTheme.ink
                    : AppTheme.ink.withValues(alpha: 0.78);
              }),
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                return states.contains(WidgetState.selected)
                    ? const Color(0xFFE6F0FF)
                    : Colors.white.withValues(alpha: mobile ? 0.72 : 0.90);
              }),
              side: WidgetStateProperty.resolveWith((states) {
                return BorderSide(
                  color: states.contains(WidgetState.selected)
                      ? AppTheme.tacticalBlue.withValues(alpha: 0.72)
                      : AppTheme.ink.withValues(alpha: mobile ? 0.12 : 0.28),
                  width: states.contains(WidgetState.selected) ? 1.3 : 1,
                );
              }),
            ),
          ),
          child: SegmentedButton<String>(
            segments: <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'mine',
                icon: mobile ? null : Icon(Icons.bookmark_rounded),
                label: Text('\uB0B4 \uCE90\uB9AD\uD130'),
              ),
              ButtonSegment<String>(
                value: 'shared',
                icon: mobile ? null : Icon(Icons.public_rounded),
                label: Text('\uACF5\uC720 \uCE90\uB9AD\uD130'),
              ),
            ],
            selected: <String>{_scope},
            onSelectionChanged: (Set<String> values) {
              setState(() => _scope = values.first);
              final filtered = widget.personas.where((PersonaModel persona) {
                if (values.first == 'mine') {
                  return persona.userId == currentUserId;
                }
                return persona.userId != currentUserId &&
                    (persona.isPublic ||
                        persona.templateVisibility == 'followers');
              }).toList();
              if (filtered.isNotEmpty) {
                widget.onChanged(filtered.first.id);
              }
            },
          ),
        ),
        const Gap(6),
        if (widget.isLoading) ...<Widget>[
          const SizedBox(
            height: 40,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          const Gap(8),
        ],
        if (widget.personas.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              border: Border.all(color: const Color(0xFFBFD9FF)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Center(
                child: Text(
                  '\uCE90\uB9AD\uD130 \uD0ED\uC5D0\uC11C \uBA3C\uC800 \uCE90\uB9AD\uD130\uB97C \uB9CC\uB4E4\uC5B4 \uC8FC\uC138\uC694.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF5B8EEB),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          )
        else if (scopedPersonas.isEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              border: Border.all(color: const Color(0xFFBFD9FF)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Center(
                child: Text(
                  _scope == 'mine'
                      ? '\uB0B4 \uCE90\uB9AD\uD130\uAC00 \uC544\uC9C1 \uC5C6\uC2B5\uB2C8\uB2E4.'
                      : '\uACF5\uC720 \uCE90\uB9AD\uD130\uAC00 \uC544\uC9C1 \uC5C6\uC2B5\uB2C8\uB2E4.',
                  style: const TextStyle(
                    color: Color(0xFF5B8EEB),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: PageView.builder(
              controller: PageController(
                viewportFraction: mobile ? 0.36 : 0.48,
              ),
              padEnds: false,
              itemCount: scopedPersonas.length,
              onPageChanged: (int index) {
                widget.onChanged(scopedPersonas[index].id);
              },
              itemBuilder: (BuildContext context, int index) {
                final persona = scopedPersonas[index];
                final imageUrl = persona.imageUrl ?? persona.baseImageUrl;
                final isSelected = widget.selectedPersonaId == persona.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _PressableScale(
                    onTap: () => widget.onChanged(persona.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEAF3FF)
                            : Colors.white.withValues(alpha: 0.76),
                        border: isSelected
                            ? Border.all(
                                color: const Color(0xFF6EA3FF),
                                width: 1.7,
                              )
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: imageUrl == null || imageUrl.isEmpty
                                    ? const Center(
                                        child: Icon(
                                          Icons.face_retouching_natural_rounded,
                                          color: Color(0xFF8BB9FF),
                                          size: 42,
                                        ),
                                      )
                                    : _StorageAwareImage(url: imageUrl),
                              ),
                            ),
                            const Gap(5),
                            Text(
                              persona.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppTheme.ink,
                                fontSize: isSelected ? 14.5 : 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (!mobile) ...<Widget>[
                              const Gap(2),
                              Text(
                                _scope == 'mine'
                                    ? '\uB0B4 \uCE90\uB9AD\uD130'
                                    : '\uACF5\uC720 \uCE90\uB9AD\uD130',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.ink.withValues(alpha: 0.82),
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _SaveModeSelector extends StatelessWidget {
  const _SaveModeSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButtonTheme(
        data: SegmentedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? const Color(0xFFDDEBFF)
                  : Colors.white.withValues(alpha: 0.92);
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              return states.contains(WidgetState.selected)
                  ? AppTheme.ink
                  : AppTheme.ink.withValues(alpha: 0.72);
            }),
            side: WidgetStateProperty.resolveWith((states) {
              return BorderSide(
                color: states.contains(WidgetState.selected)
                    ? const Color(0xFF6EA3FF)
                    : AppTheme.tacticalBlue.withValues(alpha: 0.42),
                width: states.contains(WidgetState.selected) ? 1.8 : 1.1,
              );
            }),
            textStyle: WidgetStateProperty.all(
              const TextStyle(fontWeight: FontWeight.w900),
            ),
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            ),
          ),
        ),
        child: SegmentedButton<String>(
          showSelectedIcon: true,
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(
              value: 'share',
              icon: Icon(Icons.ios_share_rounded),
              label: Text('\uC804\uCCB4 \uACF5\uAC1C'),
            ),
            ButtonSegment<String>(
              value: 'followers',
              icon: Icon(Icons.people_alt_rounded),
              label: Text('\uD314\uB85C\uC6CC \uACF5\uAC1C'),
            ),
            ButtonSegment<String>(
              value: 'archive',
              icon: Icon(Icons.inventory_2_rounded),
              label: Text('\uC18C\uC7A5'),
            ),
          ],
          selected: <String>{selected},
          onSelectionChanged: (Set<String> values) {
            Feedback.forTap(context);
            SystemSound.play(SystemSoundType.click);
            onChanged(values.first);
          },
        ),
      ),
    );
  }
}

String _visibilityFromSaveMode(String saveMode) {
  return switch (saveMode) {
    'share' => 'public',
    'followers' => 'followers',
    _ => 'private',
  };
}

String _saveModeFromVisibility(String visibility) {
  return switch (visibility) {
    'public' => 'share',
    'followers' => 'followers',
    _ => 'archive',
  };
}

class _ArchiveScreen extends StatelessWidget {
  const _ArchiveScreen({
    required this.albums,
    required this.albumDiaryCounts,
    required this.albumDiariesByTitle,
    required this.selectedAlbum,
    required this.isLoading,
    required this.controller,
    required this.onBack,
    required this.onCreateAlbum,
    required this.onAlbumSelected,
    required this.onDeleteAlbum,
    required this.onOpenDiary,
    required this.onRemoveDiary,
    required this.onDeleteDiary,
    required this.onRefresh,
  });

  final List<String> albums;
  final Map<String, int> albumDiaryCounts;
  final Map<String, List<DiaryModel>> albumDiariesByTitle;
  final String? selectedAlbum;
  final bool isLoading;
  final TextEditingController controller;
  final VoidCallback onBack;
  final ValueChanged<String> onCreateAlbum;
  final ValueChanged<String> onAlbumSelected;
  final Future<void> Function(String albumTitle) onDeleteAlbum;
  final ValueChanged<DiaryModel> onOpenDiary;
  final Future<void> Function(String albumTitle, DiaryModel diary)
  onRemoveDiary;
  final Future<void> Function(String albumTitle, DiaryModel diary)
  onDeleteDiary;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 12 : 46,
        mobile ? 10 : 18,
        mobile ? 12 : 46,
        mobile ? 78 : 24,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: mobile ? double.infinity : 1120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _FigmaBackButton(onTap: onBack),
                  const Gap(12),
                  const _FigmaPill(text: '\uC568\uBC94 \uB9CC\uB4E4\uAE30'),
                ],
              ),
              const Gap(16),
              mobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextField(
                          controller: controller,
                          decoration: _finalMobileField(
                            '\uC568\uBC94 \uC774\uB984',
                          ),
                          onSubmitted: onCreateAlbum,
                        ),
                        const Gap(8),
                        SizedBox(
                          height: 44,
                          child: FilledButton.icon(
                            onPressed: () => onCreateAlbum(controller.text),
                            icon: const Icon(Icons.create_new_folder_rounded),
                            label: const Text('\uB9CC\uB4E4\uAE30'),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: <Widget>[
                        Expanded(
                          child: TextField(
                            controller: controller,
                            decoration: _figmaField(
                              '\uC568\uBC94 \uC774\uB984',
                            ),
                            onSubmitted: onCreateAlbum,
                          ),
                        ),
                        const Gap(10),
                        FilledButton.icon(
                          onPressed: () => onCreateAlbum(controller.text),
                          icon: const Icon(Icons.create_new_folder_rounded),
                          label: const Text('\uB9CC\uB4E4\uAE30'),
                        ),
                      ],
                    ),
              const Gap(18),
              Expanded(
                child: albums.isEmpty
                    ? const Center(
                        child: Text(
                          '\uC544\uC9C1 \uC568\uBC94\uC774 \uC5C6\uC2B5\uB2C8\uB2E4.',
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: mobile ? 180 : 210,
                          mainAxisSpacing: mobile ? 10 : 14,
                          crossAxisSpacing: mobile ? 10 : 14,
                          childAspectRatio: mobile ? 1.18 : 1.45,
                        ),
                        itemCount: albums.length,
                        itemBuilder: (BuildContext context, int index) {
                          final albumTitle = albums[index];
                          final diaryCount = albumDiaryCounts[albumTitle] ?? 0;
                          final isSelected = selectedAlbum == albumTitle;
                          return _LifeFourCutAlbumCard(
                            title: albumTitle,
                            diaryCount: diaryCount,
                            isSelected: isSelected,
                            onTap: () {
                              onAlbumSelected(albumTitle);
                              _showAlbumDiariesDialog(context, albumTitle);
                            },
                            onDelete: () => onDeleteAlbum(albumTitle),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAlbumDiariesDialog(BuildContext context, String albumTitle) {
    final diaries = albumDiariesByTitle[albumTitle] ?? const <DiaryModel>[];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: _LifeFourCutAlbumInteriorFrame(
              albumTitle: albumTitle,
              isLoading: isLoading,
              isEmpty: diaries.isEmpty,
              onRefresh: () {
                Navigator.of(context).pop();
                unawaited(onRefresh());
              },
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : diaries.isEmpty
                  ? const Center(
                      child: Text(
                        '\uC800\uC7A5\uB41C \uC77C\uAE30\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                      itemCount: diaries.length,
                      separatorBuilder: (_, _) => const Gap(10),
                      itemBuilder: (BuildContext context, int index) {
                        final diary = diaries[index];
                        return _ArchiveDiaryTile(
                          diary: diary,
                          onOpen: () => onOpenDiary(diary),
                          onRemove: () => onRemoveDiary(albumTitle, diary),
                          onDelete: () => onDeleteDiary(albumTitle, diary),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}

class _ArchiveDiaryTile extends StatelessWidget {
  const _ArchiveDiaryTile({
    required this.diary,
    required this.onOpen,
    required this.onRemove,
    required this.onDelete,
  });

  final DiaryModel diary;
  final VoidCallback onOpen;
  final Future<void> Function() onRemove;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    final title = diary.title?.trim().isNotEmpty == true
        ? diary.title!.trim()
        : '\uC81C\uBAA9 \uC5C6\uB294 \uC77C\uAE30';
    final dateText = diary.diaryAt == null
        ? ''
        : '${diary.diaryAt!.year}.${diary.diaryAt!.month.toString().padLeft(2, '0')}.${diary.diaryAt!.day.toString().padLeft(2, '0')}';

    return _PressableScale(
      onTap: onOpen,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          border: Border.all(color: const Color(0xFFC7DFFF)),
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 74,
                height: 74,
                child: _ArchiveDiaryPreview(
                  imageUrls: _diaryImageUrlsReadingOrder(diary.imageUrls),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF5B8EEB),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      [
                        dateText,
                        _weatherLabel(diary.weather.value),
                      ].where((String text) => text.isNotEmpty).join(' / '),
                      style: const TextStyle(
                        color: Color(0xFF8EA0C0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      diary.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF526071)),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: '\uBCF4\uAD00\uD568 \uBA54\uB274',
                onSelected: (String value) async {
                  if (value == 'remove') {
                    await onRemove();
                  } else if (value == 'delete') {
                    await onDelete();
                  }
                },
                itemBuilder: (BuildContext context) {
                  return const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'remove',
                      child: Text('\uC568\uBC94\uC5D0\uC11C \uBE7C\uAE30'),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text('\uC77C\uAE30 \uC0AD\uC81C'),
                    ),
                  ];
                },
                icon: const Icon(Icons.more_horiz_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LifeFourCutAlbumInteriorFrame extends StatelessWidget {
  const _LifeFourCutAlbumInteriorFrame({
    required this.albumTitle,
    required this.isLoading,
    required this.isEmpty,
    required this.onRefresh,
    required this.child,
  });

  final String albumTitle;
  final bool isLoading;
  final bool isEmpty;
  final VoidCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF232936),
        borderRadius: BorderRadius.circular(22),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _FilmPerforationDot(active: !isEmpty),
                const Gap(8),
                Expanded(
                  child: Text(
                    albumTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  color: Colors.white,
                  tooltip: '\uC0C8\uB85C\uACE0\uCE68',
                ),
              ],
            ),
            const Gap(8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const _FilmPerforationRail(),
                  const Gap(10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FBFF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.pastelBlue.withValues(alpha: 0.75),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: child,
                      ),
                    ),
                  ),
                  const Gap(10),
                  const _FilmPerforationRail(),
                ],
              ),
            ),
            const Gap(10),
            Text(
              isLoading
                  ? 'PRINTING...'
                  : isEmpty
                  ? 'EMPTY ALBUM'
                  : 'MY DIARY FILM',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilmPerforationRail extends StatelessWidget {
  const _FilmPerforationRail();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List<Widget>.generate(
          8,
          (int index) => Container(
            width: 10,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilmPerforationDot extends StatelessWidget {
  const _FilmPerforationDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppTheme.pastelGreen : AppTheme.pastelBlue,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: (active ? AppTheme.pastelGreen : AppTheme.pastelBlue)
                .withValues(alpha: 0.55),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }
}

class _LifeFourCutAlbumCard extends StatelessWidget {
  const _LifeFourCutAlbumCard({
    required this.title,
    required this.diaryCount,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  final String title;
  final int diaryCount;
  final bool isSelected;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return _PressableScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.pastelBlue.withValues(alpha: 0.46)
              : Colors.white.withValues(alpha: 0.82),
          border: Border.all(
            color: isSelected ? AppTheme.tacticalBlue : const Color(0xFFBFD9FF),
            width: isSelected ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppTheme.ink.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        const Color(0xFFFFFFFF).withValues(alpha: 0.72),
                        AppTheme.pastelBlue.withValues(alpha: 0.18),
                        AppTheme.pastelGreen.withValues(alpha: 0.16),
                      ],
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  tooltip: '\uC568\uBC94 \uBA54\uB274',
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: AppTheme.tacticalBlue.withValues(alpha: 0.60),
                  ),
                  onSelected: (String value) async {
                    if (value == 'delete') {
                      await onDelete();
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return const <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'delete',
                        child: Text('\uC568\uBC94 \uC0AD\uC81C'),
                      ),
                    ];
                  },
                ),
              ),
              Positioned(
                right: 12,
                bottom: 10,
                child: Icon(
                  Icons.folder_rounded,
                  color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
                  size: 32,
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF5B78D6),
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        '$diaryCount\uAC1C \uC77C\uAE30',
                        style: const TextStyle(
                          color: Color(0xFF8EA0C0),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.tacticalBlue
                        : const Color(0xFFC7DFFF),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArchiveDiaryPreview extends StatelessWidget {
  const _ArchiveDiaryPreview({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    String? url;
    for (final item in imageUrls) {
      if (item.trim().isNotEmpty) {
        url = item;
        break;
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFEAF3FF),
          border: Border.all(color: const Color(0xFF9FC4FF)),
        ),
        child: url == null || url.isEmpty
            ? const Icon(Icons.auto_stories_rounded, color: Color(0xFF8BB9FF))
            : _StorageAwareImage(url: url),
      ),
    );
  }
}

String _weatherLabel(String value) {
  return switch (value) {
    'cloudy' => '\uD750\uB9BC',
    'rainy' => '\uBE44',
    'snowy' => '\uB208',
    'foggy' => '\uC548\uAC1C',
    _ => '\uB9D1\uC74C',
  };
}

IconData _weatherIcon(String value) {
  return switch (value) {
    'cloudy' => Icons.cloud_rounded,
    'rainy' => Icons.grain_rounded,
    'snowy' => Icons.ac_unit_rounded,
    'foggy' => Icons.foggy,
    _ => Icons.wb_sunny_rounded,
  };
}

String _socialTagLabel(String value) {
  return switch (value) {
    'card_slide' ||
    'image_focus' ||
    'qa_slide' ||
    'reaction_focus' => '\uCE74\uB4DC \uC2AC\uB77C\uC774\uB4DC',
    'comics_ld' => '\uADF9\uD654\uD615',
    'anime_ld' => '\uC560\uB2C8\uD615',
    'comics_sd' => '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615',
    'anime_sd' => '\uCE90\uC8FC\uC5BC \uB9CC\uD654\uD615',
    'simple_2d' => '\uCE90\uB9AD\uD130\uD615',
    'realistic_3d' => '\uC785\uCCB4 \uB80C\uB354\uB9C1',
    'daily_comic' => '\uC720\uCF8C\uD558\uACE0 \uC6C3\uAE34 \uB0A0',
    'serious' => '\uC9C4\uC9C0\uD558\uACE0 \uCC28\uBD84\uD55C \uB0A0',
    'fantasy_action' => '\uAC1C\uADF8/\uC561\uC158',
    'healing_romance' => '\uB530\uB73B\uD558\uACE0 \uD589\uBCF5\uD55C \uB0A0',
    'growth' =>
      '\uBFCC\uB73B\uD558\uACE0 \uC131\uCDE8\uAC10 \uC788\uB294 \uB0A0',
    'hard_day' => '\uD798\uB4E4\uACE0 \uC9C0\uCE5C \uB0A0',
    _ => value,
  };
}

List<String> _socialDisplayTagsForPost(SocialFeedItemModel post) {
  return <String>[
    _socialDisplayTagText(post.artStyle.value),
    _socialDisplayTagText(post.genre.value),
  ];
}

String _socialDisplayTagText(String value) => _socialTagLabel(value);

String _filterChipLabel(String value) {
  return switch (value) {
    'comics_ld' => '\uADF9\uD654',
    'anime_ld' => '\uC560\uB2C8',
    'comics_sd' || 'anime_sd' => '\uCE90\uC8FC\uC5BC',
    'simple_2d' => '\uCE90\uB9AD\uD130',
    'realistic_3d' => '3D',
    'daily_comic' => '\uC720\uCF8C',
    'serious' => '\uC9C4\uC9C0',
    'healing_romance' => '\uB530\uB73B',
    'growth' => '\uBFCC\uB73B',
    'hard_day' => '\uC9C0\uCE5C',
    _ => _socialDisplayTagText(value),
  };
}

String _socialTagText(String value) => _socialTagLabel(value);

IconData _socialTagIcon(String value) {
  return switch (value) {
    'image_focus' => Icons.image_rounded,
    'qa_slide' => Icons.forum_rounded,
    'reaction_focus' => Icons.sentiment_very_satisfied_rounded,
    'comics_ld' || 'comics_sd' => Icons.auto_stories_rounded,
    'anime_ld' || 'anime_sd' => Icons.star_rounded,
    'simple_2d' => Icons.favorite_rounded,
    'realistic_3d' => Icons.view_in_ar_rounded,
    'daily_comic' => Icons.wb_sunny_rounded,
    'serious' => Icons.nights_stay_rounded,
    'fantasy_action' => Icons.bolt_rounded,
    'healing_romance' => Icons.local_florist_rounded,
    'growth' => Icons.emoji_events_rounded,
    'hard_day' => Icons.volunteer_activism_rounded,
    _ => Icons.sell_rounded,
  };
}
