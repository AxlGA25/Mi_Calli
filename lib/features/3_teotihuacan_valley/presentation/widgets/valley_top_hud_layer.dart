// HUD Superior Minimalista del Valle (Layer 4 — Tarea 4.3).
//
// Tres botones semitransparentes flotantes:
// - Esquina superior izquierda: Audio Ambiental
// - Esquina superior derecha (izquierda): Ajustes / Accesibilidad
// - Esquina superior derecha (derecha): Caracol SOS (rojo grana)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/audio/ambient_audio_service.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/widgets/altar_of_calm_modal.dart';

/// Capa del HUD superior con 3 botones flotantes.
class ValleyTopHudLayer extends ConsumerWidget {
  const ValleyTopHudLayer({
    super.key,
    this.onOpenSettings,
    this.onOpenSanctuaryJournal,
    this.onOpenCodex,
  });

  /// Callback para abrir ajustes (inyectado desde TeotihuacanValleyScreen).
  /// Si es null, abre un modal provisional de ajustes.
  final VoidCallback? onOpenSettings;

  /// Callback para abrir el Santuario del Diario (Quetzalcóatl).
  final VoidCallback? onOpenSanctuaryJournal;

  /// Callback para abrir el Códice/Historial (Templo de los Códices).
  final VoidCallback? onOpenCodex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMuted = ref.watch(ambientAudioIsMutedProvider);

