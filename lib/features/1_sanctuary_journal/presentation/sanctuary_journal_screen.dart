// SanctuaryJournalScreen - Pantalla del diario íntimo (Etapa 1).
//
// - Fondo EmotionGradientBackground a pantalla completa.
// - Texto de invitación, EmotionWeatherSelector, pergamino (TextField).
// - Botón "Entregar ofrenda" (deshabilitado si texto vacío).
// - Botón "Necesito apoyo" (siempre visible, abre SupportNetworkModal).
// - Flujo SOS: guarda siempre la entrada, muestra modal si hay coincidencia,
//   luego muestra Pluma de Sabiduría.
// - Pausa animaciones de fondo con TickerMode cuando el teclado tiene foco.
// - Respeta "reducir movimiento" (AppSettings + MediaQuery).
// - Sin desbordes a 200% texto. Sin print/debugPrint del contenido.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/database/asset_loader_service.dart';
import 'package:mi_calli/core/security/safety_guard_provider.dart';
import 'package:mi_calli/core/security/support_network_modal.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/constants/sanctuary_texts.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/diary_entry.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/prehispanic_emotion.dart';
import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/emotion_gradient_background.dart';
import 'package:mi_calli/features/1_sanctuary_journal/presentation/emotion_weather_selector.dart';

// Constantes de color/superficie para tests de contraste (WCAG 4.5:1).
// Deben coincidir exactamente con los valores usados en la implementación.
class SanctuaryJournalContrastConstants {
  // Fondos translúcidos detrás de los textos
  static const Color phraseBgColor = Color.fromRGBO(255, 255, 255, 0.85);
  static const Color climateSelectedBgColor = Color.fromRGBO(255, 255, 255, 0.95);
  static const Color climateUnselectedBgColor = Color.fromRGBO(255, 255, 255, 0.85);

  // Fondos de botones
  static const Color entregarOfrendaBgColor = AppColors.obsidiana;
  static const Color necesitoApoyoBgColor = Color.fromRGBO(255, 255, 255, 0.9);

  // Colores de texto
  static const Color darkTextColor = AppColors.obsidiana;
  static const Color lightTextColor = Colors.white;

  // Diálogo Pluma de Sabiduría
  static const Color featherDialogBgColor = AppColors.pergaminoClaro;
  static const Color featherDialogTextColor = AppColors.obsidiana;
  static const Color featherDialogButtonBgColor = AppColors.obsidiana;
  static const Color featherDialogButtonTextColor = Colors.white;

  SanctuaryJournalContrastConstants._();
}

/// Pantalla principal del diario (SanctuaryJournalScreen).
///
/// Estructura (desplazable, sin desbordes a 200% texto):
/// 1. EmotionGradientBackground (full screen, detrás de todo)
/// 2. Texto de invitación cálido
/// 3. EmotionWeatherSelector (transparente)
/// 4. Pergamino (TextField multilínea estilo papel antiguo)
/// 5. Botón "Entregar ofrenda" (deshabilitado si vacío)
/// 6. Botón "Necesito apoyo" (siempre visible)
class SanctuaryJournalScreen extends ConsumerStatefulWidget {
  const SanctuaryJournalScreen({super.key});

  @override
  ConsumerState<SanctuaryJournalScreen> createState() =>
      _SanctuaryJournalScreenState();
}

