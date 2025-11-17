import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

enum MapProvider {
  openStreetMap,
  googleMaps;
}

class TileProvider {
  // Singleton pattern
  TileProvider._();
  static final TileProvider instance = TileProvider._();

  _MapTileProviderAbstract? _currentProvider;

  bool get isInitialized =>
      TileProvider.instance._currentProvider?.isInitialized ?? false;

  Future<bool> initialize({required MapProvider tileProvider}) async {
    final instance = TileProvider.instance;
    instance._currentProvider = switch (tileProvider) {
      MapProvider.googleMaps => _GoogleTileProvider(),
      MapProvider.openStreetMap => _OpenStreetMapTileProvider()
    };

    return await instance._currentProvider!.initialize();
  }

  String get urlTile {
    final instance = TileProvider.instance;
    if (instance._currentProvider == null) {
      throw Exception('Tile provider is not initialized');
    }
    return instance._currentProvider!.urlTile;
  }
}

abstract class _MapTileProviderAbstract {
  String get urlTile;
  bool get isInitialized;
  Future<bool> initialize();
}

class _GoogleTileProvider extends _MapTileProviderAbstract {
  @override
  bool get isInitialized => _isTokenValid && _apiKey.isNotEmpty;

  static String get _apiKey {
    const fromDartDefined =
        String.fromEnvironment('STAGESS_GOOGLE_MAPS_API_KEY');
    if (fromDartDefined.isNotEmpty) return fromDartDefined;
    throw Exception('Google Maps API key is not defined');
  }

  static String? _sessionTokenCache;
  static DateTime? _sessionTokenExpiry;
  static bool get _isTokenValid =>
      _sessionTokenCache != null &&
      _sessionTokenExpiry != null &&
      DateTime.now().isBefore(_sessionTokenExpiry!);

  @override
  Future<bool> initialize() async {
    // Create a new session token
    final response = await http.post(
      Uri.parse('https://tile.googleapis.com/v1/createSession?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(
          {'mapType': 'roadmap', 'language': 'fr-CA', 'region': 'CA'}),
    );
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to create Google Maps session: ${response.statusCode} ${response.reasonPhrase}');
    }

    // Parse the response body to extract the session token and expiry
    final responseBody = jsonDecode(response.body);
    _sessionTokenCache = responseBody['session'];
    _sessionTokenExpiry = DateTime.fromMillisecondsSinceEpoch(
        int.parse(responseBody['expiry']) * 1000);
    return true;
  }

  @override
  String get urlTile {
    if (!_isTokenValid) throw Exception('Session token is not initialized');
    return 'https://tile.googleapis.com/v1/2dtiles/{z}/{x}/{y}?session=$_sessionTokenCache&key=$_apiKey';
  }
}

class _OpenStreetMapTileProvider extends _MapTileProviderAbstract {
  @override
  bool get isInitialized => true;

  @override
  Future<bool> initialize() async {
    // No initialization needed for OpenStreetMap
    return true;
  }

  @override
  String get urlTile => 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
}
