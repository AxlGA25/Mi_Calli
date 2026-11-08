// Modal de Red de Apoyo (SOS) - SupportNetworkModal.
//
// Dos botones:
// 1. Contactar a persona de confianza (WhatsApp/SMS prellenado)
// 2. Llamar a Línea de la Vida (800 911 2000)
//
// Si no hay contacto configurado, el botón 1 lleva a configurarlo.
// Nunca bloquea al usuario; puede cerrar y continuar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/core/constants/sos_texts.dart';
import 'package:mi_calli/core/security/support_contact_service.dart';
import 'package:mi_calli/core/settings/app_settings_provider.dart';

/// Modal que muestra las opciones de apoyo (Red de Apoyo Dual).
///
/// - Botón 1: Contactar a persona de confianza (WhatsApp/SMS) o configurar contacto.
/// - Botón 2: Llamar a Línea de la Vida (800 911 2000).
/// - Botón 3: Llamar al 911 (emergencias inmediatas).
class SupportNetworkModal extends ConsumerStatefulWidget {
  const SupportNetworkModal({super.key});

  @override
  ConsumerState<SupportNetworkModal> createState() => _SupportNetworkModalState();

  /// Muestra el modal como diálogo.
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // El usuario puede cerrar tocando fuera
      builder: (_) => const SupportNetworkModal(),
    );
  }
}

class _SupportNetworkModalState extends ConsumerState<SupportNetworkModal> {
  late SupportContactService _contactService;

  @override
  void initState() {
    super.initState();
    // Obtener el servicio de contactos desde el provider
    _contactService = ref.read(supportContactServiceProvider);
  }

  /// Genera el mensaje SOS personalizado con el nombre del contacto.
  /// Usa el nombre real (sin fallback "mi persona de confianza").
  String _getPersonalizedMessage() {
    return SosTexts.mensajePersonaConfianza(_contactService.trustedContactName);
  }

  /// Abre WhatsApp con el mensaje prellenado.
  Future<void> _openWhatsApp() async {
    final phone = _contactService.phoneDigits;
    if (phone == null) return;

    final message = Uri.encodeComponent(_getPersonalizedMessage());
    final uri = Uri.parse('https://wa.me/$phone?text=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Abre SMS con el mensaje prellenado.
  Future<void> _openSMS() async {
    final phone = _contactService.phoneDigits;
    if (phone == null) return;

    final message = Uri.encodeComponent(_getPersonalizedMessage());
    final uri = Uri.parse('sms:$phone?body=$message');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Muestra selector WhatsApp/SMS para contactar a la persona de confianza.
  Future<void> _contactTrustedPerson() async {
    if (!_contactService.hasContact) {
      // No hay contacto -> navegar a ajustes para configurarlo
      if (!mounted) return;
      Navigator.of(context).pop(); // Cerrar modal
      // TODO: Navegar a SettingsScreen -> contacto de confianza
      // Por ahora solo mostramos un snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ve a Ajustes > Contacto de confianza para configurarlo')),
      );
      return;
    }

    // Mostrar selector WhatsApp/SMS
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
              '¿Cómo quieres contactar a ${_contactService.displayName}?',
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
              subtitle: Text('Se abrirá con el mensaje prellenado', style: TextStyle(color: AppColors.obsidiana.withValues(alpha: 0.6))),
              onTap: () {
                Navigator.of(ctx).pop();
                _openWhatsApp();
              },
            ),
            ListTile(
              leading: Icon(Icons.sms, color: AppColors.jade),
              title: Text('SMS', style: TextStyle(color: AppColors.obsidiana)),
              subtitle: Text('Se abrirá con el mensaje prellenado', style: TextStyle(color: AppColors.obsidiana.withValues(alpha: 0.6))),
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

  /// Llama a la Línea de la Vida (800 911 2000).
  Future<void> _callLineaDeLaVida() async {
    final uri = Uri.parse('tel:${SosTexts.lineaDeLaVida}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Llama al 911 (emergencias inmediatas).
  Future<void> _callEmergencias() async {
    final uri = Uri.parse('tel:${SosTexts.emergencias911}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContact = _contactService.hasContact;

    return Dialog(
      backgroundColor: AppColors.pergaminoClaro,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono de manos/calidez
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.oro.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.oro, width: 2),
                  ),
                  child: const Icon(Icons.favorite, size: 40, color: AppColors.oro),
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Text(
                SosTexts.tituloSupportNetworkModal,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.obsidiana,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              // Subtítulo
              Text(
                SosTexts.subtituloSupportNetworkModal,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.obsidiana.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 24),

              // Botón 1: Contactar a persona de confianza / Configurar
              FilledButton.icon(
                onPressed: _contactTrustedPerson,
                icon: Icon(hasContact ? Icons.person : Icons.person_add, size: 22),
                label: Text(hasContact ? SosTexts.botonContactoConfianza : SosTexts.botonConfigurarContacto),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.jade,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              // Botón 2: Línea de la Vida
              FilledButton.icon(
                onPressed: _callLineaDeLaVida,
                icon: const Icon(Icons.phone, size: 22),
                label: Text(SosTexts.botonLineaDeLaVida),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.oro,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              // Botón 3: Emergencias 911
              OutlinedButton.icon(
                onPressed: _callEmergencias,
                icon: const Icon(Icons.local_police, size: 22),
                label: Text(SosTexts.botonEmergencias),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.rojoGrana,
                  side: BorderSide(color: AppColors.rojoGrana, width: 2),
                  minimumSize: const Size(double.infinity, 56),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 16),

              // Mensaje de cierre
              Text(
                'Puedes cerrar este modal y seguir escribiendo cuando quieras. Lo que escribiste se guarda automáticamente.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.obsidiana.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Provider para SupportContactService.
final supportContactServiceProvider = Provider<SupportContactService>((ref) {
  final settings = ref.watch(appSettingsServiceProvider);
  return SupportContactService.createForTesting(settings);
});