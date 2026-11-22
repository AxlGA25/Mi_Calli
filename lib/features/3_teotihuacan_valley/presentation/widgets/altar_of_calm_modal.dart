// Modal del Altar de Calma (Respiración 4-4-6 + Red de Apoyo Dual).
//
// Diseño sereno y proporcionado que respeta el escalado real del dispositivo
// (hasta 200% sin overflow). Al completar 3 ciclos alimenta el Fuego Sagrado.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
import 'package:url_launcher/url_launcher.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/sos_texts.dart';
import 'package:mi_calli/core/performance/safe_animation_wrapper.dart';
import 'package:mi_calli/core/security/support_contact_service.dart';
import 'package:mi_calli/core/security/support_network_modal.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/features/2_gamification/services/sacred_fire_and_evolution_service.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/breathing_cycle_engine.dart';

/// Modal del Altar de Calma.
class AltarOfCalmModal extends ConsumerStatefulWidget {
  const AltarOfCalmModal({super.key});

  static void Function(void Function() tickCallback)? _testTimerFactory;

  @visibleForTesting
  static void setTestTimerFactory(
    void Function(void Function() tickCallback)? factory,
  ) {
    _testTimerFactory = factory;
  }

  /// Muestra el modal como hoja inferior (bottom sheet).
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.obsidiana.withValues(alpha: 0.65),
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
  late final BreathingCycleEngine _breathingEngine;
  Timer? _breathingTimer;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  bool _isConfiguringContact = false;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showSacredFireBanner = false;
  bool _isFeedingSacredFire = false;
  BreathingEnginePhase? _previousPhase;

