// SanctuaryJournalScreen - Pantalla del diario íntimo (Altar de Ofrenda).
//
// - Fondo EmotionGradientBackground a pantalla completa.
// - Hero desde Quetzalcóatl, AnimatedSwitcher al cambiar de clima,
//   BouncyTap en botones y transición MiCalliPageRoute hacia el Códice.
// - Mantiene todas las constantes de contraste WCAG 4.5:1, keys y Semantics.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/database/asset_loader_service.dart';
import 'package:mi_calli/core/security/safety_guard_provider.dart';
import 'package:mi_calli/core/security/support_network_modal.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/core/widgets/mi_calli_animations.dart';
import 'package:mi_calli/features/1_sanctuary_journal/constants/sanctuary_texts.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/emotion_gradient_background.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/emotion_weather_selector.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/private_codex_screen.dart';

// Constantes de color/superficie para tests de contraste (WCAG 4.5:1).
class SanctuaryJournalContrastConstants {
  static const Color phraseBgColor = Color.fromRGBO(255, 255, 255, 0.85);
  static const Color entregarOfrendaBgColor = AppColors.obsidiana;
  static const Color necesitoApoyoBgColor = Color.fromRGBO(255, 255, 255, 0.9);
  static const Color darkTextColor = AppColors.obsidiana;
  static const Color lightTextColor = Colors.white;
  static const Color featherDialogBgColor = AppColors.pergaminoClaro;
  static const Color featherDialogTextColor = AppColors.obsidiana;
  static const Color featherDialogButtonBgColor = AppColors.obsidiana;
  static const Color featherDialogButtonTextColor = Colors.white;
  static const Color misEntradasBgColor = Color.fromRGBO(255, 255, 255, 0.9);
  static const Color misEntradasTextColor = AppColors.obsidiana;

  SanctuaryJournalContrastConstants._();
}

/// Pantalla principal del diario (SanctuaryJournalScreen).
class SanctuaryJournalScreen extends ConsumerStatefulWidget {
  const SanctuaryJournalScreen({super.key});

  @override
  ConsumerState<SanctuaryJournalScreen> createState() =>
      _SanctuaryJournalScreenState();
}

