// Modal del Altar de Calma (Respiración 4-4-6 + Red de Apoyo Dual).
//
// Se abre como hoja inferior (showModalBottomSheet con isScrollControlled: true).
// Incluye:
// - Sección 1: Ejercicio de respiración guiada 4-4-6 con vibración háptica y apoyo visual
// - Sección 2: Red de Apoyo Dual (Línea de la Vida + Persona de Confianza + Configuración)
//
// Al completar 3 ciclos, alimenta el Fuego Sagrado mediante SacredFireAndEvolutionService.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    hide Provider;
import 'package:url_launcher/url_launcher.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/sos_texts.dart';
import 'package:mi_calli/core/security/support_contact_service.dart';
import 'package:mi_calli/core/security/support_network_modal.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/features/2_gamification/services/sacred_fire_and_evolution_service.dart';
import 'package:mi_calli/core/performance/safe_animation_wrapper.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/breathing_cycle_engine.dart';

/// Modal del Altar de Calma.
class AltarOfCalmModal extends ConsumerStatefulWidget {
  const AltarOfCalmModal({super.key});

  /// Callback for testing: if set, this is called instead of starting a real Timer.
  /// Allows tests to control time advancement manually.
  static void Function(void Function() tickCallback)? _testTimerFactory;

  /// Sets a test timer factory. Call with null to reset.
  /// Only for testing purposes.
  @visibleForTesting
  static void setTestTimerFactory(void Function(void Function() tickCallback)? factory) {
    _testTimerFactory = factory;
  }

  /// Muestra el modal como hoja inferior (bottom sheet).
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.obsidiana.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const AltarOfCalmModal(),
    );
  }

  @override
  ConsumerState<AltarOfCalmModal> createState() => _AltarOfCalmModalState();
}

