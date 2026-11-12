// Providers de reliquias para acceso reactivo desde la UI.
//
// Re-exporta el provider de reliquias desbloqueadas con el nombre
// esperado por la pantalla del Valle (userRelicsProvider).

import '../services/deity_visits_and_relics_service.dart';

/// Provider reactivo de la lista de reliquias desbloqueadas por el usuario.
///
/// Alias de [unlockedRelicsProvider] con el nombre semántico esperado
/// por la pantalla del Valle de Teotihuacán.
final userRelicsProvider = unlockedRelicsProvider;