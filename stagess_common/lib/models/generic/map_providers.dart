import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:stagess_common/models/generic/address.dart';
import 'package:xml/xml.dart';

enum MapTileProvider {
  openStreetMap,
  googleMaps;
}

enum MapReverseGeocodingProvider {
  openStreetMap,
  googleMaps;
}

class TileProvider {
  // Singleton pattern
  TileProvider._();
  static final TileProvider instance = TileProvider._();

  MapTileProvider? _mapTileProvider;
  MapTileProvider get mapTileProvider {
    if (instance._mapTileProvider == null) {
      throw Exception('Tile provider is not initialized');
    }
    return instance._mapTileProvider!;
  }

  _TileProviderAbstract? _provider;

  bool get isInitialized => instance._provider?.isInitialized ?? false;

  Future<bool> initialize({required MapTileProvider provider}) async {
    instance._mapTileProvider = provider;
    instance._provider = switch (instance._mapTileProvider!) {
      MapTileProvider.googleMaps => _GoogleTileProvider(),
      MapTileProvider.openStreetMap => _OpenStreetMapTileProvider()
    };

    return await instance._provider!.initialize();
  }

  String get urlTile {
    final instance = TileProvider.instance;
    if (instance._provider == null) {
      throw Exception('Tile provider is not initialized');
    }
    return instance._provider!.urlTile;
  }
}

abstract class _TileProviderAbstract {
  String get urlTile;
  bool get isInitialized;
  Future<bool> initialize();
}

class _GoogleTileProvider extends _TileProviderAbstract {
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

class _OpenStreetMapTileProvider extends _TileProviderAbstract {
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

class ReverseGeocodingProvider {
  // Singleton pattern
  ReverseGeocodingProvider._();
  static final ReverseGeocodingProvider instance = ReverseGeocodingProvider._();

  _ReverseGeocodingProviderAbstract? _currentProvider;

  bool get isInitialized => instance._currentProvider?.isInitialized ?? false;

  Future<bool> initialize(
      {required MapReverseGeocodingProvider provider}) async {
    instance._currentProvider = switch (provider) {
      MapReverseGeocodingProvider.googleMaps =>
        _GoogleReverseGeocodingProvider(),
      MapReverseGeocodingProvider.openStreetMap =>
        _OpenStreetMapReverseGeocodingProvider()
    };

    return await instance._currentProvider!.initialize();
  }

  Future<Address?> find(String value, {String? id}) async {
    final instance = ReverseGeocodingProvider.instance;
    if (instance._currentProvider == null) {
      throw Exception('Tile provider is not initialized');
    }
    return await instance._currentProvider!.find(value, id: id);
  }
}

abstract class _ReverseGeocodingProviderAbstract {
  bool get isInitialized;
  Future<bool> initialize();
  Future<Address?> find(String value, {String? id});
}

class _GoogleReverseGeocodingProvider
    extends _ReverseGeocodingProviderAbstract {
  @override
  bool get isInitialized => _apiKey.isNotEmpty;

  static String get _apiKey {
    const fromDartDefined =
        String.fromEnvironment('STAGESS_GOOGLE_MAPS_API_KEY');
    if (fromDartDefined.isNotEmpty) return fromDartDefined;
    final fromEnvironment = Platform.environment['STAGESS_GOOGLE_MAPS_API_KEY'];
    if (fromEnvironment?.isNotEmpty ?? false) return fromEnvironment!;
    throw Exception('Google Maps API key is not defined');
  }

  @override
  Future<bool> initialize() async {
    // No initialization needed for Google Maps reverse geocoding
    return true;
  }

  @override
  Future<Address?> find(String value, {String? id}) async {
    if (value.isEmpty) return null;

    final response = await http.get(Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/xml?'
      'address=${value.replaceAll(' ', '+').replaceAll('#', '')}'
      '&key=$_apiKey',
    ));
    if (response.statusCode != 200) return null;

    try {
      final data = XmlDocument.parse(response.body);

      final location = data.findAllElements('location').first;
      final latitude =
          double.parse(location.findElements('lat').first.innerText);
      final longitude =
          double.parse(location.findElements('lng').first.innerText);

      int? civicNumber;
      String? street;
      String? city;
      String? postalCode;
      String? apartment;
      for (final component in data.findAllElements('address_component')) {
        final types =
            component.findAllElements('type').map((e) => e.innerText).toList();
        final longName = component.findElements('long_name').first.innerText;
        if (types.contains('street_number')) {
          civicNumber = int.tryParse(longName);
        } else if (types.contains('route')) {
          street = longName;
        } else if (types.contains('locality')) {
          city = longName;
        } else if (types.contains('postal_code')) {
          postalCode = longName;
        } else if (types.contains('subpremise')) {
          apartment = longName;
        }
      }

      return Address(
        id: id,
        civicNumber: civicNumber,
        street: street,
        city: city,
        postalCode: postalCode,
        apartment: apartment,
        latitude: latitude,
        longitude: longitude,
      );
    } catch (e) {
      return null;
    }
  }
}

class _OpenStreetMapReverseGeocodingProvider
    extends _ReverseGeocodingProviderAbstract {
  @override
  bool get isInitialized => true;

  @override
  Future<bool> initialize() async {
    // No initialization needed for OpenStreetMap reverse geocoding
    return true;
  }

  @override
  Future<Address?> find(String value, {String? id}) async {
    var url = 'https://nominatim.openstreetmap.org/search?format=json&q=$value';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final dataList = json.decode(response.body) as List<dynamic>;
    final latitude = double.parse(dataList.first['lat']);
    final longitude = double.parse(dataList.first['lon']);

    url =
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude';
    response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return null;

    final dataMap = json.decode(response.body) as Map<String, dynamic>;
    if (dataMap.isEmpty) return null;

    return Address(
      civicNumber: int.tryParse(dataMap['address']?['house_number'] ?? ''),
      street: dataMap['address']?['road'],
      city: dataMap['address']?['city'],
      postalCode: dataMap['address']?['postcode'],
      latitude: latitude,
      longitude: longitude,
    );
  }
}