  @override
  void initState() {
    super.initState();
    _breathingEngine = BreathingCycleEngine();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    // Expansión suave y tranquila: inhala 4s, sostén 4s, exhala 6s
    _breathingAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 4),
      TweenSequenceItem(tween: ConstantTween(1.28), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 1.0), weight: 6),
    ]).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
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

        if (_previousPhase != null && _previousPhase != currentPhase) {
          _onPhaseTransition(_previousPhase!, currentPhase);
        }
        _previousPhase = currentPhase;

        setState(() {});

        if (cycleCompleted) {
          _onCycleCompleted();
        }

        if (_breathingController.status != AnimationStatus.forward) {
          _breathingController.forward(from: 0);
        }
      } on StateError {
        _stopBreathingTimer();
      }
    }

    if (AltarOfCalmModal._testTimerFactory != null) {
      AltarOfCalmModal._testTimerFactory!(tickCallback);
    } else {
      _breathingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
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
    if (from == BreathingEnginePhase.inhale &&
        to == BreathingEnginePhase.hold) {
      HapticFeedback.selectionClick();
    } else if (from == BreathingEnginePhase.hold &&
        to == BreathingEnginePhase.exhale) {
      HapticFeedback.lightImpact();
    } else if (from == BreathingEnginePhase.exhale &&
        to == BreathingEnginePhase.inhale) {
      HapticFeedback.lightImpact();
    }
  }

  void _onCycleCompleted() {
    if (!mounted) return;
    final cycles = _breathingEngine.completedCycles;

    if (cycles >= 3) {
      _stopBreathingTimer();
      _breathingEngine.complete();
      _feedSacredFireAndShowBanner();
    } else {
      HapticFeedback.lightImpact();
      _breathingController.forward(from: 0);
    }
  }

  Future<void> _feedSacredFireAndShowBanner() async {
    if (_isFeedingSacredFire) return;
    setState(() {
      _isFeedingSacredFire = true;
    });

    try {
      final service = ref.read(sacredFireAndEvolutionServiceProvider);
      await service.registerDailyCheckin(
        now: DateTime.now(),
        grantJournalXp: false,
      );
      ref.invalidate(gamificationStateProvider);
      ref.invalidate(refreshGamificationStateProvider);

      if (mounted) {
        setState(() {
          _showSacredFireBanner = true;
          _isFeedingSacredFire = false;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (_) {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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

    final phase = _breathingEngine.phase;
    if (phase == BreathingEnginePhase.inhale ||
        phase == BreathingEnginePhase.exhale) {
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

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.pergaminoClaro,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '¿Cómo quieres contactar a ${contactService.displayName}?',
                    textAlign: TextAlign.center,
                    style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                      color: AppColors.obsidiana,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.chat_bubble, color: AppColors.jade),
                  title: const Text(
                    'WhatsApp',
                    style: TextStyle(color: AppColors.obsidiana),
                  ),
                  subtitle: Text(
                    'Se abrirá con el mensaje prellenado',
                    style: TextStyle(
                      color: AppColors.obsidiana.withValues(alpha: 0.6),
                    ),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openWhatsApp();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.sms, color: AppColors.jade),
                  title: const Text(
                    'SMS',
                    style: TextStyle(color: AppColors.obsidiana),
                  ),
                  subtitle: Text(
                    'Se abrirá con el mensaje prellenado',
                    style: TextStyle(
                      color: AppColors.obsidiana.withValues(alpha: 0.6),
                    ),
                  ),
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

    final message = Uri.encodeComponent(
      SosTexts.mensajePersonaConfianza(contactService.trustedContactName),
    );
    final uri = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openSMS() async {
    final contactService = ref.read(supportContactServiceProvider);
    final phone = contactService.phoneDigits;
    if (phone == null) return;

    final message = Uri.encodeComponent(
      SosTexts.mensajePersonaConfianza(contactService.trustedContactName),
    );
    final uri = Uri.parse('sms:$phone?body=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

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
        const SnackBar(
          content: Text('Contacto de confianza guardado'),
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
    final reduceMotion = ref.watch(
      appSettingsProvider.select((s) => s.reduceMotion),
    );
    final effectiveReduceMotion =
        reduceMotion || MediaQuery.disableAnimationsOf(context);
    final contactService = ref.watch(supportContactServiceProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1E24), AppColors.obsidiana],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: AppColors.jade.withValues(alpha: 0.65),
            width: 1.8,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.96,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 14, 22, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Mango sutil de arrastre
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: AppColors.pergaminoClaro.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  _buildHeader(),

                  const SizedBox(height: 20),

                  if (_showSacredFireBanner) _buildSacredFireBanner(),

                  // Sección 1: Respiración en tarjeta serena
                  _buildBreathingSection(effectiveReduceMotion),

                  const SizedBox(height: 18),

                  // Sección 2: Red de Apoyo Dual en tarjeta tranquila
                  _buildSupportNetworkSection(contactService),

                  const SizedBox(height: 16),

                  // Mensaje de cierre legible y cálido
                  Text(
                    'Puedes cerrar este espacio y volver cuando quieras. Lo que escribes se guarda automáticamente.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.pergaminoClaro.withValues(alpha: 0.55),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.jade.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.jade.withValues(alpha: 0.65),
              width: 1.5,
            ),
          ),
          child: const Icon(Icons.air_rounded, size: 28, color: AppColors.jade),
        ),
        const SizedBox(height: 12),
        Text(
          'Aquí hay manos que te sostienen',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.pergaminoClaro,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Altar de Calma · Viento de Ehécatl',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.pergaminoClaro.withValues(alpha: 0.65),
          ),
        ),
      ],
    );
  }

  Widget _buildSacredFireBanner() {
    return Container(
      key: const ValueKey('altar_sacred_fire_fed_banner'),
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.oro.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.oro.withValues(alpha: 0.8),
          width: 1.4,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.oro,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Has completado 3 ciclos de calma. Tu Fuego Sagrado ha sido alimentado hoy.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.pergaminoClaro,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingSection(bool reduceMotion) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.pergaminoClaro.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.jade.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.air_rounded, color: AppColors.jade, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Respiración de Ehécatl (4-4-6)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.pergaminoClaro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Inhala 4s · Sostén 4s · Exhala 6s · Repite 3 ciclos',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.pergaminoClaro.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 18),

          // Círculo de respiración sereno
          Center(
            child: SizedBox(
              height: 210,
              child: Center(
                child: SafeAnimationWrapper(
                  fallbackWidget: _buildStaticBreathingCircle(),
                  child:
                      reduceMotion
                          ? _buildStaticBreathingCircle()
                          : _buildAnimatedBreathingCircle(),
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Contador de ciclos discreto
          Center(
            child: Text(
              'Ciclo ${_breathingEngine.completedCycles} de 3',
              key: const ValueKey('altar_cycle_counter'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.pergaminoClaro.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (_breathingEngine.phase != BreathingEnginePhase.idle &&
              _breathingEngine.phase != BreathingEnginePhase.paused &&
              _breathingEngine.phase != BreathingEnginePhase.completed) ...[
            const SizedBox(height: 4),
            Center(
              child: Text(
                '${_breathingEngine.secondsRemaining}s',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.turquesa,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Botón Iniciar / Pausar / Reiniciar
          Center(
            child: Semantics(
              button: true,
              label: _getToggleButtonLabel(),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: FilledButton.icon(
                  key: const ValueKey('altar_breathing_toggle_button'),
                  onPressed: _toggleBreathing,
                  icon: Icon(_getToggleButtonIcon(), size: 20),
                  label: Text(
                    _getToggleButtonText(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: _getToggleButtonColor(),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(156, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBreathingCircle() {
    return AnimatedBuilder(
      animation: _breathingController,
      builder: (context, child) {
        final scale = _breathingAnimation.value;
        final phaseColor = _getPhaseColor();
        final diameter = 152.0 * scale;

        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                phaseColor.withValues(alpha: 0.25),
                phaseColor.withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
            border: Border.all(
              color: phaseColor.withValues(alpha: 0.85),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: phaseColor.withValues(alpha: 0.2),
                blurRadius: 20 * scale,
                spreadRadius: 2 * scale,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _breathingEngine.getPhaseText(),
                      key: const ValueKey('altar_breathing_phase_text'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: phaseColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Icon(_getPhaseIcon(), color: phaseColor, size: 28),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaticBreathingCircle() {
    final phaseColor = _getPhaseColor();

    return Container(
      width: 158,
      height: 158,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            phaseColor.withValues(alpha: 0.25),
            phaseColor.withValues(alpha: 0.08),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: phaseColor.withValues(alpha: 0.85),
          width: 2.2,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _breathingEngine.getPhaseText(),
                  key: const ValueKey('altar_breathing_phase_text'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: phaseColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Icon(_getPhaseIcon(), color: phaseColor, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Color _getPhaseColor() {
    return switch (_breathingEngine.phase) {
      BreathingEnginePhase.inhale => AppColors.jade,
      BreathingEnginePhase.hold => AppColors.turquesa,
      BreathingEnginePhase.exhale => AppColors.oro,
      BreathingEnginePhase.completed => AppColors.oro,
      BreathingEnginePhase.paused => AppColors.jade.withValues(alpha: 0.65),
      BreathingEnginePhase.idle => AppColors.jade.withValues(alpha: 0.75),
    };
  }

  IconData _getPhaseIcon() {
    return switch (_breathingEngine.phase) {
      BreathingEnginePhase.inhale => Icons.arrow_upward_rounded,
      BreathingEnginePhase.hold => Icons.pause_circle_filled_rounded,
      BreathingEnginePhase.exhale => Icons.arrow_downward_rounded,
      BreathingEnginePhase.completed => Icons.check_circle_rounded,
      BreathingEnginePhase.paused => Icons.pause_rounded,
      BreathingEnginePhase.idle => Icons.air_rounded,
    };
  }

  String _getToggleButtonText() {
    return switch (_breathingEngine.phase) {
      BreathingEnginePhase.idle => 'Iniciar',
      BreathingEnginePhase.inhale ||
      BreathingEnginePhase.hold ||
      BreathingEnginePhase.exhale => 'Pausar',
      BreathingEnginePhase.paused => 'Continuar',
      BreathingEnginePhase.completed => 'Reiniciar',
    };
  }

  IconData _getToggleButtonIcon() {
    return switch (_breathingEngine.phase) {
      BreathingEnginePhase.idle => Icons.play_arrow_rounded,
      BreathingEnginePhase.inhale ||
      BreathingEnginePhase.hold ||
      BreathingEnginePhase.exhale => Icons.pause_rounded,
      BreathingEnginePhase.paused => Icons.play_arrow_rounded,
      BreathingEnginePhase.completed => Icons.refresh_rounded,
    };
  }

  Color _getToggleButtonColor() {
    return switch (_breathingEngine.phase) {
      BreathingEnginePhase.idle => AppColors.jade,
      BreathingEnginePhase.inhale ||
      BreathingEnginePhase.hold ||
      BreathingEnginePhase.exhale => const Color(0xFFC98A2E),
      BreathingEnginePhase.paused => AppColors.turquesa,
      BreathingEnginePhase.completed => AppColors.jade,
    };
  }

  String _getToggleButtonLabel() {
    return switch (_breathingEngine.phase) {
      BreathingEnginePhase.idle => 'Iniciar ejercicio de respiración 4-4-6',
      BreathingEnginePhase.inhale ||
      BreathingEnginePhase.hold ||
      BreathingEnginePhase.exhale => 'Pausar ejercicio de respiración',
      BreathingEnginePhase.paused => 'Continuar ejercicio de respiración',
      BreathingEnginePhase.completed => 'Reiniciar ejercicio de respiración',
    };
  }

  Widget _buildSupportNetworkSection(SupportContactService contactService) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.pergaminoClaro.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.oro.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: AppColors.rojoGrana,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Red de Apoyo Dual',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.pergaminoClaro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'En un toque: contacto de confianza o línea profesional 24/7',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.pergaminoClaro.withValues(alpha: 0.65),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (!_isConfiguringContact)
            _buildSupportButtons(contactService)
          else
            _buildContactConfigForm(contactService),
        ],
      ),
    );
  }

  Widget _buildSupportButtons(SupportContactService contactService) {
    return Column(
      children: [
        Semantics(
          button: true,
          label:
              contactService.hasContact
                  ? 'Contactar a ${contactService.displayName} por WhatsApp o SMS'
                  : 'Configurar persona de confianza',
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 50,
            ),
            child: FilledButton.icon(
              key: const ValueKey('altar_trusted_contact_button'),
              onPressed: _contactTrustedPerson,
              icon: Icon(
                contactService.hasContact
                    ? Icons.person_rounded
                    : Icons.person_add_rounded,
                size: 20,
              ),
              label: Text(
                contactService.hasContact
                    ? 'Pedir compañía a ${contactService.displayName}'
                    : 'Configurar contacto de confianza',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.jade,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          button: true,
          label: 'Llamar a Línea de la Vida 800 911 2000',
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 50,
            ),
            child: FilledButton.icon(
              key: const ValueKey('altar_lifeline_button'),
              onPressed: _callLineaDeLaVida,
              icon: const Icon(Icons.phone_rounded, size: 20),
              label: Text(
                SosTexts.botonLineaDeLaVida,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB8862D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          button: true,
          label: 'Configurar o editar contacto de confianza',
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: double.infinity,
              minHeight: 48,
            ),
            child: OutlinedButton.icon(
              key: const ValueKey('altar_configure_contact_button'),
              onPressed: () {
                setState(() {
                  _isConfiguringContact = true;
                  _nameController.text =
                      contactService.trustedContactName ?? '';
                  _phoneController.text =
                      contactService.trustedContactPhone ?? '';
                });
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: Text(
                contactService.hasContact
                    ? 'Editar contacto de confianza'
                    : 'Configurar contacto de confianza',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.turquesa,
                side: BorderSide(
                  color: AppColors.turquesa.withValues(alpha: 0.7),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
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
          TextFormField(
            key: const ValueKey('altar_contact_name_input'),
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Nombre de la persona de confianza',
              labelStyle: TextStyle(
                color: AppColors.pergaminoClaro.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: AppColors.pergaminoClaro.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.jade.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.jade.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.jade, width: 1.8),
              ),
              prefixIcon: const Icon(
                Icons.person_rounded,
                color: AppColors.jade,
              ),
            ),
            style: const TextStyle(color: AppColors.pergaminoClaro),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            key: const ValueKey('altar_contact_phone_input'),
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Teléfono (ej: +5215512345678)',
              labelStyle: TextStyle(
                color: AppColors.pergaminoClaro.withValues(alpha: 0.7),
              ),
              filled: true,
              fillColor: AppColors.pergaminoClaro.withValues(alpha: 0.08),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.jade.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.jade.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.jade, width: 1.8),
              ),
              prefixIcon: const Icon(
                Icons.phone_rounded,
                color: AppColors.jade,
              ),
            ),
            style: const TextStyle(color: AppColors.pergaminoClaro),
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
          const SizedBox(height: 18),
          Semantics(
            button: true,
            label: 'Guardar contacto de confianza',
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: 50,
              ),
              child: FilledButton.icon(
                key: const ValueKey('altar_save_contact_button'),
                onPressed: _saveContact,
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text(
                  'Guardar contacto',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.jade,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Semantics(
            button: true,
            label: 'Cancelar configuración',
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: double.infinity,
                minHeight: 48,
              ),
              child: OutlinedButton.icon(
                onPressed: _cancelContactConfig,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(
                  'Cancelar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.pergaminoClaro.withValues(
                    alpha: 0.75,
                  ),
                  side: BorderSide(
                    color: AppColors.pergaminoClaro.withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
