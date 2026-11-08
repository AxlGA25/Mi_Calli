// Tests para AssetLoaderService - verifica que los JSON se cargan y parsean correctamente.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:mi_calli/features/1_sanctuary_journal/models/wisdom_feather.dart';
import 'package:mi_calli/features/2_gamification/models/seed_catalog_item.dart';

void main() {
  group('JSON Asset Files', () {
    late File feathersFile;
    late File seedsFile;

    setUpAll(() {
      feathersFile = File('assets/data/feathers.json');
      seedsFile = File('assets/data/seeds_catalog.json');
    });

    test('feathers.json existe y es JSON válido con 5 plumas', () {
      expect(feathersFile.existsSync(), isTrue);

      final String content = feathersFile.readAsStringSync();
      final List<dynamic> jsonList = json.decode(content) as List<dynamic>;

      expect(jsonList.length, equals(5));

      // Verificar estructura de cada pluma
      for (final item in jsonList) {
        final map = item as Map<String, dynamic>;
        expect(map.containsKey('feather_id'), isTrue);
        expect(map.containsKey('emotion_id'), isTrue);
        expect(map.containsKey('name'), isTrue);
        expect(map.containsKey('color_hex'), isTrue);
        expect(map.containsKey('message'), isTrue);

        expect(map['feather_id'], isNotEmpty);
        expect(map['emotion_id'], isNotEmpty);
        expect(map['color_hex'], startsWith('#'));
      }

      // Verificar las 5 emociones únicas
      final emotionIds = jsonList.map((e) => (e as Map)['emotion_id']).toSet();
      expect(emotionIds, equals({
        'tlaloc_lluvia',
        'tonatiuh_sol',
        'ehecatl_viento',
        'mixcoatl_tormenta',
        'metztli_noche',
      }));
    });

    test('seeds_catalog.json existe y es JSON válido con 7 semillas', () {
      expect(seedsFile.existsSync(), isTrue);

      final String content = seedsFile.readAsStringSync();
      final List<dynamic> jsonList = json.decode(content) as List<dynamic>;

      expect(jsonList.length, equals(7));

      // Verificar estructura de cada semilla
      for (final item in jsonList) {
        final map = item as Map<String, dynamic>;
        expect(map.containsKey('seed_id'), isTrue);
        expect(map.containsKey('name'), isTrue);
        expect(map.containsKey('rarity'), isTrue);
        expect(map.containsKey('waterings_needed'), isTrue);
        expect(map.containsKey('affinity_emotion'), isTrue);
        expect(map.containsKey('description'), isTrue);
        expect(map.containsKey('sprite_stages'), isTrue);

        expect(map['seed_id'], isNotEmpty);
        expect(map['rarity'], isIn(['comun', 'rara', 'sagrada']));
        expect(map['waterings_needed'], allOf(isA<int>(), greaterThanOrEqualTo(3), lessThanOrEqualTo(4)));
        expect(map['affinity_emotion'], isNotEmpty);
        expect(map['sprite_stages'], isA<List>());
        expect((map['sprite_stages'] as List).length, greaterThanOrEqualTo(4));
      }

      // Verificar las 7 semillas esperadas
      final seedIds = jsonList.map((e) => (e as Map)['seed_id']).toSet();
      expect(seedIds, equals({
        'seed_cempasuchil',
        'seed_nopal_tunas',
        'seed_maiz_morado',
        'seed_maguey',
        'seed_cacao',
        'seed_dalia',
        'seed_vainilla',
      }));

      // Verificar waterings_needed y affinity_emotion (CONTEXT.md punto 4)
      final cempasuchil = jsonList.firstWhere((e) => (e as Map)['seed_id'] == 'seed_cempasuchil') as Map;
      expect(cempasuchil['waterings_needed'], equals(3));
      expect(cempasuchil['affinity_emotion'], equals('tlaloc_lluvia'));

      final cacao = jsonList.firstWhere((e) => (e as Map)['seed_id'] == 'seed_cacao') as Map;
      expect(cacao['waterings_needed'], equals(4));
      expect(cacao['affinity_emotion'], equals('tonatiuh_sol'));
    });

    test('ambos JSONs se parsean a modelos Dart sin errores', () {
      // Parse feathers
      final feathersContent = feathersFile.readAsStringSync();
      final feathersJson = json.decode(feathersContent) as List<dynamic>;
      final feathers = feathersJson
          .map((e) => WisdomFeather.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(feathers.length, equals(5));
      for (final feather in feathers) {
        expect(feather.featherId, isNotEmpty);
        expect(feather.emotionId, isNotEmpty);
        expect(feather.color.toARGB32(), isA<int>());
      }

      // Parse seeds
      final seedsContent = seedsFile.readAsStringSync();
      final seedsJson = json.decode(seedsContent) as List<dynamic>;
      final seeds = seedsJson
          .map((e) => SeedCatalogItem.fromJson(e as Map<String, dynamic>))
          .toList();

      expect(seeds.length, equals(7));
      for (final seed in seeds) {
        expect(seed.seedId, isNotEmpty);
        expect(seed.wateringsNeeded, greaterThanOrEqualTo(3));
        expect(seed.affinityEmotion, isNotEmpty);
        expect(seed.rarity, isA<SeedRarity>());
        expect(seed.hasAffinityWith(seed.affinityEmotion), isTrue);
      }
    });
  });

  group('WisdomFeather model', () {
    test('fromJson crea instancia correcta', () {
      final json = {
        'feather_id': 'test_01',
        'emotion_id': 'tlaloc_lluvia',
        'name': 'Test Feather',
        'color_hex': '#2A9D8F',
        'message': 'Test message',
      };

      final feather = WisdomFeather.fromJson(json);

      expect(feather.featherId, equals('test_01'));
      expect(feather.emotionId, equals('tlaloc_lluvia'));
      expect(feather.name, equals('Test Feather'));
      expect(feather.colorHex, equals('#2A9D8F'));
      expect(feather.message, equals('Test message'));
      expect(feather.color.toARGB32(), equals(0xFF2A9D8F));
    });

    test('toJson produce mapa correcto', () {
      const feather = WisdomFeather(
        featherId: 'test_01',
        emotionId: 'tlaloc_lluvia',
        name: 'Test Feather',
        colorHex: '#2A9D8F',
        message: 'Test message',
      );

      final json = feather.toJson();

      expect(json['feather_id'], equals('test_01'));
      expect(json['emotion_id'], equals('tlaloc_lluvia'));
      expect(json['name'], equals('Test Feather'));
      expect(json['color_hex'], equals('#2A9D8F'));
      expect(json['message'], equals('Test message'));
    });

    test('equality funciona correctamente', () {
      const feather1 = WisdomFeather(
        featherId: 'test_01',
        emotionId: 'tlaloc_lluvia',
        name: 'Test',
        colorHex: '#2A9D8F',
        message: 'Msg',
      );
      const feather2 = WisdomFeather(
        featherId: 'test_01',
        emotionId: 'tonatiuh_sol',
        name: 'Different',
        colorHex: '#E9C46A',
        message: 'Different',
      );
      const feather3 = WisdomFeather(
        featherId: 'test_02',
        emotionId: 'tlaloc_lluvia',
        name: 'Test',
        colorHex: '#2A9D8F',
        message: 'Msg',
      );

      expect(feather1 == feather2, isTrue);
      expect(feather1 == feather3, isFalse);
    });
  });

  group('SeedCatalogItem model', () {
    test('fromJson crea instancia correcta con todos los campos', () {
      final json = {
        'seed_id': 'seed_test',
        'name': 'Test Seed',
        'rarity': 'comun',
        'waterings_needed': 3,
        'affinity_emotion': 'tlaloc_lluvia',
        'description': 'Test description',
        'sprite_stages': ['stage0.png', 'stage1.png'],
      };

      final seed = SeedCatalogItem.fromJson(json);

      expect(seed.seedId, equals('seed_test'));
      expect(seed.name, equals('Test Seed'));
      expect(seed.rarity, equals(SeedRarity.comun));
      expect(seed.wateringsNeeded, equals(3));
      expect(seed.affinityEmotion, equals('tlaloc_lluvia'));
      expect(seed.description, equals('Test description'));
      expect(seed.spriteStages, equals(['stage0.png', 'stage1.png']));
    });

    test('fromJson maneja rareza mayúscula/minúscula', () {
      final jsonComun = {'rarity': 'COMUN', 'seed_id': 't1', 'name': 't', 'waterings_needed': 3, 'affinity_emotion': 'e', 'description': 'd', 'sprite_stages': []};
      final jsonRara = {'rarity': 'RaRa', 'seed_id': 't2', 'name': 't', 'waterings_needed': 3, 'affinity_emotion': 'e', 'description': 'd', 'sprite_stages': []};
      final jsonSagrada = {'rarity': 'SAGRADA', 'seed_id': 't3', 'name': 't', 'waterings_needed': 3, 'affinity_emotion': 'e', 'description': 'd', 'sprite_stages': []};

      expect(SeedCatalogItem.fromJson(jsonComun).rarity, equals(SeedRarity.comun));
      expect(SeedCatalogItem.fromJson(jsonRara).rarity, equals(SeedRarity.rara));
      expect(SeedCatalogItem.fromJson(jsonSagrada).rarity, equals(SeedRarity.sagrada));
    });

    test('hasAffinityWith detecta emoción de afinidad correctamente', () {
      const seed = SeedCatalogItem(
        seedId: 'seed_cempasuchil',
        name: 'Cempasúchil',
        rarity: SeedRarity.comun,
        wateringsNeeded: 3,
        affinityEmotion: 'tlaloc_lluvia',
        description: 'Desc',
        spriteStages: [],
      );

      expect(seed.hasAffinityWith('tlaloc_lluvia'), isTrue);
      expect(seed.hasAffinityWith('tonatiuh_sol'), isFalse);
      expect(seed.hasAffinityWith('ehecatl_viento'), isFalse);
    });

    test('toJson produce mapa correcto', () {
      const seed = SeedCatalogItem(
        seedId: 'seed_test',
        name: 'Test Seed',
        rarity: SeedRarity.rara,
        wateringsNeeded: 4,
        affinityEmotion: 'ehecatl_viento',
        description: 'Test description',
        spriteStages: ['s0.png'],
      );

      final json = seed.toJson();

      expect(json['seed_id'], equals('seed_test'));
      expect(json['name'], equals('Test Seed'));
      expect(json['rarity'], equals('rara'));
      expect(json['waterings_needed'], equals(4));
      expect(json['affinity_emotion'], equals('ehecatl_viento'));
      expect(json['description'], equals('Test description'));
      expect(json['sprite_stages'], equals(['s0.png']));
    });

    test('equality funciona correctamente', () {
      const seed1 = SeedCatalogItem(
        seedId: 'seed_test',
        name: 'Test',
        rarity: SeedRarity.comun,
        wateringsNeeded: 3,
        affinityEmotion: 'tlaloc_lluvia',
        description: 'Desc',
        spriteStages: [],
      );
      const seed2 = SeedCatalogItem(
        seedId: 'seed_test',
        name: 'Different',
        rarity: SeedRarity.sagrada,
        wateringsNeeded: 4,
        affinityEmotion: 'tonatiuh_sol',
        description: 'Different',
        spriteStages: [],
      );
      const seed3 = SeedCatalogItem(
        seedId: 'seed_other',
        name: 'Test',
        rarity: SeedRarity.comun,
        wateringsNeeded: 3,
        affinityEmotion: 'tlaloc_lluvia',
        description: 'Desc',
        spriteStages: [],
      );

      expect(seed1 == seed2, isTrue);
      expect(seed1 == seed3, isFalse);
    });
  });
}