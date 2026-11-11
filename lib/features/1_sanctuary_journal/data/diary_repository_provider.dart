// Providers para el repositorio de diario y servicios relacionados.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mi_calli/core/database/local_database_service.dart';
import 'package:mi_calli/features/1_sanctuary_journal/services/diary_repository.dart';

/// Provider del servicio de base de datos local (singleton).
///
/// En producción usa el singleton inicializado en main.dart.
/// En tests se puede sobrescribir con una instancia de test.
final localDatabaseServiceProvider = Provider<LocalDatabaseService>((ref) {
  // En producción, el singleton ya está inicializado
  return LocalDatabaseService.instance;
});

/// Provider del repositorio de diario.
///
/// Usa el LocalDatabaseService para acceder a la tabla diary_entries.
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final databaseService = ref.watch(localDatabaseServiceProvider);
  return DiaryRepository(databaseService: databaseService);
});