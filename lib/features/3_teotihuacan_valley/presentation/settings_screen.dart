// Pantalla de Ajustes principal (Tarea 4.6).
//
// Cinco secciones:
// 1. General
// 2. Apariencia / Accesibilidad
// 3. Notificaciones
// 4. Red de Apoyo
// 5. Privacidad y Legal
//
// Usa AppSettingsProvider para reactividad y navega a PrivacyAndLegalScreen.
// Integra ReminderService para recordatorios diarios (Tarea 4.7).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mi_calli/core/backup/diary_backup_service.dart';
import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/legal_texts.dart';
import 'package:mi_calli/core/notifications/reminder_service.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';
import 'package:mi_calli/features/3_teotihuacan_valley/presentation/privacy_and_legal_screen.dart';

/// Pantalla principal de Ajustes.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      key: const ValueKey('settings_screen'),
      backgroundColor: AppColors.obsidiana,
      appBar: AppBar(
        backgroundColor: AppColors.obsidiana,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.pergaminoClaro),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Ajustes',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.oro,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sección 1: General
            _buildSectionHeader(context, 'General', Icons.tune_rounded),
            _buildSettingsTile(
              context,
              key: const ValueKey('settings_tile_audio'),
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
              key: const ValueKey('settings_tile_app_lock'),
              icon: Icons.lock_rounded,
              title: 'Candado de la App',
              subtitle: 'Biometría al volver de segundo plano (>30s)',
              trailing: Switch(
                value: settings.appLockEnabled,
                onChanged: (value) => ref.read(appSettingsProvider.notifier).setAppLockEnabled(value),
                activeColor: AppColors.jade,
                inactiveThumbColor: AppColors.pergaminoClaro.withValues(alpha: 0.5),
                inactiveTrackColor: AppColors.pergaminoClaro.withValues(alpha: 0.2),
              ),
              onTap: () => ref.read(appSettingsProvider.notifier).setAppLockEnabled(!settings.appLockEnabled),
            ),
            _buildSettingsTile(
              context,
              key: const ValueKey('settings_tile_version'),
              icon: Icons.info_outline_rounded,
              title: 'Versión de la App',
              subtitle: '1.0.0', // TODO: obtener de package_info
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.pergaminoClaro, size: 20),
              onTap: () => _showVersionDialog(context),
            ),

            // Sección 2: Apariencia / Accesibilidad
            _buildSectionHeader(context, 'Apariencia / Accesibilidad', Icons.palette_outlined),
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

            // Sección 3: Notificaciones
            _buildSectionHeader(context, 'Notificaciones', Icons.notifications_outlined),
            _buildSettingsTile(
              context,
              key: const ValueKey('settings_tile_recordatorio'),
              icon: Icons.schedule_rounded,
              title: 'Recordatorio Diario',
              subtitle: settings.reminderEnabled
                  ? 'Activado a las ${settings.reminderTime ?? '20:00'}'
                  : 'Desactivado',
              trailing: Switch(
                value: settings.reminderEnabled,
                onChanged: (value) => _onReminderToggle(context, ref, value),
                activeColor: AppColors.jade,
                inactiveThumbColor: AppColors.pergaminoClaro.withValues(alpha: 0.5),
                inactiveTrackColor: AppColors.pergaminoClaro.withValues(alpha: 0.2),
              ),
              onTap: () => _onReminderTap(context, ref),
            ),
            if (settings.reminderEnabled)
              _buildSettingsTile(
                context,
                icon: Icons.access_time_rounded,
                title: 'Hora del Recordatorio',
                subtitle: settings.reminderTime ?? '20:00',
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.pergaminoClaro, size: 20),
                onTap: () => _pickReminderTime(context, ref),
              ),

            // Sección 4: Red de Apoyo
            _buildSectionHeader(context, 'Red de Apoyo', Icons.people_outline),
            _buildSettingsTile(
              context,
              icon: Icons.person_outline_rounded,
              title: 'Contacto de Confianza',
              subtitle: settings.trustedContactName != null
                  ? '${settings.trustedContactName} (${settings.trustedContactPhone})'
                  : 'No configurado',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.pergaminoClaro, size: 20),
              onTap: () => _navigateToContactConfig(context, ref),
            ),

            // Sección 5: Privacidad y Legal
            _buildSectionHeader(context, 'Privacidad y Legal', Icons.gavel_rounded),
            _buildActionTile(
              context,
              icon: Icons.description_rounded,
              title: 'Aviso y Privacidad',
              subtitle: 'Textos legales completos',
              color: AppColors.turquesa,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const PrivacyAndLegalScreen()),
              ),
            ),
            _buildActionTile(
              context,
              icon: Icons.policy_rounded,
              title: 'Política de Privacidad (Web)',
              subtitle: 'Versión completa en el sitio web',
              color: AppColors.oro,
              onTap: () => _launchPrivacyPolicy(),
            ),
            _buildActionTile(
              context,
              icon: Icons.delete_forever_rounded,
              title: 'Eliminar mi Respaldo en la Nube',
              subtitle: 'Borra el progreso respaldado con Google',
              color: AppColors.rojoGrana,
              onTap: () => _showDeleteBackupDialog(context, ref),
            ),
            _buildActionTile(
              context,
              icon: Icons.download_rounded,
              title: 'Exportar mi Diario',
              subtitle: 'Crea un archivo .calli cifrado',
              color: AppColors.jade,
              onTap: () => _showExportDialog(context, ref),
            ),
            _buildActionTile(
              context,
              icon: Icons.upload_rounded,
              title: 'Importar mi Diario',
              subtitle: 'Restaura desde un archivo .calli',
              color: AppColors.turquesa,
              onTap: () => _showImportDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.jade, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.oro,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
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
    Key? key,
  }) {
    return Semantics(
      key: key,
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
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    Key? key,
  }) {
    return Semantics(
      key: key,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
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

  void _onReminderToggle(BuildContext context, WidgetRef ref, bool value) async {
    final reminderService = ref.read(reminderServiceProvider);
    if (value) {
      // Al activar, pedir permiso de notificaciones y abrir selector de hora
      final currentSettings = ref.read(appSettingsProvider);
      int hour = 20;
      int minute = 0;
      if (currentSettings.reminderTime != null) {
        hour = int.parse(currentSettings.reminderTime!.split(':')[0]);
        minute = int.parse(currentSettings.reminderTime!.split(':')[1]);
      }
      final success = await reminderService.enableReminder(hour: hour, minute: minute);
      if (!success && context.mounted) {
        // Si no concede permiso, revertir el switch
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso de notificaciones para los recordatorios'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (success && context.mounted) {
        await _pickReminderTime(context, ref);
      }
    } else {
      await reminderService.disableReminder();
    }
  }

  Future<void> _onReminderTap(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(appSettingsProvider);
    if (settings.reminderEnabled) {
      await _pickReminderTime(context, ref);
    } else {
      _onReminderToggle(context, ref, true);
    }
  }

  Future<void> _pickReminderTime(BuildContext context, WidgetRef ref) async {
    final settings = ref.read(appSettingsProvider);
    final initialTime = settings.reminderTime != null
        ? TimeOfDay(
            hour: int.parse(settings.reminderTime!.split(':')[0]),
            minute: int.parse(settings.reminderTime!.split(':')[1]),
          )
        : const TimeOfDay(hour: 20, minute: 0);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.jade,
              onPrimary: AppColors.obsidiana,
              surface: AppColors.obsidiana,
              onSurface: AppColors.pergaminoClaro,
            ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: AppColors.obsidiana,
              hourMinuteTextColor: AppColors.pergaminoClaro,
              dayPeriodTextColor: AppColors.oro,
              dialHandColor: AppColors.jade,
              dialBackgroundColor: AppColors.jade.withValues(alpha: 0.1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && context.mounted) {
      final reminderService = ref.read(reminderServiceProvider);
      await reminderService.updateReminderTime(
        hour: picked.hour,
        minute: picked.minute,
      );
    }
  }

  void _navigateToContactConfig(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContactConfigSheet(
        onSave: (name, phone) async {
          await ref.read(appSettingsProvider.notifier).setTrustedContactName(name);
          await ref.read(appSettingsProvider.notifier).setTrustedContactPhone(phone);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Contacto "$name" guardado'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.jade,
              ),
            );
          }
        },
        onClear: () async {
          await ref.read(appSettingsProvider.notifier).setTrustedContactName(null);
          await ref.read(appSettingsProvider.notifier).setTrustedContactPhone(null);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contacto de confianza eliminado'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.oro,
              ),
            );
          }
        },
      ),
    );
  }

  void _showVersionDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.obsidiana,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.jade.withValues(alpha: 0.3)),
        ),
        title: Text('Versión de la App', style: TextStyle(color: AppColors.oro)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mi Calli v1.0.0', style: TextStyle(color: AppColors.pergaminoClaro)),
            const SizedBox(height: 8),
            Text('Refugio Quetzalcóatl', style: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.7))),
            const SizedBox(height: 16),
            Text(
              'Una app de bienestar emocional inspirada en la cosmovisión prehispánica.',
              style: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cerrar', style: TextStyle(color: AppColors.jade)),
          ),
        ],
      ),
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    // La URL tiene placeholder [TU_DOMINIO], validar antes de intentar lanzar
    final url = LegalTexts.urlPoliticaPrivacidad;
    if (url.contains('[') || url.contains(']')) {
      // URL no configurada aún, mostrar mensaje
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showDeleteBackupDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.obsidiana,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.rojoGrana.withValues(alpha: 0.3)),
        ),
        title: Text(LegalTexts.deleteBackupTitle, style: TextStyle(color: AppColors.rojoGrana)),
        content: Text(LegalTexts.deleteBackupBody, style: TextStyle(color: AppColors.pergaminoClaro)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(LegalTexts.deleteBackupCancel, style: TextStyle(color: AppColors.pergaminoClaro)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: Implementar eliminación de respaldo en Tarea 4.8 / Phase 5
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función disponible próximamente (requiere Cloudflare)'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: AppColors.oro,
                  ),
                );
              }
            },
            child: Text(LegalTexts.deleteBackupConfirm, style: TextStyle(color: AppColors.rojoGrana)),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.obsidiana,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.jade.withValues(alpha: 0.3)),
        ),
        title: Text(LegalTexts.exportWarningTitle, style: TextStyle(color: AppColors.jade)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LegalTexts.exportWarningBody, style: TextStyle(color: AppColors.pergaminoClaro)),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                style: const TextStyle(color: AppColors.pergaminoClaro),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  labelStyle: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: AppColors.pergaminoClaro.withValues(alpha: 0.05),
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
                    borderSide: const BorderSide(color: AppColors.jade, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es obligatoria';
                  }
                  if (value.length < 8) {
                    return 'Mínimo 8 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                style: const TextStyle(color: AppColors.pergaminoClaro),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  labelStyle: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: AppColors.pergaminoClaro.withValues(alpha: 0.05),
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
                    borderSide: const BorderSide(color: AppColors.jade, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Confirma la contraseña';
                  }
                  if (value != passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: AppColors.pergaminoClaro)),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.of(context).pop();

              final backupService = ref.read(diaryBackupServiceProvider);
              final success = await backupService.exportBackup(passwordController.text);

              if (context.mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LegalTexts.exportSuccess),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.jade,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LegalTexts.exportError),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.rojoGrana,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.jade,
              foregroundColor: AppColors.obsidiana,
            ),
            child: const Text('Exportar'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.obsidiana,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.turquesa.withValues(alpha: 0.3)),
        ),
        title: Text(LegalTexts.importWarningTitle, style: TextStyle(color: AppColors.turquesa)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(LegalTexts.importWarningBody, style: TextStyle(color: AppColors.pergaminoClaro)),
              const SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                style: const TextStyle(color: AppColors.pergaminoClaro),
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Contraseña del archivo .calli',
                  labelStyle: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: AppColors.pergaminoClaro.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.turquesa.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.turquesa.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.turquesa, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'La contraseña es obligatoria';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancelar', style: TextStyle(color: AppColors.pergaminoClaro)),
          ),
          FilledButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;

              Navigator.of(context).pop();

              final backupService = ref.read(diaryBackupServiceProvider);
              final result = await backupService.importBackup(passwordController.text);

              if (context.mounted) {
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Importación exitosa: ${result.entriesCount} entradas, ${result.moodsCount} estados, ${result.chinampasCount} chinampas, ${result.cyclesCount} ciclos'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.jade,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(LegalTexts.importError),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.rojoGrana,
                    ),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.turquesa,
              foregroundColor: AppColors.obsidiana,
            ),
            child: const Text('Importar'),
          ),
        ],
      ),
    );
  }
}

