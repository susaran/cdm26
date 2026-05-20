import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart' show Ref;

part 'api_football_service.g.dart';

@riverpod
ApiFootballService apiFootballService(Ref ref) => ApiFootballService();

/// Thin client around API-Football v3 (api-sports.io).
/// All heavy data ingestion (scheduled pulls, storage to Firestore)
/// is done in Cloud Functions — this client is only used for
/// on-demand requests from the Flutter app (e.g. lineups on demand).
class ApiFootballService {
  static const int _worldCup2026LeagueId = 1; // confirm with API-Football docs
  static const int _worldCup2026Season = 2026;

  late final Dio _dio;

  ApiFootballService() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_FOOTBALL_BASE_URL'] ??
          'https://v3.football.api-sports.io',
      headers: {
        'x-apisports-key': dotenv.env['API_FOOTBALL_KEY'] ?? '',
      },
    ));
  }

  Future<Map<String, dynamic>> getFixtures({int? round}) async {
    final response = await _dio.get('/fixtures', queryParameters: {
      'league': _worldCup2026LeagueId,
      'season': _worldCup2026Season,
      if (round != null) 'round': round,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLineups(int fixtureId) async {
    final response = await _dio.get('/fixtures/lineups', queryParameters: {
      'fixture': fixtureId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFixtureStats(int fixtureId) async {
    final response = await _dio.get('/fixtures/statistics', queryParameters: {
      'fixture': fixtureId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getFixtureEvents(int fixtureId) async {
    final response = await _dio.get('/fixtures/events', queryParameters: {
      'fixture': fixtureId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getSquad(int teamId) async {
    final response = await _dio.get('/players/squads', queryParameters: {
      'team': teamId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getStandings() async {
    final response = await _dio.get('/standings', queryParameters: {
      'league': _worldCup2026LeagueId,
      'season': _worldCup2026Season,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getPlayerStats(
      int playerId, int fixtureId) async {
    final response = await _dio.get('/fixtures/players', queryParameters: {
      'fixture': fixtureId,
    });
    return response.data as Map<String, dynamic>;
  }
}
