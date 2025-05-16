import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'location_service.dart';
import 'search_service.dart';

class MapController {
  String currentAddress = 'Загрузка';
  mp.MapboxMap? mapboxController;
  mp.PointAnnotationManager? _pointAnnotationManager;
  final LocationService _locationService = LocationService();
  final SearchService _searchService = SearchService();
  StreamSubscription? userPositionStream;

  Future<void> onMapCreated(mp.MapboxMap controller) async {
    mapboxController = controller;
    mapboxController?.location.updateSettings(
      mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
    _searchService.mapboxController = controller;
  }

  Future<void> setupPositionTracking() async {
    await _locationService.checkPermissions();
    userPositionStream = _locationService.positionStream.listen((position) async {
      if (position != null && mapboxController != null) {
        mapboxController?.setCamera(
          mp.CameraOptions(
            zoom: 15,
            center: mp.Point(
              coordinates: mp.Position(position.longitude, position.latitude),
            ),
          ),
        );

        try {
          final address = await _locationService.getAddressFromCoordinates(
              position.latitude, position.longitude);
          currentAddress = address;
        } catch (e) {
          debugPrint('Ошибка при получении адреса: $e');
        }
      }
    });
  }

  Future<void> searchStreet(String query) async {
    await _searchService.searchStreet(query);
  }

  Future<Uint8List> loadHQMarkerImage() async {
    var byteData = await rootBundle.load('assets/icons/flag.png');
    return byteData.buffer.asUint8List();
  }

  void dispose() {
    userPositionStream?.cancel();
    _searchService.dispose();
  }
}