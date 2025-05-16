import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;

class SearchService {
  final String mapboxAccessToken =
      'pk.eyJ1Ijoicm9tYWJveTEyIiwiYSI6ImNtOWN3bzJmdjBuY3Eya3NhdmQzcW92dzkifQ.YCWRB3usCdTRDNOkrun9xg';
  mp.MapboxMap? mapboxController;
  mp.PointAnnotationManager? _pointAnnotationManager;
  Timer? _debounce;
  List<String> searchResults = [];

  Future<void> searchStreet(String query) async {
    if (query.isEmpty) {
      searchResults = [];
      await _pointAnnotationManager?.deleteAll();
      return;
    }

    final encodedQuery = Uri.encodeComponent(query);
    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json'
      '?access_token=$mapboxAccessToken'
      '&autocomplete=true'
      '&limit=10'
      '&language=ru'
      '&country=kz'
      '&types=address,street',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        if (features.isEmpty) {
          searchResults = ['Ничего не найдено'];
          return;
        }

        await _pointAnnotationManager?.deleteAll();
        _pointAnnotationManager ??= await mapboxController?.annotations
            .createPointAnnotationManager();

        final Uint8List imageData = await _loadHQMarkerImage();
        searchResults = [];

        for (final feature in features) {
          try {
            final coords = feature['geometry']['coordinates'] as List;
            final lng = coords[0] as double;
            final lat = coords[1] as double;
            final name = feature['place_name'] as String;

            _pointAnnotationManager?.create(
              mp.PointAnnotationOptions(
                image: imageData,
                iconSize: 0.1,
                geometry: mp.Point(
                  coordinates: mp.Position(lng, lat),
                ),
              ),
            );
            searchResults.add(name);
          } catch (e) {
            debugPrint('Ошибка обработки feature: $e');
          }
        }
      } else {
        debugPrint('Ошибка API: ${response.statusCode}');
        searchResults = ['Ошибка поиска'];
      }
    } catch (e) {
      debugPrint('Ошибка сети: $e');
      searchResults = ['Проверьте подключение'];
    }
  }

  Future<Uint8List> _loadHQMarkerImage() async {
    var byteData = await rootBundle.load('assets/icons/flag.png');
    return byteData.buffer.asUint8List();
  }

  void dispose() {
    _debounce?.cancel();
  }
}