class _AltarOfCalmModalState extends ConsumerState<AltarOfCalmModal>
    with TickerProviderStateMixin {
  // Breathing engine (pure Dart, no Flutter dependencies)
  late final BreathingCycleEngine _breathingEngine;

  // Timer for advancing the engine (1 second ticks)
  Timer? _breathingTimer;

  // Animation controller for visual breathing circle (14 seconds per cycle)
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  // Support network state
  bool _isConfiguringContact = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // UI state
  bool _showSacredFireBanner = false;
  bool _isFeedingSacredFire = false;

  // Track previous phase for haptic feedback on transitions
  BreathingEnginePhase? _previousPhase;

  @override
  void initState() {
    super.initState();

    // Initialize breathing engine
    _breathingEngine = BreathingCycleEngine();

    // Initialize breathing animation controller (14 seconds per cycle)
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    // Animation: expand for 4s (inhale), hold for 4s (hold), contract for 6s (exhale)
    _breathingAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 4),
      TweenSequenceItem(tween: ConstantTween(1.5), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0), weight: 6),
    ]).animate(CurvedAnimation(
      parent: _breathingController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _breathingController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _startBreathingTimer() {
    _breathingTimer?.cancel();

    void tickCallback() {
      if (!mounted) return;

      try {
        final cycleCompleted = _breathingEngine.tick();
        final currentPhase = _breathingEngine.phase;

        // Detect phase transition for haptic feedback
        if (_previousPhase != null && _previousPhase != currentPhase) {
          _onPhaseTransition(_previousPhase!, currentPhase);
        }
        _previousPhase = currentPhase;

        setState(() {
          // UI updates based on engine state
        });

        if (cycleCompleted) {
          _onCycleCompleted();
        }

        // Restart animation controller for visual sync
        if (_breathingController.status == AnimationStatus.forward) {
          // Keep animation running, it will loop naturally
        } else {
          _breathingController.forward(from: 0);
        }
      } on StateError {
        // Engine not running, timer will be cancelled by pause/stop
        _stopBreathingTimer();
      }
    }

    // Use test factory if available (for testing)
    if (AltarOfCalmModal._testTimerFactory != null) {
      AltarOfCalmModal._testTimerFactory!(tickCallback);
    } else {
      // Production: real timer
      _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        tickCallback();
      });
    }
  }

  void _stopBreathingTimer() {
    _breathingTimer?.cancel();
    _breathingTimer = null;
    _breathingController.stop();
    _previousPhase = null;
  }

  void _onPhaseTransition(BreathingEnginePhase from, BreathingEnginePhase to) {
    // Haptic feedback on phase transitions
    if (from == BreathingEnginePhase.inhale && to == BreathingEnginePhase.hold) {
      HapticFeedback.selectionClick();
    } else if (from == BreathingEnginePhase.hold && to == BreathingEnginePhase.exhale) {
      HapticFeedback.lightImpact();
    } else if (from == BreathingEnginePhase.exhale && to == BreathingEnginePhase.inhale) {
      // Cycle completed, new cycle starting - light impact for inhale
      HapticFeedback.lightImpact();
    }
  }

  void _onCycleCompleted() {
    if (!mounted) return;

    final cycles = _breathingEngine.completedCycles;

    if (cycles >= 3) {
      // Completed 3 cycles - feed Sacred Fire and wait for result before showing banner
      _stopBreathingTimer();
      _breathingEngine.complete();
      _feedSacredFireAndShowBanner();
    } else {
      // Start next cycle - haptic for new inhale
      HapticFeedback.lightImpact();
      // Timer continues, animation restarts
      _breathingController.forward(from: 0);
    }
  }

  /// Feeds Sacred Fire and shows banner only on success.
  /// If it fails, shows a friendly error message.
  Future<void> _feedSacredFireAndShowBanner() async {
    if (_isFeedingSacredFire) return;
    setState(() {
      _isFeedingSacredFire = true;
    });

    try {
      final service = ref.read(sacredFireAndEvolutionServiceProvider);
      final now = DateTime.now();
      await service.registerDailyCheckin(now: now, grantJournalXp: false);
      // Invalidate the gamification state provider to refresh UI
      ref.invalidate(gamificationStateProvider);
      ref.invalidate(refreshGamificationStateProvider);

      if (mounted) {
        setState(() {
          _showSacredFireBanner = true;
          _isFeedingSacredFire = false;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFeedingSacredFire = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No pudimos guardar tu día en el Fuego Sagrado, pero tu respiración cuenta. Puedes intentarlo de nuevo.',
            ),
            backgroundColor: AppColors.oro.withValues(alpha: 0.9),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _startBreathing() {
    setState(() {
      _breathingEngine.start();
      _showSacredFireBanner = false;
      _isFeedingSacredFire = false;
    });
    _breathingController.forward(from: 0);
    _startBreathingTimer();
    HapticFeedback.lightImpact();
  }

  void _pauseBreathing() {
    _breathingEngine.pause();
    _stopBreathingTimer();
    setState(() {});
  }

  void _resumeBreathing() {
    _breathingEngine.resume();
    _startBreathingTimer();
    _breathingController.forward();
    setState(() {});

    // Haptic feedback based on resumed phase
    final phase = _breathingEngine.phase;
    if (phase == BreathingEnginePhase.inhale || phase == BreathingEnginePhase.exhale) {
      HapticFeedback.lightImpact();
    } else if (phase == BreathingEnginePhase.hold) {
      HapticFeedback.selectionClick();
    }
  }

  void _resetBreathing() {
    _breathingEngine.reset();
    _stopBreathingTimer();
    _breathingController.reset();
    setState(() {
      _showSacredFireBanner = false;
      _isFeedingSacredFire = false;
    });
  }

  void _toggleBreathing() {
    switch (_breathingEngine.phase) {
      case BreathingEnginePhase.idle:
        _startBreathing();
        break;
      case BreathingEnginePhase.inhale:
      case BreathingEnginePhase.hold:
      case BreathingEnginePhase.exhale:
        _pauseBreathing();
        break;
      case BreathingEnginePhase.paused:
        _resumeBreathing();
        break;
      case BreathingEnginePhase.completed:
        _resetBreathing();
        break;
    }
  }

  // Support network methods
  Future<void> _callLineaDeLaVida() async {
    final uri = Uri.parse('tel:${SosTexts.lineaDeLaVida.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _contactTrustedPerson() async {
    final contactService = ref.read(supportContactServiceProvider);
    if (!contactService.hasContact) {
      setState(() {
        _isConfiguringContact = true;
        _nameController.text = contactService.trustedContactName ?? '';
        _phoneController.text = contactService.trustedContactPhone ?? '';
      });
      return;
    }

    // Show WhatsApp/SMS selector
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pergaminoClaro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              '¿Cómo quieres contactar a ${contactService.displayName}?',
              textAlign: TextAlign.center,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: AppColors.obsidiana,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.chat_bubble, color: AppColors.jade),
              title: Text('WhatsApp', style: TextStyle(color: AppColors.obsidiana)),
              subtitle: Text('Se abrirá con el mensaje prellenado',
                  style: TextStyle(color: AppColors.obsidiana.withValues(alpha: 0.6))),
              onTap: () {
                Navigator.of(ctx).pop();
                _openWhatsApp();
              },
            ),
            ListTile(
              leading: Icon(Icons.sms, color: AppColors.jade),
              title: Text('SMS', style: TextStyle(color: AppColors.obsidiana)),
              subtitle: Text('Se abrirá con el mensaje prellenado',
                  style: TextStyle(color: AppColors.obsidiana.withValues(alpha: 0.6))),
              onTap: () {
                Navigator.of(ctx).pop();
                _openSMS();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _openWhatsApp() async {
    final contactService = ref.read(supportContactServiceProvider);
    final phone = contactService.phoneDigits;
    if (phone == null) return;

    final message = Uri.encodeComponent(SosTexts.mensajePersonaConfianza(contactService.trustedContactName));
    final uri = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openSMS() async {
    final contactService = ref.read(supportContactServiceProvider);
    final phone = contactService.phoneDigits;
    if (phone == null) return;

    final message = Uri.encodeComponent(SosTexts.mensajePersonaConfianza(contactService.trustedContactName));
    final uri = Uri.parse('sms:$phone?body=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Establece el nombre y teléfono del contacto de confianza.
  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) return;

    final settings = ref.read(appSettingsProvider.notifier);
    await settings.setTrustedContactName(_nameController.text.trim());
    await settings.setTrustedContactPhone(_phoneController.text.trim());

    setState(() {
      _isConfiguringContact = false;
      _nameController.clear();
      _phoneController.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Contacto de confianza guardado'),
          backgroundColor: AppColors.jade,
        ),
      );
    }
  }

  void _cancelContactConfig() {
    setState(() {
      _isConfiguringContact = false;
      _nameController.clear();
      _phoneController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = ref.watch(appSettingsProvider.select((s) => s.reduceMotion));
    final effectiveReduceMotion = reduceMotion || MediaQuery.disableAnimationsOf(context);
    // Watch the contact service provider to react to settings changes
    final contactService = ref.watch(supportContactServiceProvider);

    return MediaQuery(
      // Support text scaling up to 200% without overflow
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(2.0)),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.obsidiana,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: AppColors.jade, width: 2),
        ),
        child: SafeArea(
          top: false,
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            expand: false,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.jade.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Header
                    _buildHeader(),

                    const SizedBox(height: 32),

                    // Sacred Fire fed banner
                    if (_showSacredFireBanner) _buildSacredFireBanner(),

                    // Section 1: Breathing Exercise
                    _buildBreathingSection(effectiveReduceMotion),

                    const SizedBox(height: 32),

                    // Section 2: Support Network
                    _buildSupportNetworkSection(contactService),

                    const SizedBox(height: 16),

                    // Closing message
                    Text(
                      'Puedes cerrar este espacio y seguir cuando quieras. Lo que escribiste se guarda automáticamente.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.obsidiana.withValues(alpha: 0.5),
                          ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.jade.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.jade, width: 2),
          ),
          child: const Icon(Icons.air_rounded, size: 40, color: AppColors.jade),
        ),
        const SizedBox(height: 16),

        // Title
        Text(
          'Aquí hay manos que te sostienen',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.pergaminoClaro,
                fontWeight: FontWeight.bold,
              ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Altar de Calma · Viento de Ehécatl',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.pergaminoClaro.withValues(alpha: 0.7),
              ),
        ),
      ],
    );
  }

  Widget _buildSacredFireBanner() {
    return Container(
      key: const ValueKey('altar_sacred_fire_fed_banner'),
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.oro.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.oro, width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, color: AppColors.oro, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Has completado 3 ciclos de calma. Tu Fuego Sagrado ha sido alimentado hoy.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.obsidiana,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingSection(bool reduceMotion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(Icons.air_rounded, color: AppColors.jade, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Respiración de Ehécatl (4-4-6)',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.pergaminoClaro,
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          'Inhala 4s · Sostén 4s · Exhala 6s · Repite 3 ciclos',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.pergaminoClaro.withValues(alpha: 0.7),
              ),
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 24),

        // Breathing circle with phase text
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 280),
            child: SafeAnimationWrapper(
              fallbackWidget: _buildStaticBreathingCircle(reduceMotion),
              child: reduceMotion
                  ? _buildStaticBreathingCircle(reduceMotion)
                  : _buildAnimatedBreathingCircle(),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Cycle counter
        Center(
          child: Text(
            'Ciclo ${_breathingEngine.completedCycles} de 3',
            key: const ValueKey('altar_cycle_counter'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.pergaminoClaro,
                  fontWeight: FontWeight.w600,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 8),

        // Seconds remaining (only during active phases)
        if (_breathingEngine.phase != BreathingEnginePhase.idle &&
            _breathingEngine.phase != BreathingEnginePhase.paused &&
            _breathingEngine.phase != BreathingEnginePhase.completed)
          Center(
            child: Text(
              '${_breathingEngine.secondsRemaining}s',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.turquesa,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

        const SizedBox(height: 24),

        // Toggle button
        Center(
          child: Semantics(
            button: true,
            label: _getToggleButtonLabel(),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: FilledButton.icon(
                key: const ValueKey('altar_breathing_toggle_button'),
                onPressed: _toggleBreathing,
                icon: Icon(_getToggleButtonIcon(), size: 24),
                label: Text(
                  _getToggleButtonText(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _getToggleButtonColor(),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(160, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedBreathingCircle() {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final scale = _breathingAnimation.value;
        final phaseColor = _getPhaseColor();

        return Container(
          width: 200 * scale,
          height: 200 * scale,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                phaseColor.withValues(alpha: 0.3),
                phaseColor.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
            border: Border.all(color: phaseColor, width: 3),
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: 0.3),
                blurRadius: 30 * scale,
                spreadRadius: 5 * scale,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _breathingEngine.getPhaseText(),
                    key: const ValueKey('altar_breathing_phase_text'),
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: phaseColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  _getPhaseIcon(),
                  color: phaseColor,
                  size: 40,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticBreathingCircle(bool reduceMotion) {
    final phaseColor = _getPhaseColor();

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            phaseColor.withValues(alpha: 0.3),
            phaseColor.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        border: Border.all(color: phaseColor, width: 3),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _breathingEngine.getPhaseText(),
                key: const ValueKey('altar_breathing_phase_text'),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: phaseColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              _getPhaseIcon(),
              color: phaseColor,
              size: 40,
            ),
          ],
        ),
      ),
    );
  }

  Color _getPhaseColor() {
    switch (_breathingEngine.phase) {
      case BreathingEnginePhase.inhale:
        return AppColors.jade;
      case BreathingEnginePhase.hold:
        return AppColors.turquesa;
      case BreathingEnginePhase.exhale:
        return AppColors.oro;
      case BreathingEnginePhase.completed:
        return AppColors.oro;
      case BreathingEnginePhase.paused:
        return AppColors.jade.withValues(alpha: 0.5);
      case BreathingEnginePhase.idle:
        return AppColors.jade.withValues(alpha: 0.3);
    }
  }

  IconData _getPhaseIcon() {
    switch (_breathingEngine.phase) {
      case BreathingEnginePhase.inhale:
        return Icons.arrow_upward_rounded;
      case BreathingEnginePhase.hold:
        return Icons.pause_circle_filled_rounded;
      case BreathingEnginePhase.exhale:
        return Icons.arrow_downward_rounded;
      case BreathingEnginePhase.completed:
        return Icons.check_circle_rounded;
      case BreathingEnginePhase.paused:
        return Icons.pause_rounded;
      case BreathingEnginePhase.idle:
        return Icons.air_rounded;
    }
  }

  String _getToggleButtonText() {
    switch (_breathingEngine.phase) {
      case BreathingEnginePhase.idle:
        return 'Iniciar';
      case BreathingEnginePhase.inhale:
      case BreathingEnginePhase.hold:
      case BreathingEnginePhase.exhale:
        return 'Pausar';
      case BreathingEnginePhase.paused:
        return 'Continuar';
      case BreathingEnginePhase.completed:
        return 'Reiniciar';
    }
  }

  IconData _getToggleButtonIcon() {
    switch (_breathingEngine.phase) {
      case BreathingEnginePhase.idle:
        return Icons.play_arrow_rounded;
      case BreathingEnginePhase.inhale:
      case BreathingEnginePhase.hold:
      case BreathingEnginePhase.exhale:
        return Icons.pause_rounded;
      case BreathingEnginePhase.paused:
        return Icons.play_arrow_rounded;
      case BreathingEnginePhase.completed:
        return Icons.refresh_rounded;
    }
  }

  Color _getToggleButtonColor() {
    switch (_breathingEngine.phase) {
      case BreathingEnginePhase.idle:
        return AppColors.jade;
      case BreathingEnginePhase.inhale:
      case BreathingEnginePhase.hold:
      case BreathingEnginePhase.exhale:
        return AppColors.oro;
      case BreathingEnginePhase.paused:
        return AppColors.turquesa;
      case BreathingEnginePhase.completed:
        return AppColors.jade;
    }
  }

  String _getToggleButtonLabel() {
    switch (_breathingEngine.phase) {
      case BreathingEnginePhase.idle:
        return 'Iniciar ejercicio de respiración 4-4-6';
      case BreathingEnginePhase.inhale:
      case BreathingEnginePhase.hold:
      case BreathingEnginePhase.exhale:
        return 'Pausar ejercicio de respiración';
      case BreathingEnginePhase.paused:
        return 'Continuar ejercicio de respiración';
      case BreathingEnginePhase.completed:
        return 'Reiniciar ejercicio de respiración';
    }
  }

  Widget _buildSupportNetworkSection(SupportContactService contactService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Row(
          children: [
            Icon(Icons.favorite_rounded, color: AppColors.rojoGrana, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Red de Apoyo Dual',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.pergaminoClaro,
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        Text(
          'En un toque: contacto de confianza o línea profesional 24/7',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.pergaminoClaro.withValues(alpha: 0.7),
              ),
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 24),

        // Show either support buttons OR contact config form (not both hidden)
        if (!_isConfiguringContact)
          _buildSupportButtons(contactService)
        else
          _buildContactConfigForm(contactService),
      ],
    );
  }

  Widget _buildSupportButtons(SupportContactService contactService) {
    return Column(
      children: [
        // Button 1: Trusted contact
        Semantics(
          button: true,
          label: contactService.hasContact
              ? 'Contactar a ${contactService.displayName} por WhatsApp o SMS'
              : 'Configurar persona de confianza',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 56),
            child: FilledButton.icon(
              key: const ValueKey('altar_trusted_contact_button'),
              onPressed: _contactTrustedPerson,
              icon: Icon(contactService.hasContact ? Icons.person : Icons.person_add, size: 22),
              label: Text(
                contactService.hasContact
                    ? 'Pedir compañía a ${contactService.displayName}'
                    : 'Configurar contacto de confianza',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.jade,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Button 2: Línea de la Vida
        Semantics(
          button: true,
          label: 'Llamar a Línea de la Vida 800 911 2000',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 56),
            child: FilledButton.icon(
              key: const ValueKey('altar_lifeline_button'),
              onPressed: _callLineaDeLaVida,
              icon: const Icon(Icons.phone, size: 22),
              label: Text(
                SosTexts.botonLineaDeLaVida,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.oro,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Button 3: Configure contact (inline)
        Semantics(
          button: true,
          label: 'Configurar o editar contacto de confianza',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
            child: OutlinedButton.icon(
              key: const ValueKey('altar_configure_contact_button'),
              onPressed: () {
                setState(() {
                  _isConfiguringContact = true;
                  _nameController.text = contactService.trustedContactName ?? '';
                  _phoneController.text = contactService.trustedContactPhone ?? '';
                });
              },
              icon: const Icon(Icons.edit_rounded, size: 20),
              label: Text(
                contactService.hasContact ? 'Editar contacto de confianza' : 'Configurar contacto de confianza',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.turquesa,
                side: BorderSide(color: AppColors.turquesa, width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactConfigForm(SupportContactService contactService) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name input
          TextFormField(
            key: const ValueKey('altar_contact_name_input'),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre de la persona de confianza',
              labelStyle: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.7)),
              filled: true,
              fillColor: AppColors.pergaminoClaro.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.jade.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.jade.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.jade, width: 2),
              ),
              prefixIcon: Icon(Icons.person_rounded, color: AppColors.jade),
            ),
            style: TextStyle(color: AppColors.pergaminoClaro),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es obligatorio';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Phone input
          TextFormField(
            key: const ValueKey('altar_contact_phone_input'),
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Teléfono (con código de país, ej: +5215512345678)',
              labelStyle: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.7)),
              filled: true,
              fillColor: AppColors.pergaminoClaro.withValues(alpha: 0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.jade.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.jade.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.jade, width: 2),
              ),
              prefixIcon: Icon(Icons.phone_rounded, color: AppColors.jade),
            ),
            style: TextStyle(color: AppColors.pergaminoClaro),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El teléfono es obligatorio';
              }
              final digits = value.replaceAll(RegExp(r'[^\d]'), '');
              if (digits.length < 10) {
                return 'Ingresa un teléfono válido con código de país';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Save button
          Semantics(
            button: true,
            label: 'Guardar contacto de confianza',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 56),
              child: FilledButton.icon(
                key: const ValueKey('altar_save_contact_button'),
                onPressed: _saveContact,
                icon: const Icon(Icons.save_rounded, size: 22),
                label: const Text(
                  'Guardar contacto',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.jade,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Cancel button
          Semantics(
            button: true,
            label: 'Cancelar configuración',
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: double.infinity, minHeight: 48),
              child: OutlinedButton.icon(
                onPressed: _cancelContactConfig,
                icon: const Icon(Icons.close_rounded, size: 20),
                label: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pergaminoClaro.withValues(alpha: 0.7),
                  side: BorderSide(color: AppColors.pergaminoClaro.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}