// Flujo principal de Onboarding.
//
// Coordina las pantallas: Bienvenida → Confirmación +18 → Consentimiento
// → Contacto Confianza (opcional) → Preferencias (opcional) → Completado.
// Usa PageView para navegación fluida.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'onboarding_welcome_screen.dart';
import 'onboarding_adult_confirmation_screen.dart';
import 'onboarding_minor_block_screen.dart';
import 'onboarding_consent_screen.dart';
import 'onboarding_trusted_contact_screen.dart';
import 'onboarding_preferences_screen.dart';

/// Estados del flujo de onboarding.
enum OnboardingStep {
  welcome,
  adultConfirmation,
  minorBlock,
  consent,
  trustedContact,
  preferences,
  completed,
}

/// Controlador del flujo de onboarding.
class OnboardingFlowController extends ChangeNotifier {
  OnboardingFlowController();

  OnboardingStep _currentStep = OnboardingStep.welcome;
  bool _isAdultConfirmed = false;

  OnboardingStep get currentStep => _currentStep;
  bool get isAdultConfirmed => _isAdultConfirmed;

  void _goTo(OnboardingStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void onWelcomeContinue() => _goTo(OnboardingStep.adultConfirmation);

  void onAdultConfirm() {
    _isAdultConfirmed = true;
    _goTo(OnboardingStep.consent);
  }

  void onAdultDeny() => _goTo(OnboardingStep.minorBlock);

  void onConsentContinue() => _goTo(OnboardingStep.trustedContact);

  void onConsentDecline() => _goTo(OnboardingStep.minorBlock);

  void onTrustedContactContinue() => _goTo(OnboardingStep.preferences);

  void onTrustedContactSkip() => _goTo(OnboardingStep.preferences);

  void onPreferencesComplete() => _goTo(OnboardingStep.completed);
}

/// Widget principal que muestra el flujo de onboarding completo.
class OnboardingFlow extends ConsumerStatefulWidget {
  final VoidCallback onCompleted;

  const OnboardingFlow({
    super.key,
    required this.onCompleted,
  });

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  late final OnboardingFlowController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingFlowController();
    _controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChange);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChange() {
    if (_controller.currentStep == OnboardingStep.completed) {
      widget.onCompleted();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    switch (_controller.currentStep) {
      case OnboardingStep.welcome:
        return OnboardingWelcomeScreen(onContinue: _controller.onWelcomeContinue);

      case OnboardingStep.adultConfirmation:
        return OnboardingAdultConfirmationScreen(
          onConfirmAdult: _controller.onAdultConfirm,
          onNotAdult: _controller.onAdultDeny,
        );

      case OnboardingStep.minorBlock:
        return const OnboardingMinorBlockScreen();

      case OnboardingStep.consent:
        return OnboardingConsentScreen(
          onContinue: _controller.onConsentContinue,
          onDecline: _controller.onConsentDecline,
        );

      case OnboardingStep.trustedContact:
        return OnboardingTrustedContactScreen(
          onContinue: _controller.onTrustedContactContinue,
          onSkip: _controller.onTrustedContactSkip,
        );

      case OnboardingStep.preferences:
        return OnboardingPreferencesScreen(onComplete: _controller.onPreferencesComplete);

      case OnboardingStep.completed:
        // No debería llegar aquí porque onCompleted se llama antes
        return const SizedBox.shrink();
    }
  }
}

/// Provider del controlador de onboarding (para tests o acceso imperativo).
final onboardingFlowControllerProvider = Provider<OnboardingFlowController>((ref) {
  // Nota: Este provider crea una nueva instancia cada vez.
  // Para singleton real, usar un StateNotifierProvider.
  return OnboardingFlowController();
});