    return IgnorePointer(
      // El IgnorePointer permite que los botones reciban taps pero no bloquee el resto
      ignoring: false,
      child: Stack(
        children: [
          // Botón 1: Audio Ambiental (Esquina Superior Izquierda)
          Positioned(
            top: 16,
            left: 16,
            child: _HudButton(
              key: const ValueKey('valley_hud_audio_button'),
              semanticsLabel: isMuted ? 'Activar sonido ambiental' : 'Silenciar sonido ambiental',
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(ambientAudioProvider.notifier).toggleMute();
              },
              backgroundColor: AppColors.obsidiana.withValues(alpha: 0.7),
              borderColor: AppColors.jade.withValues(alpha: 0.5),
              child: Icon(
                isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: AppColors.pergaminoClaro,
                size: 24,
              ),
            ),
          ),

          // Botón 2: Ajustes / Accesibilidad (Esquina Superior Derecha - Izquierda)
          Positioned(
            top: 16,
            right: 80, // 48 + 16 + 16 = 80 desde la derecha (espacio para botón SOS)
            child: _HudButton(
              key: const ValueKey('valley_hud_settings_button'),
              semanticsLabel: 'Abrir ajustes y accesibilidad',
              onTap: () {
                HapticFeedback.selectionClick();
                if (onOpenSettings != null) {
                  onOpenSettings!();
                } else {
                  _showProvisionalSettingsModal(context);
                }
              },
              backgroundColor: AppColors.obsidiana.withValues(alpha: 0.7),
              borderColor: AppColors.jade.withValues(alpha: 0.5),
              child: const Icon(
                Icons.settings_rounded,
                color: AppColors.pergaminoClaro,
                size: 24,
              ),
            ),
          ),

          // Botón 3: Caracol SOS (Esquina Superior Derecha - Derecha, color terracota)
          Positioned(
            top: 16,
            right: 16,
            child: _HudButton(
              key: const ValueKey('valley_hud_sos_button'),
              semanticsLabel: 'Altar de Calma: respiración y red de apoyo',
              onTap: () {
                HapticFeedback.mediumImpact();
                AltarOfCalmModal.show(context);
              },
              backgroundColor: AppColors.rojoGrana.withValues(alpha: 0.85),
              borderColor: AppColors.oro.withValues(alpha: 0.5),
              child: const Icon(
                Icons.favorite_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProvisionalSettingsModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProvisionalSettingsModal(
        onOpenSanctuaryJournal: onOpenSanctuaryJournal,
        onOpenCodex: onOpenCodex,
      ),
    );
  }
}

/// Botón del HUD con área táctil mínima 48x48, Semantics y estilo consistente.
class _HudButton extends StatelessWidget {
  const _HudButton({
    super.key,
    required this.semanticsLabel,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.child,
  });

  final String semanticsLabel;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color borderColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              splashColor: borderColor.withValues(alpha: 0.2),
              highlightColor: borderColor.withValues(alpha: 0.1),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.obsidiana.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal provisional de ajustes (hasta que se implemente SettingsScreen en Tarea 4.6).
class _ProvisionalSettingsModal extends ConsumerWidget {
  const _ProvisionalSettingsModal({
    this.onOpenSanctuaryJournal,
    this.onOpenCodex,
  });

  final VoidCallback? onOpenSanctuaryJournal;
  final VoidCallback? onOpenCodex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.obsidiana,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.jade, width: 2),
          ),
          child: Column(
            children: [
              _buildDragHandle(context),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Ajustes (Provisional)',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppColors.pergaminoClaro,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppColors.pergaminoClaro),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.pergaminoClaro.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        context,
                        icon: Icons.volume_up_rounded,
                        title: 'Audio Ambiental',
                        subtitle: settings.audioEnabled ? 'Activado' : 'Desactivado',
                        trailing: Switch(
                          value: settings.audioEnabled,
                          onChanged: (value) => ref.read(appSettingsProvider.notifier).setAudioEnabled(value),
                          activeColor: AppColors.jade,
                          inactiveThumbColor: AppColors.pergaminoClaro.withValues(alpha: 0.5),
                          inactiveTrackColor: AppColors.pergaminoClaro.withValues(alpha: 0.2),
                        ),
                        onTap: () => ref.read(appSettingsProvider.notifier).setAudioEnabled(!settings.audioEnabled),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.accessibility_new_rounded,
                        title: 'Reducir Movimiento',
                        subtitle: settings.reduceMotion ? 'Activado' : 'Desactivado',
                        trailing: Switch(
                          value: settings.reduceMotion,
                          onChanged: (value) => ref.read(appSettingsProvider.notifier).setReduceMotion(value),
                          activeColor: AppColors.jade,
                          inactiveThumbColor: AppColors.pergaminoClaro.withValues(alpha: 0.5),
                          inactiveTrackColor: AppColors.pergaminoClaro.withValues(alpha: 0.2),
                        ),
                        onTap: () => ref.read(appSettingsProvider.notifier).setReduceMotion(!settings.reduceMotion),
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.lock_rounded,
                        title: 'Candado de la App',
                        subtitle: 'Biometría al volver de segundo plano (>30s)',
                        trailing: Switch(
                          value: true, // TODO: agregar provider app_lock_enabled
                          onChanged: (_) {},
                          activeColor: AppColors.jade,
                        ),
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.notifications_rounded,
                        title: 'Recordatorio Diario',
                        subtitle: settings.reminderEnabled
                            ? 'Activado a las ${settings.reminderTime ?? '20:00'}'
                            : 'Desactivado',
                        trailing: Switch(
                          value: settings.reminderEnabled,
                          onChanged: (value) {
                            // TODO: implementar ReminderService en Tarea 4.7
                          },
                          activeColor: AppColors.jade,
                        ),
                        onTap: () {},
                      ),
                      _buildSettingsTile(
                        context,
                        icon: Icons.person_rounded,
                        title: 'Contacto de Confianza',
                        subtitle: settings.trustedContactName != null
                            ? '${settings.trustedContactName} (${settings.trustedContactPhone})'
                            : 'No configurado',
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.pergaminoClaro),
                        onTap: () {
                          Navigator.of(context).pop();
                          // TODO: navegar a pantalla de contacto de confianza
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Próximamente en Tarea 4.6')),
                          );
                        },
                      ),
                      const Divider(color: AppColors.jade, height: 32),
                      if (onOpenSanctuaryJournal != null)
                        _buildActionTile(
                          context,
                          icon: Icons.menu_book_rounded,
                          title: 'Abrir Santuario del Diario',
                          color: AppColors.jade,
                          onTap: () {
                            Navigator.of(context).pop();
                            onOpenSanctuaryJournal!();
                          },
                        ),
                      if (onOpenCodex != null)
                        _buildActionTile(
                          context,
                          icon: Icons.auto_stories_rounded,
                          title: 'Abrir Códice / Historial',
                          color: AppColors.oro,
                          onTap: () {
                            Navigator.of(context).pop();
                            onOpenCodex!();
                          },
                        ),
                      _buildActionTile(
                        context,
                        icon: Icons.description_rounded,
                        title: 'Aviso y Privacidad',
                        color: AppColors.turquesa,
                        onTap: () {
                          Navigator.of(context).pop();
                          _showLegalTexts(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.jade.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: '$title, $subtitle',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: AppColors.jade.withValues(alpha: 0.1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.jade.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.jade, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: AppColors.pergaminoClaro,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.pergaminoClaro.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                    ),
                  ),
                  trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: color.withValues(alpha: 0.1),
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 18, color: AppColors.pergaminoClaro),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLegalTexts(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.obsidiana,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.jade.withValues(alpha: 0.3)),
        ),
        title: Text(
          'Aviso y Privacidad',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.oro),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLegalSection('Descargo Médico', '''
Mi Calli es una herramienta de reflexión personal y bienestar emocional. NO sustituye
atención psicológica, psiquiátrica ni médica profesional. Si estás en crisis,
contacta a la Línea de la Vida (800 911 2000) o al 911.'''),
              _buildLegalSection('Solo Mayores de 18 Años', '''
Esta app es exclusivamente para personas mayores de 18 años. Al confirmar tu mayoría
de edad, declaras tener 18 años o más.'''),
              _buildLegalSection('Privacidad Absoluta', '''
Tu diario NUNCA sale de tu teléfono. Se guarda cifrado localmente (SQLCipher AES-256).
El respaldo opcional en la nube SOLO sincroniza progreso numérico (XP, racha, nivel),
nunca el texto de tus entradas.'''),
              _buildLegalSection('Exportación Cifrada', '''
Puedes exportar tu diario a un archivo .calli cifrado con tu contraseña (AES-256-GCM).
La contraseña NO se guarda. Si la olvidas, el archivo no se puede recuperar.'''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido', style: TextStyle(color: AppColors.jade)),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.oro, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: AppColors.pergaminoClaro, height: 1.5, fontSize: 13)),
        ],
      ),
    );
  }
}