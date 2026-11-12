// Bottom Sheet de la Chinampa Sagrada (Tarea 4.3).
//
// ModalBottomSheet estilizado que muestra las 4 parcelas y el inventario de semillas.
// Permite plantar, ver progreso, cosechar y gestionar la chinampa.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'package:mi_calli/core/constants/app_colors.dart';
import 'package:mi_calli/features/2_gamification/controllers/chinampa_controller.dart';
import 'package:mi_calli/features/2_gamification/models/chinampa_models.dart';
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart';
import 'package:mi_calli/features/1_sanctuary_journal/data/diary_repository_provider.dart';

/// Bottom sheet de la Chinampa Sagrada.
class ChinampaBottomSheet extends ConsumerWidget {
  const ChinampaBottomSheet({super.key});

  /// Muestra el bottom sheet de la chinampa.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ChinampaBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(chinampaSlotsProvider);
    final seedCatalogAsync = ref.watch(seedCatalogProvider);
    final inventoryAsync = ref.watch(userInventoryProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.obsidiana,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppColors.jade, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.obsidiana.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle de arrastre
              _buildDragHandle(context),

              // Encabezado
              _buildHeader(context),

              // Contenido scrolleable
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 4 Parcelas de la Chinampa
                      _buildSlotsSection(context, ref, slotsAsync),
                      const SizedBox(height: 24),

                      // Inventario de semillas y Plumas de Sabiduría
                      _buildInventorySection(context, ref, inventoryAsync, seedCatalogAsync),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.jade.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.jade, width: 2),
            ),
            child: const Icon(Icons.grass_rounded, color: AppColors.jade, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chinampa Sagrada',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppColors.pergaminoClaro,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Tus cultivos emocionales',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.pergaminoClaro.withValues(alpha: 0.7),
                      ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Cerrar chinampa',
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close_rounded, color: AppColors.pergaminoClaro, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.obsidiana.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsSection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<ChinampaSlotState>> slotsAsync,
  ) {
    return slotsAsync.when(
      loading: () => _buildSlotsSkeleton(context),
      error: (err, _) => _buildError(context, err.toString()),
      data: (slots) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parcelas',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.oro,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          ...slots.map((slot) => _buildSlotCard(context, ref, slot)),
        ],
      ),
    );
  }

  Widget _buildSlotsSkeleton(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 24,
          width: 100,
          decoration: BoxDecoration(
            color: AppColors.pergaminoClaro.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(4, (i) => _buildSlotSkeleton(context)),
      ],
    );
  }

  Widget _buildSlotSkeleton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pergaminoClaro.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.jade.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.pergaminoClaro.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 16, width: 120, color: AppColors.pergaminoClaro.withValues(alpha: 0.1)),
                const SizedBox(height: 8),
                Container(height: 12, width: 80, color: AppColors.pergaminoClaro.withValues(alpha: 0.1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.rojoGrana.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.rojoGrana.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.rojoGrana),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Error al cargar la chinampa: $error',
              style: TextStyle(color: AppColors.rojoGrana),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(BuildContext context, WidgetRef ref, ChinampaSlotState slot) {
    final isEmpty = slot.isEmpty;
    final isReadyToHarvest = slot.isReadyToBloom;

    return Semantics(
      label: isEmpty
          ? 'Parcela ${slot.slotIndex + 1}, vacía, toca para plantar'
          : isReadyToHarvest
              ? 'Parcela ${slot.slotIndex + 1}, ${slot.catalogItem?.name ?? slot.seedId ?? "planta"} lista para cosechar, ${slot.currentWaterings} de ${slot.wateringsNeeded} riegos'
              : 'Parcela ${slot.slotIndex + 1}, ${slot.catalogItem?.name ?? slot.seedId ?? "planta"} creciendo, etapa ${_getStageName(slot.currentWaterings, slot.wateringsNeeded)}, ${slot.currentWaterings} de ${slot.wateringsNeeded} riegos',
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              if (isEmpty) {
                _showSeedSelector(context, ref, slot.slotIndex);
              } else if (isReadyToHarvest) {
                _harvestSlot(context, ref, slot.slotIndex);
              } else {
                _showSlotDetails(context, ref, slot);
              }
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.jade.withValues(alpha: 0.1),
            highlightColor: AppColors.jade.withValues(alpha: 0.05),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isEmpty
                    ? AppColors.pergaminoClaro.withValues(alpha: 0.03)
                    : isReadyToHarvest
                        ? AppColors.oro.withValues(alpha: 0.1)
                        : AppColors.pergaminoClaro.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEmpty
                      ? AppColors.jade.withValues(alpha: 0.2)
                      : isReadyToHarvest
                          ? AppColors.oro.withValues(alpha: 0.5)
                          : AppColors.jade.withValues(alpha: 0.3),
                  width: isReadyToHarvest ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Sprite de la planta / semilla
                  _buildSlotVisual(context, slot),
                  const SizedBox(width: 16),

                  // Info de la parcela
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                isEmpty
                                    ? 'Parcela ${slot.slotIndex + 1} (Vacía)'
                                    : slot.catalogItem?.name ?? slot.seedId ?? 'Planta desconocida',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: isEmpty
                                          ? AppColors.pergaminoClaro.withValues(alpha: 0.6)
                                          : isReadyToHarvest
                                              ? AppColors.oro
                                              : AppColors.pergaminoClaro,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            if (!isEmpty) _buildStageBadge(context, slot),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (!isEmpty) ...[
                          // Barra de progreso de riegos
                          _buildWateringProgressBar(context, slot),
                          const SizedBox(height: 8),
                          // Emoción de afinidad
                          if (slot.catalogItem != null)
                            _buildAffinityBadge(context, slot.catalogItem!),
                          if (slot.isHarvested)
                            _buildHarvestedBadge(context),
                        ],
                        if (isEmpty)
                          Text(
                            'Toca para plantar una semilla',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.pergaminoClaro.withValues(alpha: 0.5),
                                ),
                          ),
                      ],
                    ),
                  ),

                  // Icono de acción
                  if (isEmpty)
                    Icon(Icons.add_circle_outline_rounded, color: AppColors.jade.withValues(alpha: 0.7), size: 28)
                  else if (isReadyToHarvest)
                    const Icon(Icons.eco_rounded, color: AppColors.oro, size: 28)
                  else
                    Icon(Icons.chevron_right_rounded, color: AppColors.pergaminoClaro.withValues(alpha: 0.4), size: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotVisual(BuildContext context, ChinampaSlotState slot) {
    if (slot.isEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.pergaminoClaro.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.jade.withValues(alpha: 0.2), style: BorderStyle.solid),
        ),
        child: const Center(
          child: Icon(Icons.grass_outlined, color: AppColors.jade, size: 24),
        ),
      );
    }

    final spriteStage = slot.currentSpriteStage;
    if (spriteStage != null) {
      // Mostrar el sprite de la etapa actual
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: AssetImage('assets/images/chinampa_plants/$spriteStage'),
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // Fallback si no hay sprite
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.jade.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          (() {
            final name = slot.catalogItem?.name;
            return (name != null && name.isNotEmpty)
                ? name.substring(0, 1).toUpperCase()
                : '🌱';
          })(),
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildStageBadge(BuildContext context, ChinampaSlotState slot) {
    final stageNames = ['Recién plantado', 'Brote', 'Crecimiento', 'Flor completa'];
    final stageIndex = slot.currentWaterings >= slot.wateringsNeeded
        ? 3
        : (slot.currentWaterings / slot.wateringsNeeded * 3).floor().clamp(0, 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: slot.isReadyToBloom ? AppColors.oro.withValues(alpha: 0.2) : AppColors.jade.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        stageNames[stageIndex],
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: slot.isReadyToBloom ? AppColors.oro : AppColors.jade,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  Widget _buildWateringProgressBar(BuildContext context, ChinampaSlotState slot) {
    final progress = slot.growthProgress;
    final color = slot.isReadyToBloom ? AppColors.oro : AppColors.jade;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riegos: ${slot.currentWaterings} / ${slot.wateringsNeeded}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.pergaminoClaro.withValues(alpha: 0.8),
                  ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.pergaminoClaro.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildAffinityBadge(BuildContext context, SeedCatalogItem catalogItem) {
    final emotionNames = {
      'tlaloc_lluvia': 'Lluvia de Tláloc',
      'tonatiuh_sol': 'Sol de Tonatiuh',
      'ehecatl_viento': 'Viento de Ehécatl',
      'mixcoatl_tormenta': 'Tormenta de Mixcóatl',
      'metztli_noche': 'Noche de Metztli',
    };

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.turquesa.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.favorite_outline_rounded, size: 12, color: AppColors.turquesa),
          const SizedBox(width: 4),
          Text(
            'Afinidad: ${emotionNames[catalogItem.affinityEmotion] ?? catalogItem.affinityEmotion}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.turquesa,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestedBadge(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.oro.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, size: 12, color: AppColors.oro),
          const SizedBox(width: 4),
          Text(
            'Cosechada - Toca para liberar',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.oro,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _getStageName(int current, int needed) {
    if (current >= needed) return 'Flor completa';
    if (current == 0) return 'Recién plantado';
    if (current < needed ~/ 2) return 'Brote';
    return 'Crecimiento';
  }

  void _showSeedSelector(BuildContext context, WidgetRef ref, int slotIndex) {
    final seedCatalogAsync = ref.read(seedCatalogProvider);
    final inventoryAsync = ref.read(userInventoryProvider);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SeedSelectorSheet(
        slotIndex: slotIndex,
        seedCatalogAsync: seedCatalogAsync,
        inventoryAsync: inventoryAsync,
      ),
    );
  }

  void _harvestSlot(BuildContext context, WidgetRef ref, int slotIndex) {
    final controller = ref.read(chinampaControllerProvider);
    controller.harvestAndClearSlot(slotIndex, clearImmediately: true).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Planta cosechada y parcela liberada!'),
            backgroundColor: AppColors.jade,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        // Refrescar slots
        ref.invalidate(refreshChinampaSlotsProvider);
      }
    }).catchError((error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cosechar: $error'),
            backgroundColor: AppColors.rojoGrana,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });
  }

  void _showSlotDetails(BuildContext context, WidgetRef ref, ChinampaSlotState slot) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.obsidiana,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.jade.withValues(alpha: 0.3)),
        ),
        title: Text(
          slot.catalogItem?.name ?? 'Detalles de la planta',
          style: const TextStyle(color: AppColors.pergaminoClaro),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Etapa', _getStageName(slot.currentWaterings, slot.wateringsNeeded)),
            _buildDetailRow('Riegos', '${slot.currentWaterings} / ${slot.wateringsNeeded}'),
            _buildDetailRow('Progreso', '${(slot.growthProgress * 100).round()}%'),
            if (slot.catalogItem != null)
              _buildDetailRow('Afinidad', slot.catalogItem!.affinityEmotion),
            if (slot.plantedAt != null)
              _buildDetailRow('Plantada', '${slot.plantedAt!.toLocal()}'.split(' ')[0]),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar', style: TextStyle(color: AppColors.jade)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.pergaminoClaro, fontSize: 14)),
          Text(value, style: const TextStyle(color: AppColors.oro, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInventorySection(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Map<String, int>> inventoryAsync,
    AsyncValue<Map<String, SeedCatalogItem>> seedCatalogAsync,
  ) {
    return inventoryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.jade)),
      error: (err, _) => _buildError(context, 'Error inventario: $err'),
      data: (inventory) => seedCatalogAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.jade)),
        error: (err, _) => _buildError(context, 'Error catálogo: $err'),
        data: (catalog) {
          // Filtrar solo semillas del inventario
          final seeds = <String, int>{};
          for (final entry in inventory.entries) {
            if (catalog.containsKey(entry.key) && entry.value > 0) {
              seeds[entry.key] = entry.value;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Inventario de Semillas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.oro,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (seeds.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.jade.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${seeds.length} tipos',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.jade,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (seeds.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.pergaminoClaro.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.jade.withValues(alpha: 0.1), style: BorderStyle.solid),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.inventory_2_outlined, color: AppColors.jade, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'No tienes semillas en el inventario',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.pergaminoClaro.withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Las semillas aparecen al escribir en el diario\nsegún tu clima emocional.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.pergaminoClaro.withValues(alpha: 0.4),
                              ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: seeds.entries.map((entry) {
                    final catalogItem = catalog[entry.key]!;
                    return _buildSeedInventoryCard(context, ref, catalogItem, entry.value);
                  }).toList(),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSeedInventoryCard(
    BuildContext context,
    WidgetRef ref,
    SeedCatalogItem catalogItem,
    int quantity,
  ) {
    return Semantics(
      label: '${catalogItem.name}, $quantity disponibles, afinidad ${catalogItem.affinityEmotion}',
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Solo info, no acción directa
              HapticFeedback.selectionClick();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.pergaminoClaro.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.jade.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.jade.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: catalogItem.spriteStages.isNotEmpty
                        ? Image.asset(
                            'assets/images/chinampa_plants/${catalogItem.spriteStages.first}',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.grass_rounded, color: AppColors.jade, size: 24),
                          )
                        : const Icon(Icons.grass_rounded, color: AppColors.jade, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    catalogItem.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.pergaminoClaro,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.jade.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'x$quantity',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.jade,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${catalogItem.wateringsNeeded} riegos',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.pergaminoClaro.withValues(alpha: 0.5),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Sheet para seleccionar semilla al plantar.
class _SeedSelectorSheet extends ConsumerWidget {
  const _SeedSelectorSheet({
    required this.slotIndex,
    required this.seedCatalogAsync,
    required this.inventoryAsync,
  });

  final int slotIndex;
  final AsyncValue<Map<String, SeedCatalogItem>> seedCatalogAsync;
  final AsyncValue<Map<String, int>> inventoryAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                        'Elige una semilla para la parcela ${slotIndex + 1}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.pergaminoClaro,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Cerrar selector de semillas',
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.pergaminoClaro),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.pergaminoClaro.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: seedCatalogAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.jade)),
                    error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.rojoGrana))),
                    data: (catalog) => inventoryAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.jade)),
                      error: (err, _) => Center(child: Text('Error inventario: $err', style: const TextStyle(color: AppColors.rojoGrana))),
                      data: (inventory) {
                        // Filtrar semillas disponibles (quantity > 0)
                        final availableSeeds = catalog.entries
                            .where((e) => (inventory[e.key] ?? 0) > 0)
                            .toList();

                        if (availableSeeds.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined, color: AppColors.jade, size: 48),
                                const SizedBox(height: 16),
                                Text(
                                  'No tienes semillas disponibles',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.pergaminoClaro),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Escribe en tu diario para recibir semillas\nsegún tu clima emocional.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.pergaminoClaro.withValues(alpha: 0.6)),
                                ),
                              ],
                            ),
                          );
                        }

                        return Column(
                          children: availableSeeds.map((entry) {
                            final catalogItem = entry.value;
                            final quantity = inventory[entry.key] ?? 0;
                            return _buildSeedOptionCard(context, ref, catalogItem, quantity);
                          }).toList(),
                        );
                      },
                    ),
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

  Widget _buildSeedOptionCard(
    BuildContext context,
    WidgetRef ref,
    SeedCatalogItem catalogItem,
    int quantity,
  ) {
    return Semantics(
      label: 'Plantar ${catalogItem.name}, tienes $quantity, requiere ${catalogItem.wateringsNeeded} riegos, afinidad ${catalogItem.affinityEmotion}',
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              HapticFeedback.mediumImpact();
              final controller = ref.read(chinampaControllerProvider);
              try {
                await controller.plantSeedInSlot(slotIndex: slotIndex, seedId: catalogItem.seedId);
                if (context.mounted) {
                  Navigator.of(context).pop(); // Cerrar selector
                  Navigator.of(context).pop(); // Cerrar bottom sheet de chinampa
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('¡${catalogItem.name} plantada en la parcela ${slotIndex + 1}!'),
                      backgroundColor: AppColors.jade,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                  ref.invalidate(refreshChinampaSlotsProvider);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al plantar: $e'),
                      backgroundColor: AppColors.rojoGrana,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.jade.withValues(alpha: 0.1),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.pergaminoClaro.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.jade.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.jade.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: catalogItem.spriteStages.isNotEmpty
                        ? Image.asset(
                            'assets/images/chinampa_plants/${catalogItem.spriteStages.first}',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.grass_rounded, color: AppColors.jade, size: 28),
                          )
                        : const Icon(Icons.grass_rounded, color: AppColors.jade, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          catalogItem.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppColors.pergaminoClaro,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.jade.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'x$quantity disponible',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.jade,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${catalogItem.wateringsNeeded} riegos',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.pergaminoClaro.withValues(alpha: 0.6),
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Afinidad: ${_getEmotionName(catalogItem.affinityEmotion)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.turquesa,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.pergaminoClaro, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getEmotionName(String emotionId) {
    return switch (emotionId) {
      'tlaloc_lluvia' => 'Lluvia de Tláloc',
      'tonatiuh_sol' => 'Sol de Tonatiuh',
      'ehecatl_viento' => 'Viento de Ehécatl',
      'mixcoatl_tormenta' => 'Tormenta de Mixcóatl',
      'metztli_noche' => 'Noche de Metztli',
      _ => emotionId,
    };
  }
}

/// Provider reactivo del inventario del usuario (solo lectura, se actualiza al invalidar).
final userInventoryProvider = FutureProvider<Map<String, int>>((ref) async {
  final db = ref.watch(localDatabaseServiceProvider);
  final inventory = await db.getInventory();
  final result = <String, int>{};
  for (final item in inventory) {
    result[item['item_id'] as String] = item['quantity'] as int? ?? 0;
  }
  return result;
});