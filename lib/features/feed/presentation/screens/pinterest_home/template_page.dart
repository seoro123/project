// ignore_for_file: unused_element, unused_element_parameter

part of '../pinterest_home_screen.dart';

class _TemplatePage extends StatefulWidget {
  const _TemplatePage();

  @override
  State<_TemplatePage> createState() => _TemplatePageState();
}

class _TemplatePageState extends State<_TemplatePage> {
  final TextEditingController _nameController = TextEditingController(
    text: '\uB098\uC758 \uCE90\uB9AD\uD130',
  );
  final TextEditingController _memoController = TextEditingController();
  final Set<String> _selectedTags = <String>{};
  int _step = 0;
  String _mode = 'prose';
  String _templateName = '\uB098\uC758 \uCE90\uB9AD\uD130';
  String? _templatePreviewImageUrl;
  String _templateSaveMode = 'share';
  String _templateScope = 'mine';
  bool _isSaving = false;
  int _templateRefreshTick = 0;
  Uint8List? _referenceImageBytes;
  String? _referenceImageName;
  bool _isRestoringDraft = false;
  bool _hasCharacterDraft = false;
  bool _isEditingDraft = false;

  static const Map<String, List<String>> _tagGroups = <String, List<String>>{
    '\uC678\uAD00': <String>[
      '\uBC1D\uC740 \uC678\uAD00',
      '\uB3D9\uADF8\uB780 \uC678\uAD00',
      '\uCC28\uBD84\uD55C \uC678\uAD00',
      '\uACE0\uC591\uC774\uC0C1',
      '\uC8FC\uADFC\uAE68',
    ],
    '\uBA38\uB9AC': <String>[
      '\uAC80\uC740 \uBA38\uB9AC',
      '\uAC08\uC0C9 \uBA38\uB9AC',
      '\uAE08\uBC1C',
      '\uC740\uBC1C',
      '\uBD84\uD64D \uBA38\uB9AC',
      '\uB2E8\uBC1C',
      '\uC911\uB2E8\uBC1C',
      '\uAE34 \uBA38\uB9AC',
      '\uC6E8\uC774\uBE0C',
      '\uD3EC\uB2C8\uD14C\uC77C',
    ],
    '\uB208': <String>[
      '\uD478\uB978 \uB208',
      '\uAC08\uC0C9 \uB208',
      '\uCD08\uB85D \uB208',
      '\uAC80\uC740 \uB208',
      '\uBC18\uC9DD\uC774\uB294 \uB208',
      '\uB3D9\uADF8\uB780 \uB208',
      '\uC67C\uCABD \uD5E4\uC5B4\uD540',
      '\uC624\uB978\uCABD \uD5E4\uC5B4\uD540',
      '\uBCC4\uBE5B \uD5E4\uC5B4\uD540',
    ],
    '\uC131\uACA9': <String>[
      '\uCC28\uBD84\uD568',
      '\uC7A5\uB09C\uC2A4\uB7EC\uC6C0',
      '\uC218\uC90D\uC74C',
      '\uD65C\uBC1C\uD568',
      '\uB3C4\uB3C4\uD568',
      '\uB2E4\uC815\uD568',
      '\uCFE8\uD568',
    ],
    '\uC758\uC0C1': <String>[
      '\uD6C4\uB4DC',
      '\uAD50\uBCF5',
      '\uC2A4\uD53C\uCE74',
      '\uB2C8\uD2B8',
      '\uC815\uC7A5',
      '\uC2A4\uC6E8\uD130',
      '\uC2A4\uCEE4\uD2B8',
      '\uCCAD\uBC14\uC9C0',
      '\uC6B4\uB3D9\uBCF5',
    ],
    '\uC18C\uD488': <String>[
      '\uB9AC\uBCF8',
      '\uBAA8\uC790',
      '\uC548\uACBD',
      '\uD5E4\uB4DC\uD3F0',
      '\uBA38\uB9AC\uB760',
      '\uAC00\uBC29',
    ],
    '\uBD84\uC704\uAE30': <String>[
      '\uB3D9\uD654\uD48D',
      '\uBBF8\uB798\uD48D',
      '\uB3D9\uC6D0\uBB34\uB4DC',
      '\uB9C8\uBC95\uC18C\uB140',
      '\uC544\uC774\uB3CC',
      '\uD654\uC0AC\uD568',
      '\uB85C\uB9E8\uD2F1',
    ],
  };

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleTemplateNameChanged);
    _memoController.addListener(_handleTemplateMemoChanged);
    unawaited(_restoreCharacterDraft());
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleTemplateNameChanged);
    _memoController.removeListener(_handleTemplateMemoChanged);
    _nameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 1) {
      return _buildModeSelector(context);
    }
    if (_step == 2) {
      return _buildCreator(context);
    }

    final mobile = _isMobileLayout(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final mobileColumns = screenWidth >= 720 ? 3 : 2;
    final mobileCardSpacing = screenWidth >= 520 ? 12.0 : 8.0;
    final mobileCardWidth =
        ((screenWidth - 34 - (mobileCardSpacing * (mobileColumns - 1))) /
                mobileColumns)
            .clamp(150.0, 236.0)
            .toDouble();
    final cardWidth = mobile ? mobileCardWidth : 176.0;
    final cardHeight = mobile ? 214.0 : 236.0;
    final mobileGridWidth =
        (cardWidth * mobileColumns) + (mobileCardSpacing * (mobileColumns - 1));

    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 8 : 28,
        mobile ? 10 : 18,
        mobile ? 8 : 28,
        mobile ? 64 : 26,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: mobile ? double.infinity : 1120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '\uCE90\uB9AD\uD130',
                style: TextStyle(
                  color: const Color(0xFF6EA3FF),
                  fontWeight: FontWeight.w900,
                  fontSize: mobile ? 14 : 16,
                ),
              ),
              Gap(mobile ? 6 : 8),
              Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<String>(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return AppTheme.tacticalBlue.withValues(alpha: 0.96);
                        }
                        return AppTheme.academyLilac.withValues(alpha: 0.42);
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.white;
                        }
                        return AppTheme.graphite;
                      }),
                      side: WidgetStateProperty.resolveWith((states) {
                        final selected = states.contains(WidgetState.selected);
                        return BorderSide(
                          color: selected
                              ? AppTheme.graphite
                              : AppTheme.tacticalBlue.withValues(alpha: 0.62),
                          width: selected ? 1.8 : 1.2,
                        );
                      }),
                      shadowColor: WidgetStateProperty.all(
                        AppTheme.graphite.withValues(alpha: 0.36),
                      ),
                      elevation: WidgetStateProperty.resolveWith((states) {
                        return states.contains(WidgetState.selected) ? 6 : 2;
                      }),
                      textStyle: WidgetStateProperty.all(
                        const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 10.5,
                        ),
                      ),
                      visualDensity: mobile
                          ? VisualDensity.compact
                          : VisualDensity.standard,
                    ),
                    segments: const <ButtonSegment<String>>[
                      ButtonSegment<String>(
                        value: 'mine',
                        icon: Icon(Icons.bookmark_rounded),
                        label: Text('\uB0B4 \uCE90\uB9AD\uD130'),
                      ),
                      ButtonSegment<String>(
                        value: 'drafts',
                        icon: Icon(Icons.inventory_2_rounded),
                        label: Text('\uC784\uC2DC\uC800\uC7A5'),
                      ),
                      ButtonSegment<String>(
                        value: 'others',
                        icon: Icon(Icons.public_rounded),
                        label: Text('\uACF5\uC720'),
                      ),
                    ],
                    selected: <String>{_templateScope},
                    onSelectionChanged: (Set<String> values) {
                      setState(() {
                        _templateScope = values.first;
                        _templateRefreshTick++;
                      });
                    },
                  ),
                ),
              ),
              Gap(mobile ? 6 : 8),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: mobile
                        ? Colors.transparent
                        : Colors.white.withValues(alpha: 0.92),
                    border: mobile
                        ? null
                        : Border.all(color: const Color(0xFFE6F0FF)),
                    borderRadius: BorderRadius.circular(mobile ? 0 : 0),
                  ),
                  child: Stack(
                    children: <Widget>[
                      if (!mobile)
                        const Positioned.fill(child: _FigmaPastelWash()),
                      FutureBuilder<List<PersonaModel>>(
                        key: ValueKey<int>(_templateRefreshTick),
                        future: _fetchSharedTemplates(),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<List<PersonaModel>> snapshot,
                            ) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const <Widget>[
                                      CircularProgressIndicator(strokeWidth: 2),
                                      Gap(12),
                                      Text(
                                        '\uCE90\uB9AD\uD130\uB97C \uBD88\uB7EC\uC624\uB294 \uC911',
                                        style: TextStyle(
                                          color: AppTheme.tacticalBlue,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return const Center(
                                  child: Text(
                                    '\uCE90\uB9AD\uD130\uB97C \uBD88\uB7EC\uC624\uC9C0 \uBABB\uD588\uC2B5\uB2C8\uB2E4.',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              final templates = _filterTemplatesForScope(
                                snapshot.data ?? const <PersonaModel>[],
                              );
                              if (_templateScope == 'drafts') {
                                return _buildDraftCharacterTab(mobile);
                              }
                              final cards = <Widget>[
                                if (_templateScope == 'mine')
                                  _TemplateGalleryCard(
                                    title:
                                        '\uC0C8 \uCE90\uB9AD\uD130\n\uB9CC\uB4E4\uAE30',
                                    isCreateCard: true,
                                    onTap: () => setState(() => _step = 1),
                                  ),
                                ...templates.map(
                                  (PersonaModel template) =>
                                      _TemplateGalleryCard(
                                        title: template.name,
                                        badge: template.isPublic
                                            ? '\uACF5\uC720'
                                            : '\uC18C\uC7A5',
                                        imageUrl:
                                            template.imageUrl ??
                                            template.baseImageUrl,
                                        onTap: () {
                                          _showTemplateDetail(
                                            context,
                                            template,
                                          );
                                        },
                                      ),
                                ),
                              ];

                              if (cards.isEmpty) {
                                return Center(
                                  child: Text(
                                    _templateScope == 'mine'
                                        ? '\uC544\uC9C1 \uC18C\uC7A5\uD55C \uCE90\uB9AD\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.'
                                        : '\uC544\uC9C1 \uACF5\uAC1C \uCE90\uB9AD\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
                                    textAlign: TextAlign.center,
                                  ),
                                );
                              }

                              return SingleChildScrollView(
                                padding: EdgeInsets.fromLTRB(
                                  mobile ? 8 : 42,
                                  mobile ? 10 : 34,
                                  mobile ? 8 : 42,
                                  mobile ? 12 : 34,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: mobile ? mobileGridWidth : null,
                                    child: Wrap(
                                      alignment: mobile
                                          ? WrapAlignment.start
                                          : WrapAlignment.center,
                                      runAlignment: mobile
                                          ? WrapAlignment.start
                                          : WrapAlignment.center,
                                      spacing: mobile ? mobileCardSpacing : 30,
                                      runSpacing: mobile ? 8 : 34,
                                      children: cards.indexed
                                          .map(
                                            ((int, Widget) entry) => SizedBox(
                                              width: cardWidth,
                                              height: cardHeight,
                                              child: _DimensionalCardSlot(
                                                index: entry.$1,
                                                depth: 0.72,
                                                child: entry.$2,
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                ),
                              );
                            },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<PersonaModel>> _fetchSharedTemplates() async {
    if (!SupabaseRuntime.isConfigured) {
      return const <PersonaModel>[];
    }

    final user = await _ensureSupabaseUserProfile();
    final repository = SupabasePersonaRepository(Supabase.instance.client);
    return repository.fetchVisibleTemplates(user.id);
  }

  List<PersonaModel> _filterTemplatesForScope(List<PersonaModel> templates) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (_templateScope == 'mine') {
      return templates
          .where((PersonaModel template) => template.userId == currentUserId)
          .toList();
    }

    return templates
        .where((PersonaModel template) => template.isPublic)
        .followedBy(
          templates.where(
            (PersonaModel template) =>
                !template.isPublic &&
                template.templateVisibility == 'followers',
          ),
        )
        .toSet()
        .toList();
  }

  Widget _buildDraftCharacterTab(bool mobile) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        mobile ? 12 : 34,
        mobile ? 14 : 28,
        mobile ? 12 : 34,
        mobile ? 18 : 30,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: _hasCharacterDraft
              ? _CharacterDraftPublishPanel(
                  name: _templateName,
                  memo: _memoController.text,
                  tags: _selectedTags.toList(),
                  imageUrl: _templatePreviewImageUrl,
                  imageBytes: _referenceImageBytes,
                  isPublishing: _isSaving,
                  onEdit: () {
                    setState(() {
                      _isEditingDraft = true;
                      _step = 2;
                    });
                  },
                  onPublish: () =>
                      unawaited(_showCharacterDraftPublishSettings()),
                  onClear: () => unawaited(
                    _clearCharacterDraft(showSnackBar: true, clearForm: true),
                  ),
                )
              : _EmptyDraftCharacterPanel(
                  onCreate: () => setState(() => _step = 1),
                ),
        ),
      ),
    );
  }

  void _handleTemplateNameChanged() {
    if (_isRestoringDraft) {
      return;
    }
    final nextName = _nameController.text.trim();
    setState(() {
      _templateName = nextName.isEmpty
          ? '\uB098\uC758 \uCE90\uB9AD\uD130'
          : nextName;
    });
    _scheduleCharacterDraftSave();
  }

  void _handleTemplateMemoChanged() {
    if (_isRestoringDraft) {
      return;
    }
    setState(() {});
    _scheduleCharacterDraftSave();
  }

  void _startCharacterDraft(String mode) {
    _isRestoringDraft = true;
    setState(() {
      _isEditingDraft = false;
      _mode = mode;
      _templateName = '\uB098\uC758 \uCE90\uB9AD\uD130';
      _templatePreviewImageUrl = null;
      _referenceImageBytes = null;
      _referenceImageName = null;
      _selectedTags.clear();
      _step = 2;
    });
    _nameController.text = _templateName;
    _memoController.clear();
    _isRestoringDraft = false;
  }

  Widget _buildModeSelector(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        mobile ? 8 : 28,
        mobile ? 8 : 18,
        mobile ? 8 : 28,
        mobile ? 92 : 26,
      ),
      child: _DiaryFigmaFrame(
        title: '\uCE90\uB9AD\uD130 \uB9CC\uB4E4\uAE30',
        onClose: () => setState(() => _step = 0),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            mobile ? 18 : 46,
            mobile ? 18 : 28,
            mobile ? 18 : 46,
            mobile ? 22 : 34,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final compact = constraints.maxWidth < 700;
              final cards = <Widget>[
                _FigmaGradientButton(
                  title: 'PROSE START',
                  subtitle: '\uC904\uAE00\uB85C \uB9CC\uB4E4\uAE30',
                  icon: Icons.edit_note_rounded,
                  colors: const <Color>[
                    AppTheme.pastelRose,
                    AppTheme.pastelPeach,
                  ],
                  onTap: () => _startCharacterDraft('prose'),
                ),
                _FigmaGradientButton(
                  title: 'TAG START',
                  subtitle: '\uD0DC\uADF8\uB85C \uB9CC\uB4E4\uAE30',
                  icon: Icons.grid_view_rounded,
                  colors: const <Color>[
                    AppTheme.pastelBlue,
                    AppTheme.pastelGreen,
                  ],
                  onTap: () => _startCharacterDraft('tags'),
                ),
              ];

              if (compact) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(height: 118, child: cards.first),
                    const Gap(18),
                    SizedBox(height: 118, child: cards.last),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  Expanded(child: cards.first),
                  const Gap(34),
                  Expanded(child: cards.last),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCreator(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        mobile ? 12 : 28,
        mobile ? 12 : 18,
        mobile ? 12 : 28,
        mobile ? 92 : 26,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: _GlassPanel(
            child: Padding(
              padding: EdgeInsets.all(mobile ? 14 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      IconButton.filledTonal(
                        tooltip: '\uB4A4\uB85C',
                        onPressed: () => setState(() => _step = 1),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Text(
                          _isEditingDraft
                              ? '\uC784\uC2DC\uC800\uC7A5 \uC218\uC815'
                              : _mode == 'tags'
                              ? '\uD0DC\uADF8\uB85C \uB9CC\uB4E4\uAE30'
                              : '\uC904\uAE00\uB85C \uB9CC\uB4E4\uAE30',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.graphite,
                              ),
                        ),
                      ),
                      const SizedBox(width: 52),
                    ],
                  ),
                  const Gap(22),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints _) {
                      final showProseEditor =
                          _isEditingDraft || _mode == 'prose';
                      final showTagEditor = _isEditingDraft || _mode == 'tags';
                      final editor = DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.74),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppTheme.tacticalBlue.withValues(
                              alpha: 0.30,
                            ),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: AppTheme.tacticalBlue.withValues(
                                alpha: 0.08,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(mobile ? 12 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              TextField(
                                controller: _nameController,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  labelText: '\uCE90\uB9AD\uD130 \uC774\uB984',
                                  hintText: '\uC774\uB984',
                                ),
                              ),
                              const Gap(14),
                              _ReferenceFilePicker(
                                imageBytes: _referenceImageBytes,
                                imageName: _referenceImageName,
                                isBusy: _isSaving,
                                onPick: _pickReferenceImage,
                                onClear: _clearReferenceImage,
                              ),
                              if (showProseEditor) ...<Widget>[
                                const Gap(14),
                                SizedBox(
                                  height: 160,
                                  child: TextField(
                                    controller: _memoController,
                                    textAlign: TextAlign.center,
                                    textAlignVertical: TextAlignVertical.top,
                                    expands: true,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      alignLabelWithHint: true,
                                      labelText: '\uC904\uAE00 \uC124\uC815',
                                      hintText:
                                          '\uC678\uD615, \uC131\uACA9, \uC758\uC0C1',
                                    ),
                                  ),
                                ),
                              ],
                              if (showTagEditor) ...<Widget>[
                                const Gap(14),
                                _CharacterTagPicker(
                                  groups: _tagGroups,
                                  selectedTags: _selectedTags,
                                  onTagToggled: _toggleTemplateTag,
                                  onClear: () {
                                    setState(() => _selectedTags.clear());
                                    _scheduleCharacterDraftSave();
                                  },
                                ),
                              ],
                              const Gap(14),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _isSaving
                                          ? null
                                          : () => unawaited(
                                              _finishCharacterDraft(),
                                            ),
                                      icon: const Icon(
                                        Icons.archive_outlined,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        '\uC784\uC2DC\uC800\uC7A5',
                                      ),
                                    ),
                                  ),
                                  const Gap(10),
                                  IconButton.filledTonal(
                                    tooltip:
                                        '\uC784\uC2DC\uC800\uC7A5 \uCE78\uC73C\uB85C \uB3CC\uC544\uAC00\uAE30',
                                    onPressed: _isSaving
                                        ? null
                                        : () => setState(() => _step = 0),
                                    icon: const Icon(Icons.view_module_rounded),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );

                      return editor;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickReferenceImage() async {
    try {
      final pickedImage = await pickReferenceImageFile();
      if (pickedImage == null) {
        return;
      }
      if (!mounted) {
        return;
      }
      if (!_isSupportedReferenceImageName(pickedImage.name)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\uCC38\uACE0 \uC774\uBBF8\uC9C0\uB294 JPG, PNG, WebP, GIF\uB9CC \uC0AC\uC6A9\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4.',
            ),
          ),
        );
        return;
      }

      setState(() {
        _referenceImageBytes = pickedImage.bytes;
        _referenceImageName = pickedImage.name;
      });
      _scheduleCharacterDraftSave();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '\uC774\uBBF8\uC9C0 \uC120\uD0DD\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. $error',
          ),
        ),
      );
    }
  }

  void _clearReferenceImage() {
    setState(() {
      _referenceImageBytes = null;
      _referenceImageName = null;
    });
    _scheduleCharacterDraftSave();
  }

  Future<String?> _uploadReferenceImage(String userId) async {
    final bytes = _referenceImageBytes;
    if (bytes == null) {
      return null;
    }

    final extension = _imageExtensionFromName(_referenceImageName);
    final storagePath =
        '$userId/persona-references/${DateTime.now().millisecondsSinceEpoch}.$extension';
    await Supabase.instance.client.storage
        .from('diary-assets')
        .uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(
            contentType: _imageContentType(extension),
            upsert: true,
          ),
        );

    return Supabase.instance.client.storage
        .from('diary-assets')
        .getPublicUrl(storagePath);
  }

  String _imageExtensionFromName(String? name) {
    final lower = (name ?? '').toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'jpg';
    }
    if (lower.endsWith('.webp')) {
      return 'webp';
    }
    if (lower.endsWith('.gif')) {
      return 'gif';
    }
    return 'png';
  }

  bool _isSupportedReferenceImageName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif');
  }

  String _imageContentType(String extension) {
    return switch (extension) {
      'jpg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      _ => 'image/png',
    };
  }

  void _toggleTemplateTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
    _scheduleCharacterDraftSave();
  }

  void _scheduleCharacterDraftSave() {
    // Drafts are persisted explicitly with the temporary save action.
  }

  Future<void> _restoreCharacterDraft() async {
    try {
      if (!SupabaseRuntime.isConfigured) {
        return;
      }
      final user = await _ensureSupabaseUserProfile();
      final draft = await SupabasePersonaRepository(
        Supabase.instance.client,
      ).fetchPersonaDraft(user.id);
      if (!mounted) {
        return;
      }
      if (draft == null) {
        setState(() {
          _hasCharacterDraft = false;
        });
        return;
      }

      _isRestoringDraft = true;
      setState(() {
        _mode = draft.inputMode == PersonaInputMode.tags ? 'tags' : 'prose';
        _templateName = draft.name;
        _templateSaveMode = _saveModeFromVisibility(draft.templateVisibility);
        _selectedTags
          ..clear()
          ..addAll(draft.appearanceTags);
        _referenceImageBytes = null;
        _referenceImageName = null;
        _templatePreviewImageUrl = draft.referenceImageUrl;
        _hasCharacterDraft = true;
      });
      _nameController.text = _templateName;
      _memoController.text = draft.appearanceDescription;
      _isRestoringDraft = false;
    } catch (_) {
      _isRestoringDraft = false;
    }
  }

  Future<void> _saveCharacterDraft({required bool showSnackBar}) async {
    try {
      final user = await _ensureSupabaseUserProfile();
      final bytes = _referenceImageBytes;
      final referenceImageUrl = bytes == null
          ? _templatePreviewImageUrl
          : await _uploadReferenceImage(user.id);
      final draft = await SupabasePersonaRepository(Supabase.instance.client)
          .upsertPersonaDraft(
            userId: user.id,
            name: _templateName,
            appearanceDescription: _memoController.text,
            inputMode: _mode == 'tags'
                ? PersonaInputMode.tags
                : PersonaInputMode.prose,
            appearanceTags: _selectedTags.toList(),
            templateVisibility: _visibilityFromSaveMode(_templateSaveMode),
            referenceImageUrl: referenceImageUrl,
          );
      if (mounted) {
        setState(() {
          _hasCharacterDraft = true;
          _templatePreviewImageUrl = draft.referenceImageUrl;
          _referenceImageBytes = null;
          _referenceImageName = null;
          _templateScope = 'drafts';
          _templateRefreshTick++;
        });
      }
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '\uCE90\uB9AD\uD130 \uC124\uC815\uC744 \uC784\uC2DC \uC800\uC7A5\uD588\uC2B5\uB2C8\uB2E4.',
            ),
          ),
        );
      }
    } catch (error) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('\uC784\uC2DC \uC800\uC7A5 \uC2E4\uD328: $error'),
          ),
        );
      }
    }
  }

  Future<void> _finishCharacterDraft() async {
    await _saveCharacterDraft(showSnackBar: true);
    if (mounted) {
      setState(() {
        _isEditingDraft = false;
        _step = 0;
      });
    }
  }

  Future<void> _clearCharacterDraft({
    bool showSnackBar = false,
    bool clearForm = false,
  }) async {
    if (SupabaseRuntime.isConfigured) {
      final user = await _ensureSupabaseUserProfile();
      await SupabasePersonaRepository(
        Supabase.instance.client,
      ).deletePersonaDraft(user.id);
    }
    if (clearForm && mounted) {
      _isRestoringDraft = true;
      setState(() {
        _templateName = '\uB098\uC758 \uCE90\uB9AD\uD130';
        _templateSaveMode = 'share';
        _templatePreviewImageUrl = null;
        _referenceImageBytes = null;
        _referenceImageName = null;
        _selectedTags.clear();
        _hasCharacterDraft = false;
        _isEditingDraft = false;
      });
      _nameController.text = _templateName;
      _memoController.clear();
      _isRestoringDraft = false;
    }
    if (showSnackBar && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '\uC784\uC2DC\uC800\uC7A5\uC744 \uBE44\uC6E0\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
    }
  }

  Future<void> _showCharacterDraftPublishSettings() async {
    var draftSaveMode = _templateSaveMode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('\uCE90\uB9AD\uD130 \uCD5C\uC885 \uBC1C\uD589'),
              content: SizedBox(
                width: 520,
                child: _SaveModeSelector(
                  selected: draftSaveMode,
                  onChanged: (String value) {
                    setDialogState(() => draftSaveMode = value);
                  },
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
                  label: const Text('\uCD5C\uC885 \uBC1C\uD589'),
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

    setState(() => _templateSaveMode = draftSaveMode);
    await _saveCharacterDraft(showSnackBar: false);
    await _publishCharacterDraft();
  }

  Future<void> _publishCharacterDraft() async {
    await _createTemplate();
  }

  Future<void> _createTemplate() async {
    final memo = _memoController.text.trim();
    final tagPrompt = _selectedTags.join(', ');
    final savedReferenceImageUrl = _templatePreviewImageUrl;
    final prompt = [
      if (memo.isEmpty && tagPrompt.isEmpty)
        '\uC0AC\uC6A9\uC790\uAC00 \uC791\uC131\uD55C \uCE90\uB9AD\uD130',
      if (memo.isNotEmpty) memo,
      if (tagPrompt.isNotEmpty)
        '\uD0DC\uADF8\uB85C \uACE0\uC815\uD55C \uC678\uD615 \uC694\uC18C: $tagPrompt',
      '\uD45C\uC815\uC774 \uC0B4\uC544\uC788\uB294 \uADC0\uC5EC\uC6B4 \uC6F9\uD230 \uCE90\uB9AD\uD130 \uC544\uD2B8',
    ].join('\n');

    setState(() {
      _isSaving = true;
      _templatePreviewImageUrl = null;
    });

    try {
      final user = await _ensureSupabaseUserProfile();
      final referenceImageUrl = _referenceImageBytes == null
          ? savedReferenceImageUrl
          : await _uploadReferenceImage(user.id);
      final effectivePrompt = [
        if (referenceImageUrl != null)
          [
            'Reference image URL: $referenceImageUrl',
            'The uploaded image is the primary design source. Use image-derived visual cues before written tags.',
            'Extract safe visual cues from the actual image: face shape, eye shape and gaze, eyebrow impression, hair volume, bangs, hair length, skin tone, outfit colors, accessories, and overall mood.',
            'Reinterpret those cues as an original Korean diary webtoon character, not a direct likeness of the person in the photo.',
            'If written memo or selected tags conflict with the photo, follow the photo first. Use tags only as secondary style and mood hints.',
            'Final output must be exactly one original reusable character, not a character sheet, grid, collage, or multiple variations.',
          ].join('\\n'),
        prompt,
      ].join('\\n');
      if (mounted) {}
      final repository = SupabasePersonaRepository(Supabase.instance.client);
      final persona = await repository.createPersonaTemplate(
        userId: user.id,
        name: _templateName.trim().isEmpty
            ? '\uACF5\uC720 \uCE90\uB9AD\uD130'
            : _templateName.trim(),
        appearanceDescription: effectivePrompt,
        seed: DateTime.now().millisecondsSinceEpoch % 2147483647,
        inputMode: _mode == 'tags'
            ? PersonaInputMode.tags
            : PersonaInputMode.prose,
        appearanceTags: _selectedTags.toList(),
        expressionLibrary: const <String, String>{
          'happy': '\uD658\uD558\uAC8C \uC6C3\uB294 \uD45C\uC815',
          'sad': '\uB208\uBB3C\uC774 \uACE0\uC778 \uC2AC\uD508 \uD45C\uC815',
          'angry': '\uBD89\uC740 \uD45C\uC815\uC758 \uD654\uB09C \uC5BC\uAD74',
          'embarrassed':
              '\uB2F9\uD669\uD574 \uB540\uC744 \uD758\uB9AC\uB294 \uD45C\uC815',
          'calm': '\uD3C9\uC628\uD558\uACE0 \uCC28\uBD84\uD55C \uD45C\uC815',
        },
        isPublic: _templateSaveMode == 'share',
        templateVisibility: _visibilityFromSaveMode(_templateSaveMode),
        referenceImageUrl: referenceImageUrl,
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            persona.generationStatus == 'failed'
                ? '\uCE90\uB9AD\uD130\uB294 \uC800\uC7A5\uB410\uC9C0\uB9CC \uC774\uBBF8\uC9C0\uB294 \uC544\uC9C1 \uC644\uC131\uB418\uC9C0 \uC54A\uC558\uC2B5\uB2C8\uB2E4: '
                      '${_friendlyTemplateError(persona.errorMessage ?? 'unknown error')}'
                : _templateSaveMode == 'share'
                ? '\uCE90\uB9AD\uD130\uAC00 \uACF5\uC720\uC640 \uB0B4 \uCE90\uB9AD\uD130\uC5D0 \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4.'
                : _templateSaveMode == 'followers'
                ? '\uCE90\uB9AD\uD130\uAC00 \uD314\uB85C\uC6CC \uACF5\uAC1C\uB85C \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4.'
                : '\uCE90\uB9AD\uD130\uAC00 \uB0B4 \uCE90\uB9AD\uD130\uC5D0 \uC800\uC7A5\uB410\uC2B5\uB2C8\uB2E4.',
          ),
        ),
      );
      setState(() {
        _templatePreviewImageUrl = persona.imageUrl ?? persona.baseImageUrl;
        _step = persona.generationStatus == 'failed' ? _step : 0;
        _templateRefreshTick++;
        if (persona.generationStatus != 'failed') {
          _templateName = '\uB098\uC758 \uCE90\uB9AD\uD130';
          _templateSaveMode = 'share';
          _referenceImageBytes = null;
          _referenceImageName = null;
          _selectedTags.clear();
          _hasCharacterDraft = false;
        }
      });
      if (persona.generationStatus != 'failed') {
        _isRestoringDraft = true;
        _nameController.text = _templateName;
        _memoController.clear();
        _isRestoringDraft = false;
        unawaited(_clearCharacterDraft());
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '\uCE90\uB9AD\uD130 \uC800\uC7A5 \uC2E4\uD328: ${_friendlyTemplateError(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _friendlyTemplateError(Object error) {
    final message = error.toString();
    if (message.contains('create_guest_persona') ||
        message.contains('PGRST202')) {
      return '\uCE90\uB9AD\uD130 \uC0DD\uC131 RPC\uAC00 DB\uC5D0 \uC5C6\uC2B5\uB2C8\uB2E4. run_template_rpc_bundle.sql\uC744 \uC2E4\uD589\uD574 \uC8FC\uC138\uC694.';
    }
    if (message.contains('row-level security')) {
      return '\uCE90\uB9AD\uD130 RLS \uC624\uB958\uC785\uB2C8\uB2E4. \uB85C\uADF8\uC778\uD55C \uACC4\uC815\uC758 \uCE90\uB9AD\uD130\uB9CC \uC800\uC7A5\uD560 \uC218 \uC788\uC2B5\uB2C8\uB2E4. \uC6D0\uBB38: $message';
    }
    if (message.contains('Failed to fetch')) {
      return 'generate-persona-image Edge Function \uD638\uCD9C\uC5D0 \uC2E4\uD328\uD588\uC2B5\uB2C8\uB2E4. Supabase \uBC30\uD3EC\uC640 OPENAI_API_KEY, STABILITY_API_KEY Secret\uC744 \uD655\uC778\uD574 \uC8FC\uC138\uC694.';
    }
    return _friendlyGenerationError(error);
  }

  void _showTemplateDetail(BuildContext context, PersonaModel template) {
    final isMine =
        Supabase.instance.client.auth.currentUser?.id == template.userId;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return FractionallySizedBox(
          heightFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  template.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
                const Gap(12),
                SizedBox(
                  height: 160,
                  child: _TemplateDetailImage(
                    imageUrl: template.imageUrl ?? template.baseImageUrl,
                  ),
                ),
                const Gap(12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: template.appearanceTags
                      .map((String tag) => _FigmaTinyTag(text: tag))
                      .toList(),
                ),
                const Spacer(),
                if (isMine) ...<Widget>[
                  const Gap(12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: <Widget>[
                      OutlinedButton.icon(
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  '\uCE90\uB9AD\uD130 \uC0AD\uC81C',
                                  textAlign: TextAlign.center,
                                ),
                                content: const Text(
                                  '\uC774 \uCE90\uB9AD\uD130\uB294 \uC0AD\uC81C\uD558\uBA74 \uB418\uB3CC\uB9B4 \uC218 \uC5C6\uC2B5\uB2C8\uB2E4.',
                                  textAlign: TextAlign.center,
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('\uCDE8\uC18C'),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('\uC0AD\uC81C'),
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed != true) {
                            return;
                          }
                          await SupabasePersonaRepository(
                            Supabase.instance.client,
                          ).deletePersonaTemplate(template.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                          if (mounted) {
                            setState(() => _templateRefreshTick++);
                          }
                        },
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('\uC0AD\uC81C'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmptyDraftCharacterPanel extends StatelessWidget {
  const _EmptyDraftCharacterPanel({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.28),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.tacticalBlue.withValues(alpha: 0.82),
              size: 44,
            ),
            const Gap(12),
            Text(
              '\uC784\uC2DC\uC800\uC7A5\uB41C \uCE90\uB9AD\uD130\uAC00 \uC5C6\uC2B5\uB2C8\uB2E4.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Gap(6),
            Text(
              '\uB9CC\uB4E0 \uCE90\uB9AD\uD130\uB97C \uC5EC\uAE30\uC11C \uD655\uC778\uD558\uACE0 \uBC1C\uD589\uD574\uC694.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.ink.withValues(alpha: 0.58),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
            const Gap(16),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('\uCE90\uB9AD\uD130 \uB9CC\uB4E4\uAE30'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterDraftPublishPanel extends StatelessWidget {
  const _CharacterDraftPublishPanel({
    required this.name,
    required this.memo,
    required this.tags,
    required this.isPublishing,
    required this.onEdit,
    required this.onPublish,
    required this.onClear,
    this.imageUrl,
    this.imageBytes,
  });

  final String name;
  final String memo;
  final List<String> tags;
  final String? imageUrl;
  final Uint8List? imageBytes;
  final bool isPublishing;
  final VoidCallback onEdit;
  final VoidCallback onPublish;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.26),
          width: 1.2,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(mobile ? 12 : 16),
        child: mobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _children(context),
              )
            : Row(children: _children(context)),
      ),
    );
  }

  List<Widget> _children(BuildContext context) {
    final mobile = _isMobileLayout(context);
    final details = Column(
      crossAxisAlignment: mobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: mobile
              ? MainAxisAlignment.center
              : MainAxisAlignment.start,
          children: <Widget>[
            const Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.tacticalBlue,
              size: 18,
            ),
            const Gap(6),
            Text(
              '\uC784\uC2DC\uC800\uC7A5 \uCE90\uB9AD\uD130',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppTheme.tacticalBlue,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const Gap(5),
        Text(
          name.trim().isEmpty ? '\uB098\uC758 \uCE90\uB9AD\uD130' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: mobile ? TextAlign.center : TextAlign.left,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (tags.isNotEmpty) ...<Widget>[
          const Gap(8),
          Wrap(
            alignment: mobile ? WrapAlignment.center : WrapAlignment.start,
            spacing: 6,
            runSpacing: 6,
            children: tags
                .take(3)
                .map((String tag) => _FigmaTinyTag(text: tag))
                .toList(),
          ),
        ],
      ],
    );
    return <Widget>[
      SizedBox(
        width: mobile ? double.infinity : 116,
        height: mobile ? 150 : 132,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppTheme.pastelBlue.withValues(alpha: 0.20),
              border: Border.all(
                color: AppTheme.tacticalBlue.withValues(alpha: 0.20),
              ),
            ),
            child: imageBytes != null
                ? Image.memory(imageBytes!, fit: BoxFit.cover)
                : imageUrl?.trim().isNotEmpty == true
                ? _StorageAwareImage(
                    url: imageUrl!.trim(),
                    fallback: const _TemplateImageFallback(),
                  )
                : const Icon(
                    Icons.face_retouching_natural_rounded,
                    color: AppTheme.tacticalBlue,
                    size: 38,
                  ),
          ),
        ),
      ),
      Gap(mobile ? 10 : 14),
      if (mobile) details else Expanded(child: details),
      Gap(mobile ? 10 : 14),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: mobile ? double.infinity : 190),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            FilledButton.icon(
              onPressed: isPublishing ? null : onPublish,
              icon: isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.publish_rounded),
              label: Text(
                isPublishing
                    ? '\uBC1C\uD589 \uC911...'
                    : '\uCD5C\uC885 \uBC1C\uD589',
              ),
            ),
            const Gap(8),
            OutlinedButton.icon(
              onPressed: isPublishing ? null : onEdit,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('\uC218\uC815'),
            ),
            const Gap(8),
            IconButton.filledTonal(
              tooltip: '\uC784\uC2DC\uC800\uC7A5 \uC0AD\uC81C',
              onPressed: isPublishing ? null : onClear,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    ];
  }
}

class _TemplateGalleryCard extends StatelessWidget {
  const _TemplateGalleryCard({
    required this.title,
    this.isCreateCard = false,
    this.badge,
    this.imageUrl,
    this.onTap,
  });

  final String title;
  final bool isCreateCard;
  final String? badge;
  final String? imageUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final mobile = _isMobileLayout(context);
    return SizedBox(
      width: double.infinity,
      child: _PressableScale(
        onTap: onTap ?? () {},
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: mobile ? 0.96 : 0.88),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.tacticalBlue.withValues(
                alpha: mobile ? 0.38 : 0.50,
              ),
              width: mobile ? 1 : 1.3,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: mobile ? 0.10 : 0.20),
                blurRadius: mobile ? 10 : 20,
                offset: Offset(0, mobile ? 5 : 14),
              ),
              BoxShadow(
                color: AppTheme.pastelRose.withValues(
                  alpha: mobile ? 0.07 : 0.12,
                ),
                blurRadius: mobile ? 12 : 22,
                offset: Offset(mobile ? -3 : -6, mobile ? 3 : 6),
              ),
              BoxShadow(
                color: AppTheme.pastelBlue.withValues(
                  alpha: mobile ? 0.10 : 0.18,
                ),
                blurRadius: mobile ? 12 : 22,
                offset: Offset(mobile ? 3 : 6, mobile ? 2 : 4),
              ),
              if (!mobile)
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.86),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 8 : 10,
              vertical: mobile ? 9 : 16,
            ),
            child: Stack(
              children: <Widget>[
                if (!mobile)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.34),
                            Colors.transparent,
                            AppTheme.tacticalBlue.withValues(alpha: 0.025),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (!mobile)
                  const Positioned(
                    top: 0,
                    left: 12,
                    right: 12,
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFCFE1FF),
                    ),
                  ),
                if (!mobile) const Positioned.fill(child: _CornerBrackets()),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    if (badge != null) ...<Widget>[
                      Align(
                        alignment: Alignment.centerRight,
                        child: _FigmaTinyTag(text: badge!),
                      ),
                      Gap(mobile ? 3 : 6),
                    ],
                    if (isCreateCard) ...<Widget>[
                      Icon(
                        Icons.add_rounded,
                        size: mobile ? 50 : 66,
                        color: AppTheme.tacticalBlue,
                      ),
                      Gap(mobile ? 10 : 18),
                    ] else if (imageUrl != null &&
                        imageUrl!.isNotEmpty) ...<Widget>[
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFBFD9FF),
                                width: 1.2,
                              ),
                            ),
                            child: _StorageAwareImage(
                              url: imageUrl!,
                              fallback: const _TemplateImageFallback(),
                            ),
                          ),
                        ),
                      ),
                      Gap(mobile ? 5 : 10),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: mobile ? 34 : (isCreateCard ? 50 : 42),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.center,
                          child: Text(
                            title,
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.tacticalBlue,
                              fontSize: mobile ? 15 : 18,
                              height: 1.04,
                              fontStyle: mobile
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TemplateImageFallback extends StatelessWidget {
  const _TemplateImageFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        border: Border.all(color: const Color(0xFFBFD9FF)),
      ),
      child: const Center(
        child: Icon(
          Icons.face_retouching_natural_rounded,
          color: Color(0xFFA5CCFF),
          size: 42,
        ),
      ),
    );
  }
}