/// Hoja modal para configurar el contacto de confianza.
class _ContactConfigSheet extends ConsumerStatefulWidget {
  const _ContactConfigSheet({
    required this.onSave,
    required this.onClear,
  });

  final Future<void> Function(String name, String phone) onSave;
  final Future<void> Function() onClear;

  @override
  ConsumerState<_ContactConfigSheet> createState() => _ContactConfigSheetState();
}

class _ContactConfigSheetState extends ConsumerState<_ContactConfigSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _hasExistingContact = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(appSettingsProvider);
    if (settings.trustedContactName != null) {
      _hasExistingContact = true;
      _nameController.text = settings.trustedContactName!;
      _phoneController.text = settings.trustedContactPhone ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
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
                        _hasExistingContact ? 'Editar Contacto de Confianza' : 'Configurar Contacto de Confianza',
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LegalTexts.contactExplain,
                          style: TextStyle(
                            color: AppColors.pergaminoClaro.withValues(alpha: 0.7),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _nameController,
                          key: const ValueKey('settings_contact_name_input'),
                          style: const TextStyle(color: AppColors.pergaminoClaro),
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            labelStyle: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.6)),
                            prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.jade),
                            filled: true,
                            fillColor: AppColors.pergaminoClaro.withValues(alpha: 0.05),
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
                              borderSide: const BorderSide(color: AppColors.jade, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El nombre es obligatorio';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          key: const ValueKey('settings_contact_phone_input'),
                          style: const TextStyle(color: AppColors.pergaminoClaro),
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: 'Teléfono (con código de país)',
                            labelStyle: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.6)),
                            hintText: 'Ej: +5215512345678',
                            hintStyle: TextStyle(color: AppColors.pergaminoClaro.withValues(alpha: 0.4)),
                            prefixIcon: Icon(Icons.phone_outlined, color: AppColors.jade),
                            filled: true,
                            fillColor: AppColors.pergaminoClaro.withValues(alpha: 0.05),
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
                              borderSide: const BorderSide(color: AppColors.jade, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El teléfono es obligatorio';
                            }
                            final digits = value.replaceAll(RegExp(r'[^\d]'), '');
                            if (digits.length < 10) {
                              return 'Ingresa un teléfono válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        if (_hasExistingContact)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              key: const ValueKey('settings_clear_contact_button'),
                              onPressed: () async {
                                await widget.onClear();
                                if (context.mounted) Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              label: const Text('Eliminar Contacto'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.rojoGrana,
                                side: BorderSide(color: AppColors.rojoGrana),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        if (_hasExistingContact) const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const ValueKey('settings_save_contact_button'),
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                await widget.onSave(_nameController.text.trim(), _phoneController.text.trim());
                                if (context.mounted) Navigator.of(context).pop();
                              }
                            },
                            icon: const Icon(Icons.save_rounded, size: 20),
                            label: const Text('Guardar Contacto'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.jade,
                              foregroundColor: AppColors.obsidiana,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          )
        );  // Cierra Container y return statement
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
}