class _SanctuaryJournalScreenState extends ConsumerState<SanctuaryJournalScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  PrehispanicEmotion _selectedEmotion = PrehispanicEmotion.tonatiuhSol;
  bool _isSaving = false;
  bool _hasTextFocus = false;
  late AnimationController _featherDialogController;
  late Animation<double> _featherDialogAnimation;

  List<WisdomFeather>? _cachedFeathers;

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _featherDialogController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _featherDialogAnimation = CurvedAnimation(
      parent: _featherDialogController,
      curve: Curves.easeOutCubic,
    );
    _textFocusNode.addListener(_onFocusChange);
    _textController.addListener(_onTextChanged);
    _preloadFeathers();
  }

  @override
  void dispose() {
    _textFocusNode.removeListener(_onFocusChange);
    _textController.removeListener(_onTextChanged);
    _textFocusNode.dispose();
    _textController.dispose();
    _featherDialogController.dispose();
    super.dispose();
  }

  Future<void> _preloadFeathers() async {
    try {
      _cachedFeathers = await AssetLoaderService.instance.loadFeathers();
    } catch (e) {
      _cachedFeathers = null;
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _hasTextFocus = _textFocusNode.hasFocus;
      });
    }
  }

  bool get _canSubmit => _textController.text.trim().isNotEmpty && !_isSaving;

  Color _emotionAccentColor(PrehispanicEmotion emotion) {
    return Color(int.parse(emotion.colorHex.replaceFirst('#', '0xFF')));
  }

  WisdomFeather _getFeatherForEmotion(PrehispanicEmotion emotion) {
    if (_cachedFeathers != null) {
      return _cachedFeathers!.firstWhere(
        (f) => f.emotionId == emotion.id,
        orElse: () => _cachedFeathers!.first,
      );
    }
    return const WisdomFeather(
      featherId: 'fallback',
      emotionId: 'tonatiuh_sol',
      name: 'Pluma de Rayo Dorado',
      colorHex: '#E9C46A',
      message: 'El calor de tus pensamientos ilumina el valle.',
    );
  }

  Future<void> _onEntregarOfrenda() async {
    if (!_canSubmit) return;

    final appReduceMotion = ref.read(
      appSettingsProvider.select((s) => s.reduceMotion),
    );
    final systemReduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveReduceMotion = appReduceMotion || systemReduceMotion;

    setState(() {
      _isSaving = true;
    });

    _textFocusNode.unfocus();
    final text = _textController.text.trim();

    try {
      final safetyGuard = await ref.read(safetyGuardServiceProvider.future);
      final safetyCheck = safetyGuard.check(text);
      final triggeredSos = safetyCheck.matched;

      final feather = _getFeatherForEmotion(_selectedEmotion);

      final entry = DiaryEntry.create(
        emotion: _selectedEmotion,
        content: text,
        featherId: feather.featherId,
        wateredSeedId: null,
        triggeredSos: triggeredSos,
      );

      final repository = ref.read(diaryRepositoryProvider);
      await repository.saveEntry(entry);

      if (mounted) {
        _textController.clear();
      }

      if (triggeredSos && mounted) {
        await SupportNetworkModal.show(context);
      }

      if (mounted) {
        await _showFeatherDialog(feather, effectiveReduceMotion);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showErrorSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          SanctuaryTexts.errorGuardadoMensaje,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.rojoGrana.withValues(alpha: 0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _showFeatherDialog(
    WisdomFeather feather,
    bool reduceMotion,
  ) async {
    if (!mounted) return;
    if (reduceMotion) {
      await _showFeatherDialogContent(feather);
      return;
    }

    _featherDialogController.forward(from: 0.0);
    if (!mounted) return;
    await _showFeatherDialogContent(feather);
    if (mounted) {
      _featherDialogController.reverse();
    }
  }

  Future<void> _showFeatherDialogContent(WisdomFeather feather) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder:
          (dialogContext) => _FeatherDialog(
            feather: feather,
            animation: _featherDialogAnimation,
            reduceMotion:
                ref.read(appSettingsProvider.select((s) => s.reduceMotion)) ||
                MediaQuery.disableAnimationsOf(dialogContext),
          ),
    );
  }

  void _onNecesitoApoyo() {
    if (!mounted) return;
    SupportNetworkModal.show(context);
  }

  void _onMisEntradas() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MiCalliPageRoute<void>(builder: (_) => const PrivateCodexScreen()));
  }

  bool get _effectiveReduceMotion => ref.watch(appSettingsProvider.select((s) => s.reduceMotion)) || MediaQuery.disableAnimationsOf(context);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: EmotionGradientBackground(emotion: _selectedEmotion),
          ),
          SafeArea(
            child: TickerMode(
              enabled: !_hasTextFocus,
              key: const Key('background_ticker_mode'),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopCeremonialBar(),
                    const SizedBox(height: 10),
                    _buildInvitationText(),
                    const SizedBox(height: 12),
                    EmotionWeatherSelector(
                      selectedEmotion: _selectedEmotion,
                      onChanged: (emotion) {
                        setState(() {
                          _selectedEmotion = emotion;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildPergamino(),
                    const SizedBox(height: 14),
                    _buildEntregarOfrendaButton(),
                    const SizedBox(height: 12),
                    _buildNecesitoApoyoButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Barra superior: volver + emblema Hero + "Mis entradas".
  Widget _buildTopCeremonialBar() {
    final canPop = Navigator.of(context).canPop();

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canPop) ...[
              BouncyTap(
                reduceMotion: _effectiveReduceMotion,
                enableHaptics: true,
                child: Semantics(
                  button: true,
                  label: 'Volver al Valle de Teotihuacán',
                  child: Material(
                    color: SanctuaryJournalContrastConstants.misEntradasBgColor,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(14),
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color:
                              SanctuaryJournalContrastConstants.darkTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0E1720).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFC857).withValues(alpha: 0.85),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'hero_quetzalcoatl_altar',
                    child: Icon(
                      Icons.temple_hindu_rounded,
                      size: 18,
                      color: Color(0xFFFFC857),
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Altar de Ofrenda',
                    style: TextStyle(
                      color: AppColors.pergaminoClaro,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        _buildMisEntradasButton(),
      ],
    );
  }

  /// Texto de invitación con contraste limpio.
  Widget _buildInvitationText() {
    return Semantics(
      label: SanctuaryTexts.elegirClimaInvitation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: SanctuaryJournalContrastConstants.phraseBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0A93B), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.obsidiana.withValues(alpha: 0.14),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 22,
                  height: 1.5,
                  color: const Color(0xFFE0A93B),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Color(0xFFE0A93B),
                  ),
                ),
                Container(
                  width: 22,
                  height: 1.5,
                  color: const Color(0xFFE0A93B),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              SanctuaryTexts.elegirClimaInvitation,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: SanctuaryJournalContrastConstants.darkTextColor,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Pergamino de papel amate con cambio animado de clima (AnimatedSwitcher + AnimatedContainer).
  Widget _buildPergamino() {
    final accent = _emotionAccentColor(_selectedEmotion);

    return Semantics(
      label: 'Pergamino para escribir tu entrada del diario',
      child: Column(
        children: [
          _buildScrollRod(),
          AnimatedContainer(
            duration: _effectiveReduceMotion ? Duration.zero : const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: SanctuaryJournalContrastConstants.featherDialogBgColor
                  .withValues(alpha: 0.97),
              border: Border.symmetric(
                vertical: BorderSide(
                  color:
                      Color.lerp(AppColors.oro, accent, 0.35) ?? AppColors.oro,
                  width: 1.8,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.obsidiana.withValues(alpha: 0.22),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 10,
                  child: CustomPaint(
                    painter: _TeotihuacanFretPainter(
                      color: AppColors.oro.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: AnimatedSwitcher(
                    duration: _effectiveReduceMotion ? Duration.zero : const Duration(milliseconds: 240),
                    transitionBuilder:
                        (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                    child: Row(
                      key: ValueKey<PrehispanicEmotion>(_selectedEmotion),
                      children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.45),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Ofrenda bajo ${_selectedEmotion.deity}',
                            style: Theme.of(
                              context,
                            ).textTheme.labelLarge?.copyWith(
                              color: SanctuaryJournalContrastConstants
                                  .darkTextColor
                                  .withValues(alpha: 0.8),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: AppColors.oro.withValues(alpha: 0.55),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Stack(
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _textController,
                        builder: (context, value, _) {
                          if (value.text.isNotEmpty) {
                            return const SizedBox.shrink();
                          }
                          return IgnorePointer(
                            child: Text(
                              SanctuaryTexts.pergaminoHint,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: SanctuaryJournalContrastConstants
                                    .darkTextColor
                                    .withValues(alpha: 0.45),
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          );
                        },
                      ),
                      TextField(
                        controller: _textController,
                        focusNode: _textFocusNode,
                        maxLines: 9,
                        minLines: 4,
                        enableIMEPersonalizedLearning: false,
                        enableSuggestions: false,
                        autocorrect: false,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color:
                              SanctuaryJournalContrastConstants.darkTextColor,
                          height: 1.5,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        textInputAction: TextInputAction.newline,
                        enableInteractiveSelection: true,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                  child: CustomPaint(
                    painter: _TeotihuacanFretPainter(
                      color: AppColors.oro.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildScrollRod(),
        ],
      ),
    );
  }

  Widget _buildScrollRod() {
    return Container(
      height: 8,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3E2723), Color(0xFF6D4C41), Color(0xFF3E2723)],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: const Color(0xFFFFC857).withValues(alpha: 0.85),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.obsidiana.withValues(alpha: 0.28),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 14,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC857),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(3)),
            ),
          ),
          Container(
            width: 14,
            decoration: const BoxDecoration(
              color: Color(0xFFFFC857),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(3)),
            ),
          ),
        ],
      ),
    );
  }

  /// Botón ceremonial "Entregar ofrenda" con microinteracción BouncyTap.
  Widget _buildEntregarOfrendaButton() {
    return BouncyTap(
      reduceMotion: _effectiveReduceMotion,
      enableHaptics: _canSubmit,
      scaleDown: 0.96,
      child: Semantics(
        label: SanctuaryTexts.semanticaEntregarOfrenda,
        button: true,
        enabled: _canSubmit,
        child: FilledButton.icon(
          onPressed: _canSubmit ? _onEntregarOfrenda : null,
          icon:
              _isSaving
                  ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        SanctuaryJournalContrastConstants.lightTextColor,
                      ),
                    ),
                  )
                  : Icon(
                    Icons.local_fire_department_rounded,
                    size: 22,
                    color: _canSubmit ? const Color(0xFFFFC857) : null,
                  ),
          label: Text(
            SanctuaryTexts.botonEntregarOfrenda,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor:
                SanctuaryJournalContrastConstants.entregarOfrendaBgColor,
            foregroundColor: SanctuaryJournalContrastConstants.lightTextColor,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color:
                    _canSubmit
                        ? const Color(0xFFFFC857)
                        : SanctuaryJournalContrastConstants
                            .entregarOfrendaBgColor
                            .withValues(alpha: 0.25),
                width: 1.8,
              ),
            ),
            disabledBackgroundColor: SanctuaryJournalContrastConstants
                .entregarOfrendaBgColor
                .withValues(alpha: 0.25),
            disabledForegroundColor: SanctuaryJournalContrastConstants
                .entregarOfrendaBgColor
                .withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  /// Botón "Necesito apoyo" (siempre visible) con microinteracción.
  Widget _buildNecesitoApoyoButton() {
    return BouncyTap(
      reduceMotion: _effectiveReduceMotion,
      enableHaptics: true,
      scaleDown: 0.96,
      child: Semantics(
        label: SanctuaryTexts.semanticaNecesitoApoyo,
        button: true,
        child: OutlinedButton.icon(
          onPressed: _onNecesitoApoyo,
          icon: const Icon(Icons.favorite_border, size: 22),
          label: Text(
            SanctuaryTexts.botonNecesitoApoyo,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: SanctuaryJournalContrastConstants.darkTextColor,
            side: const BorderSide(
              color: SanctuaryJournalContrastConstants.darkTextColor,
              width: 2.2,
            ),
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            backgroundColor:
                SanctuaryJournalContrastConstants.necesitoApoyoBgColor,
          ),
        ),
      ),
    );
  }

  /// Botón "Mis entradas" (abre el Códice Privado) con rebote.
  Widget _buildMisEntradasButton() {
    return BouncyTap(
      reduceMotion: _effectiveReduceMotion,
      enableHaptics: true,
      child: Semantics(
        key: const ValueKey('sanctuary_mis_entradas_button'),
        label: SanctuaryTexts.semanticaMisEntradas,
        button: true,
        child: Material(
          color: SanctuaryJournalContrastConstants.misEntradasBgColor,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _onMisEntradas,
            borderRadius: BorderRadius.circular(14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFE0A93B),
                    width: 1.4,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu_book_rounded,
                      size: 16,
                      color:
                          SanctuaryJournalContrastConstants
                              .misEntradasTextColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      SanctuaryTexts.botonMisEntradas,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            SanctuaryJournalContrastConstants
                                .misEntradasTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TeotihuacanFretPainter extends CustomPainter {
  const _TeotihuacanFretPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = 1.3
          ..style = PaintingStyle.stroke;

    const unit = 18.0;
    final path = Path();
    var x = 8.0;
    final yBottom = size.height - 2;
    const yTop = 2.0;
    final yMid = size.height / 2;

    while (x + unit < size.width - 8) {
      path.moveTo(x, yBottom);
      path.lineTo(x + 4, yBottom);
      path.lineTo(x + 4, yMid);
      path.lineTo(x + 8, yMid);
      path.lineTo(x + 8, yTop);
      path.lineTo(x + 14, yTop);
      path.lineTo(x + 14, yBottom);
      x += unit;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TeotihuacanFretPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _FeatherDialog extends StatelessWidget {
  const _FeatherDialog({
    required this.feather,
    required this.animation,
    required this.reduceMotion,
  });

  final WisdomFeather feather;
  final Animation<double> animation;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final effectiveReduceMotion =
        reduceMotion || MediaQuery.disableAnimationsOf(context);

    return Dialog(
      backgroundColor: SanctuaryJournalContrastConstants.featherDialogBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFFFFC857), width: 2.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildFeatherAnimation(context, effectiveReduceMotion),
              const SizedBox(height: 24),
              Text(
                feather.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color:
                      SanctuaryJournalContrastConstants.featherDialogTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                feather.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: SanctuaryJournalContrastConstants
                      .featherDialogTextColor
                      .withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              BouncyTap(
                reduceMotion: effectiveReduceMotion,
                enableHaptics: true,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        SanctuaryJournalContrastConstants
                            .featherDialogButtonBgColor,
                    foregroundColor:
                        SanctuaryJournalContrastConstants
                            .featherDialogButtonTextColor,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(
                        color: Color(0xFFFFC857),
                        width: 1.5,
                      ),
                    ),
                  ),
                  child: Text(
                    SanctuaryTexts.cerrarPlumaDialogo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatherAnimation(
    BuildContext context,
    bool effectiveReduceMotion,
  ) {
    if (effectiveReduceMotion) {
      return Icon(Icons.auto_awesome, size: 80, color: feather.color);
    }

    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: feather.color.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: feather.color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: feather.color.withValues(alpha: 0.32),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.auto_awesome, size: 50, color: feather.color),
        ),
      ),
    );
  }
}