class _TemplateDetailImage extends StatelessWidget {
  const _TemplateDetailImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.62),
          border: Border.all(color: const Color(0xFFBFD9FF)),
        ),
        child: url == null || url.isEmpty
            ? const Center(child: _TemplateImageFallback())
            : _StorageAwareImage(
                url: url,
                fallback: const _TemplateImageFallback(),
              ),
      ),
    );
  }
}

class _ReferenceFilePicker extends StatelessWidget {
  const _ReferenceFilePicker({
    required this.imageBytes,
    required this.imageName,
    required this.isBusy,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    final mobile = _isMobileLayout(context);
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          hasImage
              ? '\uCC38\uACE0 \uC774\uBBF8\uC9C0'
              : '\uC774\uBBF8\uC9C0 \uC120\uD0DD',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (hasImage && imageName?.trim().isNotEmpty == true) ...<Widget>[
          const Gap(4),
          Text(
            imageName!.trim(),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.ink.withValues(alpha: 0.58),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
        const Gap(10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: isBusy ? null : onPick,
              icon: const Icon(Icons.folder_open_rounded),
              label: Text(
                hasImage
                    ? '\uB2E4\uB978 \uC774\uBBF8\uC9C0'
                    : '\uC774\uBBF8\uC9C0 \uC120\uD0DD',
              ),
            ),
            if (hasImage)
              IconButton.filledTonal(
                onPressed: isBusy ? null : onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: '\uC9C0\uC6B0\uAE30',
              ),
          ],
        ),
      ],
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onPick,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: hasImage
                  ? AppTheme.pastelGreen.withValues(alpha: 0.85)
                  : AppTheme.tacticalBlue.withValues(alpha: 0.28),
              width: hasImage ? 1.6 : 1,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: mobile
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _ReferenceFileThumb(imageBytes: imageBytes),
                    const Gap(10),
                    detail,
                  ],
                )
              : Row(
                  children: <Widget>[
                    _ReferenceFileThumb(imageBytes: imageBytes),
                    const Gap(14),
                    Expanded(child: detail),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ReferenceFileThumb extends StatelessWidget {
  const _ReferenceFileThumb({required this.imageBytes});

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    final bytes = imageBytes;
    return Ink(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        color: AppTheme.pastelBlue.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13),
        child: bytes == null
            ? const Icon(
                Icons.add_photo_alternate_rounded,
                color: AppTheme.tacticalBlue,
                size: 34,
              )
            : Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.memory(bytes, fit: BoxFit.cover),
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.86),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 15,
                          color: AppTheme.tacticalBlue,
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

class _ReferenceImagePicker extends StatelessWidget {
  const _ReferenceImagePicker({
    required this.imageBytes,
    required this.imageName,
    required this.isBusy,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    final mobile = _isMobileLayout(context);
    final thumb = InkWell(
      onTap: isBusy ? null : onPick,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: mobile ? 96 : 82,
          height: mobile ? 96 : 82,
          child: hasImage
              ? Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    Image.memory(imageBytes!, fit: BoxFit.cover),
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.86),
                          shape: BoxShape.circle,
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(
                            Icons.edit_rounded,
                            size: 15,
                            color: AppTheme.tacticalBlue,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppTheme.pastelBlue.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: AppTheme.tacticalBlue,
                    size: 34,
                  ),
                ),
        ),
      ),
    );
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          hasImage
              ? '\uCC38\uACE0 \uC0AC\uC9C4 \uC120\uD0DD\uB428'
              : '\uB0B4 \uD30C\uC77C\uC5D0\uC11C \uC0AC\uC9C4 \uC120\uD0DD',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        const Gap(4),
        Text(
          hasImage
              ? (imageName ?? '\uC120\uD0DD\uD55C \uC774\uBBF8\uC9C0')
              : '\uC120\uD0DD \uC0AC\uD56D\uC785\uB2C8\uB2E4',
          textAlign: TextAlign.center,
          maxLines: mobile ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppTheme.ink.withValues(alpha: 0.60),
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
        const Gap(10),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: isBusy ? null : onPick,
              icon: const Icon(Icons.folder_open_rounded),
              label: Text(
                hasImage
                    ? '\uB2E4\uB978 \uC774\uBBF8\uC9C0'
                    : '\uC774\uBBF8\uC9C0 \uC120\uD0DD',
              ),
            ),
            if (hasImage)
              IconButton.filledTonal(
                onPressed: isBusy ? null : onClear,
                icon: const Icon(Icons.close_rounded),
                tooltip: '\uC9C0\uC6B0\uAE30',
              ),
          ],
        ),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasImage
              ? AppTheme.pastelGreen.withValues(alpha: 0.85)
              : AppTheme.tacticalBlue.withValues(alpha: 0.28),
          width: hasImage ? 1.6 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: mobile
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[thumb, const Gap(12), detail],
            )
          : Row(
              children: <Widget>[
                thumb,
                const Gap(14),
                Expanded(child: detail),
              ],
            ),
    );
  }
}

