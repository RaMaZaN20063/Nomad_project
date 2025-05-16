import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as gl;

class LocationService {
  Future<void> checkPermissions() async {
    bool serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Службы определения местоположения отключены');
    }

    gl.LocationPermission permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) {
        throw Exception('Служба определения местоположения отказано');
      }
    }

    if (permission == gl.LocationPermission.deniedForever) {
      throw Exception(
          'Разрешения на определение местоположения постоянно отклонены');
    }
  }

  Stream<gl.Position?> get positionStream {
    gl.LocationSettings locationSettings = gl.LocationSettings(
      accuracy: gl.LocationAccuracy.high,
      distanceFilter: 100,
    );
    return gl.Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isNotEmpty) {
      return placemarks[0].street ?? 'Неизвестная улица';
    }
    return 'Адрес не найден';
  }
}