class _SanctuaryJournalScreenState extends ConsumerState<SanctuaryJournalScreen>
    with TickerProviderStateMixin {
  // Controladores
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  // Estado
  PrehispanicEmotion _selectedEmotion = PrehispanicEmotion.tonatiuhSol;
  bool _isSaving = false;
  bool _hasTextFocus = false;
  late AnimationController _featherDialogController;
  late Animation<double> _featherDialogAnimation;

  /// Listener para el controlador de texto - dispara rebuild al cambiar el texto
  /// para que _canSubmit se reevalúe y el botón se habilite/deshabilite en tiempo real.
  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // Caché de plumas (cargadas una vez)
  List<WisdomFeather>? _cachedFeathers;

  @override
  void initState() {
    super.initState();

    // Controlador de animación para el diálogo de la pluma
    _featherDialogController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _featherDialogAnimation = CurvedAnimation(
      parent: _featherDialogController,
      curve: Curves.easeOutCubic,
    );

    // Escuchar cambios de foco para pausar/reanudar animaciones de fondo
    _textFocusNode.addListener(_onFocusChange);

    // Escuchar cambios de texto para habilitar/deshabilitar el botón en tiempo real
    _textController.addListener(_onTextChanged);

    // Precargar plumas al iniciar
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

  /// Precarga las plumas de sabiduría.
  Future<void> _preloadFeathers() async {
    try {
      _cachedFeathers = await AssetLoaderService.instance.loadFeathers();
    } catch (e) {
      // Si falla, se cargarán bajo demanda al mostrar la pluma
      _cachedFeathers = null;
    }
  }

  /// Maneja cambios de foco del campo de texto.
  void _onFocusChange() {
    if (mounted) {
      setState(() {
        _hasTextFocus = _textFocusNode.hasFocus;
      });
    }
  }

  /// Verifica si el botón "Entregar ofrenda" debe estar habilitado.
  bool get _canSubmit => _textController.text.trim().isNotEmpty && !_isSaving;

  /// Obtiene la pluma correspondiente a la emoción seleccionada.
  WisdomFeather _getFeatherForEmotion(PrehispanicEmotion emotion) {
    if (_cachedFeathers != null) {
      final feather = _cachedFeathers!.firstWhere(
        (f) => f.emotionId == emotion.id,
        orElse: () => _cachedFeathers!.first,
      );
      return feather;
    }
    // Fallback si no se pudo cargar
    return const WisdomFeather(
      featherId: 'fallback',
      emotionId: 'tonatiuh_sol',
      name: 'Pluma de Rayo Dorado',
      colorHex: '#E9C46A',
      message: 'El calor de tus pensamientos ilumina el valle.',
    );
  }

  /// Maneja el guardado de la entrada (flujo principal).
  Future<void> _onEntregarOfrenda() async {
    if (!_canSubmit) return;

    // Leer reduceMotion para animaciones ANTES de cualquier await
    final appReduceMotion = ref.read(
      appSettingsProvider.select((s) => s.reduceMotion),
    );
    final systemReduceMotion = MediaQuery.disableAnimationsOf(context);
    final effectiveReduceMotion = appReduceMotion || systemReduceMotion;

    setState(() {
      _isSaving = true;
    });

    // Desenfocar para ocultar teclado
    _textFocusNode.unfocus();

    // Capturar el texto antes de cualquier await
    final text = _textController.text.trim();

    try {
      // 1. Ejecutar filtro SOS ANTES de guardar
      final safetyGuard = await ref.read(safetyGuardServiceProvider.future);
      final safetyCheck = safetyGuard.check(text);
      final triggeredSos = safetyCheck.matched;

      // 2. Cargar pluma para la emoción
      final feather = _getFeatherForEmotion(_selectedEmotion);

      // 3. Crear la entrada (siempre se guarda, aunque haya SOS)
      final entry = DiaryEntry.create(
        emotion: _selectedEmotion,
        content: text,
        featherId: feather.featherId,
        wateredSeedId: null, // Por ahora null (Chinampa en Fase 3)
        triggeredSos: triggeredSos,
      );

      // 4. Guardar en base de datos
      final repository = ref.read(diaryRepositoryProvider);
      await repository.saveEntry(entry);

      // 5. Guardado exitoso: LIMPIAR EL TEXTO INMEDIATAMENTE (antes de modales)
      if (mounted) {
        _textController.clear();
      }

      // 6. Si hubo SOS, mostrar modal (no bloquea, usuario puede cerrar)
      // Si falla el modal, NO mostramos error y NO restauramos el texto
      if (triggeredSos && mounted) {
        await SupportNetworkModal.show(context);
      }

      // 7. Mostrar diálogo de la Pluma de Sabiduría
      // Si falla el diálogo, NO mostramos error y NO restauramos el texto
      if (mounted) {
        await _showFeatherDialog(feather, effectiveReduceMotion);
      }
    } catch (e) {
      // Si falla el guardado (saveEntry), NO perder el texto: conservar y mostrar mensaje amable
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

  /// Muestra un SnackBar amable cuando falla el guardado.
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

  /// Muestra el diálogo de la Pluma de Sabiduría con animación.
  Future<void> _showFeatherDialog(
    WisdomFeather feather,
    bool reduceMotion,
  ) async {
    if (!mounted) return;
    if (reduceMotion) {
      // Sin animación si reduceMotion
      await _showFeatherDialogContent(feather);
      return;
    }

    // Con animación
    _featherDialogController.forward(from: 0.0);
    if (!mounted) return;
    await _showFeatherDialogContent(feather);
    if (mounted) {
      _featherDialogController.reverse();
    }
  }

  /// Contenido del diálogo de la pluma.
  Future<void> _showFeatherDialogContent(WisdomFeather feather) async {
    if (!mounted) return;
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // El usuario debe tocar "Continuar"
      builder: (dialogContext) => _FeatherDialog(
        feather: feather,
        animation: _featherDialogAnimation,
        reduceMotion: ref.read(
          appSettingsProvider.select((s) => s.reduceMotion),
        ) ||
            MediaQuery.disableAnimationsOf(dialogContext),
      ),
    );
  }

  /// Maneja el botón "Necesito apoyo".
  void _onNecesitoApoyo() {
    if (!mounted) return;
    SupportNetworkModal.show(context);
  }

  @override
  Widget build(BuildContext context) {
    // EmotionGradientBackground maneja reduceMotion internamente
    return Scaffold(
      // El fondo va detrás de todo (extendBodyBehindAppBar no aplica aquí,
      // usamos Stack para superponer)
      body: Stack(
        children: [
          // 1. Fondo animado (full screen)
          Positioned.fill(
            child: EmotionGradientBackground(emotion: _selectedEmotion),
          ),

          // 2. Contenido desplazable con TickerMode para pausar animaciones
          SafeArea(
            child: TickerMode(
              // Pausar animaciones de fondo cuando el teclado tiene foco
              enabled: !_hasTextFocus,
              key: const Key('background_ticker_mode'),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Texto de invitación cálido
                    _buildInvitationText(),

                    const SizedBox(height: 24),

                    // Selector de clima emocional (transparente)
                    EmotionWeatherSelector(
                      selectedEmotion: _selectedEmotion,
                      onChanged: (emotion) {
                        setState(() {
                          _selectedEmotion = emotion;
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Pergamino (TextField)
                    _buildPergamino(),

                    const SizedBox(height: 24),

                    // Botón "Entregar ofrenda"
                    _buildEntregarOfrendaButton(),

                    const SizedBox(height: 16),

                    // Botón "Necesito apoyo" (siempre visible)
                    _buildNecesitoApoyoButton(),

                    // Espacio extra para teclado
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Texto de invitación a elegir el clima.
  ///
  /// Usa texto oscuro (obsidiana) sobre capa translúcida clara para garantizar
  /// contraste 4.5:1 mínimo en todos los 5 gradientes de emoción (incluyendo
  /// Tonatiuh Sol y Ehecatl Viento que son claros).
  Widget _buildInvitationText() {
    return Semantics(
      label: SanctuaryTexts.elegirClimaInvitation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: SanctuaryJournalContrastConstants.phraseBgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          SanctuaryTexts.elegirClimaInvitation,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: SanctuaryJournalContrastConstants.darkTextColor,
                height: 1.4,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Pergamino (TextField multilínea estilo papel antiguo).
  ///
  /// Usa un placeholder personalizado (Stack + ValueListenableBuilder) en lugar de
  /// hintText nativo para evitar el bug de MIUI/Xiaomi donde el hintText se ve
  /// debajo del texto escrito. El placeholder:
  /// - Solo se muestra cuando _textController.text.isEmpty
  /// - No recibe toques (IgnorePointer)
  /// - No tapa el campo ni interfiere con la entrada
  Widget _buildPergamino() {
    return Semantics(
      label: 'Pergamino para escribir tu entrada del diario',
      child: Container(
        decoration: BoxDecoration(
          color: SanctuaryJournalContrastConstants.featherDialogBgColor.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: SanctuaryJournalContrastConstants.darkTextColor.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: SanctuaryJournalContrastConstants.darkTextColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Placeholder personalizado - solo visible cuando el campo está vacío
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _textController,
              builder: (context, value, _) {
                if (value.text.isNotEmpty) {
                  return const SizedBox.shrink();
                }
                return IgnorePointer(
                  child: Text(
                    SanctuaryTexts.pergaminoHint,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: SanctuaryJournalContrastConstants.darkTextColor.withValues(alpha: 0.4),
                          height: 1.5,
                        ),
                  ),
                );
              },
            ),
            // TextField sin hintText nativo
            TextField(
              controller: _textController,
              focusNode: _textFocusNode,
              maxLines: 8,
              minLines: 6,
              enableIMEPersonalizedLearning: false,
              enableSuggestions: false,
              autocorrect: false,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: SanctuaryJournalContrastConstants.darkTextColor,
                    height: 1.5,
                  ),
              decoration: const InputDecoration(
                // hintText eliminado - usamos placeholder personalizado arriba
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
    );
  }

  /// Botón "Entregar ofrenda".
  ///
  /// Usa fondo obsidiana (oscuro) con texto blanco para garantizar contraste
  /// 4.5:1 mínimo. Estado deshabilitado claramente distinguible (fondo claro,
  /// texto medio, sin icono de envío).
  Widget _buildEntregarOfrendaButton() {
    return Semantics(
      label: SanctuaryTexts.semanticaEntregarOfrenda,
      button: true,
      enabled: _canSubmit,
      child: FilledButton.icon(
        onPressed: _canSubmit ? _onEntregarOfrenda : null,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(SanctuaryJournalContrastConstants.lightTextColor),
                ),
              )
            : const Icon(Icons.send, size: 22),
        label: Text(
          SanctuaryTexts.botonEntregarOfrenda,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: SanctuaryJournalContrastConstants.entregarOfrendaBgColor,
          foregroundColor: SanctuaryJournalContrastConstants.lightTextColor,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: SanctuaryJournalContrastConstants.entregarOfrendaBgColor.withValues(alpha: 0.25),
          disabledForegroundColor: SanctuaryJournalContrastConstants.entregarOfrendaBgColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  /// Botón "Necesito apoyo" (siempre visible).
  ///
  /// Usa texto oscuro (obsidiana) y borde visible (obsidiana) para garantizar
  /// contraste 4.5:1 mínimo en todos los 5 gradientes de emoción. Es el botón
  /// de ayuda y debe ser el más legible de la pantalla.
  Widget _buildNecesitoApoyoButton() {
    return Semantics(
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
          side: const BorderSide(color: SanctuaryJournalContrastConstants.darkTextColor, width: 2.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: SanctuaryJournalContrastConstants.necesitoApoyoBgColor,
        ),
      ),
    );
  }
}

/// Diálogo de la Pluma de Sabiduría.
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
    final effectiveReduceMotion = reduceMotion ||
        MediaQuery.disableAnimationsOf(context);

    return Dialog(
      backgroundColor: SanctuaryJournalContrastConstants.featherDialogBgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Animación de la pluma (escala + opacidad)
              _buildFeatherAnimation(context, effectiveReduceMotion),

              const SizedBox(height: 24),

              // Nombre de la pluma
              Text(
                feather.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: SanctuaryJournalContrastConstants.featherDialogTextColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              // Mensaje de la pluma
              Text(
                feather.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SanctuaryJournalContrastConstants.featherDialogTextColor.withValues(alpha: 0.8),
                      height: 1.5,
                    ),
              ),

              const SizedBox(height: 32),

              // Botón cerrar
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: SanctuaryJournalContrastConstants.featherDialogButtonBgColor,
                  foregroundColor: SanctuaryJournalContrastConstants.featherDialogButtonTextColor,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  SanctuaryTexts.cerrarPlumaDialogo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
      return Icon(
        Icons.auto_awesome,
        size: 80,
        color: feather.color,
      );
    }

    return ScaleTransition(
      scale: animation,
      child: FadeTransition(
        opacity: animation,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: feather.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: feather.color, width: 2),
          ),
          child: Icon(
            Icons.auto_awesome,
            size: 50,
            color: feather.color,
          ),
        ),
      ),
    );
  }
}