class _ReferenceImagePickerLegacy extends StatelessWidget {
  const _ReferenceImagePickerLegacy({
    required this.imageBytes,
    required this.imageName,
    required this.isBusy,
    required this.onPick,
    required this.onClear,
  });

  final Uint8List? imageBytes;
  final String? imageName;
  final bool isBusy;
  final VoidCallback onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBytes != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasImage
              ? AppTheme.pastelGreen.withValues(alpha: 0.85)
              : AppTheme.tacticalBlue.withValues(alpha: 0.28),
          width: hasImage ? 1.6 : 1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.tacticalBlue.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 82,
              height: 82,
              child: hasImage
                  ? Image.memory(imageBytes!, fit: BoxFit.cover)
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppTheme.pastelBlue.withValues(alpha: 0.20),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_rounded,
                        color: AppTheme.tacticalBlue,
                        size: 34,
                      ),
                    ),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  hasImage
                      ? '\uCC38\uACE0 \uC0AC\uC9C4 \uC120\uD0DD\uB428'
                      : '\uCC38\uACE0 \uC0AC\uC9C4\uB85C \uCE90\uB9AD\uD130 \uB9CC\uB4E4\uAE30',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Gap(4),
                Text(
                  hasImage
                      ? (imageName ?? '\uC120\uD0DD\uD55C \uC774\uBBF8\uC9C0')
                      : '\uC120\uD0DD \uC0AC\uD56D\uC785\uB2C8\uB2E4',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.ink.withValues(alpha: 0.60),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const Gap(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: isBusy ? null : onPick,
                      icon: const Icon(Icons.photo_library_rounded),
                      label: Text(
                        hasImage
                            ? '\uB2E4\uC2DC \uC120\uD0DD'
                            : '\uC774\uBBF8\uC9C0 \uC120\uD0DD',
                      ),
                    ),
                    if (hasImage) ...<Widget>[
                      const Gap(8),
                      IconButton.filledTonal(
                        onPressed: isBusy ? null : onClear,
                        icon: const Icon(Icons.close_rounded),
                        tooltip: '\uC9C0\uC6B0\uAE30',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterTagPicker extends StatefulWidget {
  const _CharacterTagPicker({
    required this.groups,
    required this.selectedTags,
    required this.onTagToggled,
    required this.onClear,
  });

  final Map<String, List<String>> groups;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggled;
  final VoidCallback onClear;

  @override
  State<_CharacterTagPicker> createState() => _CharacterTagPickerState();
}

class _CharacterTagPickerState extends State<_CharacterTagPicker> {
  int _groupIndex = 0;

  @override
  Widget build(BuildContext context) {
    final entries = widget.groups.entries.toList();
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_groupIndex >= entries.length) {
      _groupIndex = 0;
    }
    final selectedEntry = entries[_groupIndex];
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.tacticalBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                const Icon(
                  Icons.tune_rounded,
                  color: AppTheme.tacticalBlue,
                  size: 18,
                ),
                const Gap(6),
                Text(
                  '\uD0DC\uADF8\uB85C \uC124\uC815',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppTheme.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                if (widget.selectedTags.isNotEmpty) ...<Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.tacticalBlue.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        '${widget.selectedTags.length}\uAC1C',
                        style: const TextStyle(
                          color: AppTheme.tacticalBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const Gap(4),
                ],
                TextButton.icon(
                  onPressed: widget.selectedTags.isEmpty
                      ? null
                      : widget.onClear,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('\uCD08\uAE30\uD654'),
                ),
              ],
            ),
            const Gap(6),
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: entries.length,
                separatorBuilder: (_, _) => const Gap(6),
                itemBuilder: (BuildContext context, int index) {
                  final entry = entries[index];
                  final selectedCount = entry.value
                      .where(widget.selectedTags.contains)
                      .length;
                  final active = index == _groupIndex;
                  return _PressableScale(
                    onTap: () => setState(() => _groupIndex = index),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFEAF3FF)
                            : Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: active
                              ? AppTheme.tacticalBlue.withValues(alpha: 0.54)
                              : AppTheme.ink.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: active
                                    ? AppTheme.tacticalBlue
                                    : AppTheme.ink.withValues(alpha: 0.62),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Gap(5),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                color: AppTheme.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (selectedCount > 0) ...<Widget>[
                              const Gap(5),
                              Text(
                                '$selectedCount',
                                style: const TextStyle(
                                  color: AppTheme.tacticalBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(8),
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: selectedEntry.value.length,
                separatorBuilder: (_, _) => const Gap(6),
                itemBuilder: (BuildContext context, int index) {
                  final tag = selectedEntry.value[index];
                  final selected = widget.selectedTags.contains(tag);
                  return FilterChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(tag, textAlign: TextAlign.center),
                    selected: selected,
                    selectedColor: AppTheme.pastelGreen.withValues(alpha: 0.72),
                    checkmarkColor: AppTheme.tacticalBlue,
                    backgroundColor: Colors.white.withValues(alpha: 0.86),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.tacticalBlue.withValues(alpha: 0.62)
                          : AppTheme.ink.withValues(alpha: 0.16),
                    ),
                    onSelected: (_) => widget.onTagToggled(tag),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterTagGroup extends StatelessWidget {
  const _CharacterTagGroup({
    required this.groupNumber,
    required this.title,
    required this.tags,
    required this.selectedTags,
    required this.selectedCount,
    required this.onTagToggled,
  });

  final int groupNumber;
  final String title;
  final List<String> tags;
  final Set<String> selectedTags;
  final int selectedCount;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selectedCount > 0
              ? AppTheme.tacticalBlue.withValues(alpha: 0.45)
              : AppTheme.tacticalBlue.withValues(alpha: 0.14),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          visualDensity: VisualDensity.compact,
          leading: CircleAvatar(
            radius: 11,
            backgroundColor: selectedCount > 0
                ? AppTheme.tacticalBlue.withValues(alpha: 0.92)
                : AppTheme.academyLilac.withValues(alpha: 0.68),
            child: Text(
              '$groupNumber',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selectedCount > 0 ? Colors.white : AppTheme.ink,
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
            ),
          ),
          title: Text(
            title,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: AppTheme.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          trailing: selectedCount > 0
              ? Text(
                  '$selectedCount',
                  style: const TextStyle(
                    color: AppTheme.tacticalBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                )
              : const Icon(Icons.expand_more_rounded),
          children: <Widget>[
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tags.length,
                separatorBuilder: (_, _) => const Gap(6),
                itemBuilder: (BuildContext context, int index) {
                  final tag = tags[index];
                  final selected = selectedTags.contains(tag);
                  return FilterChip(
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    label: Text(tag, textAlign: TextAlign.center),
                    selected: selected,
                    selectedColor: AppTheme.pastelGreen.withValues(alpha: 0.72),
                    checkmarkColor: AppTheme.tacticalBlue,
                    backgroundColor: Colors.white.withValues(alpha: 0.86),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.tacticalBlue.withValues(alpha: 0.62)
                          : AppTheme.ink.withValues(alpha: 0.16),
                    ),
                    onSelected: (_) => onTagToggled(tag),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
