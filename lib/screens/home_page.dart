import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart' as gl;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _currentAddress = 'Загрузка';
  mp.MapboxMap? mapboxController;
  StreamSubscription? userPositionStream;
  //Для Search
  TextEditingController _searchController = TextEditingController();
  List<String> _searchResults = [];
  Timer? _debounce;
  String mapboxAccessToken =
      'pk.eyJ1Ijoicm9tYWJveTEyIiwiYSI6ImNtOWN3bzJmdjBuY3Eya3NhdmQzcW92dzkifQ.YCWRB3usCdTRDNOkrun9xg';
  // будеть спрашивать permission and services enable один раз
  @override
  void initState() {
    super.initState();
    _setupPositionTracking();
    // Используй WidgetsBinding.instance.addPostFrameCallback в initState, чтобы показать BottomSheet, когда экран уже построен:
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _displayBottomSheet(context);
    });
  }

  @override
  void dispose() {
    userPositionStream?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: mp.MapWidget(
        onMapCreated: _onMapCreated,
        styleUri: mp.MapboxStyles.LIGHT,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _displayBottomSheet(context);
        },
        child: Icon(Icons.search),
      ),
    );
  }

  void _onMapCreated(mp.MapboxMap controller) async {
    setState(() {
      mapboxController = controller;
    });
    mapboxController?.location.updateSettings(
      mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );
  }

  Future<void> _setupPositionTracking() async {
    bool serviceEnabled;
    gl.LocationPermission permission;

    serviceEnabled = await gl.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Службы определения местоположения отключены');
    }

    permission = await gl.Geolocator.checkPermission();
    if (permission == gl.LocationPermission.denied) {
      permission = await gl.Geolocator.requestPermission();
      if (permission == gl.LocationPermission.denied) {
        return Future.error('Служба определения местоположения отказано');
      }
    }

    if (permission == gl.LocationPermission.deniedForever) {
      return Future.error(
        'Разрешения на определение местоположения постоянно отклонены, мы не можем запрашивать разрешения',
      );
    }

    //пользователь сдвинулся на 100 метров или больше , accuracy: high — использовать точное определение (GPS).
    gl.LocationSettings locationSettings = gl.LocationSettings(
      accuracy: gl.LocationAccuracy.high,
      distanceFilter: 100,
    );
    //Если поток уже был запущен раньше — отменяем его, чтобы не запускать повторно и избежать утечек памяти.
    userPositionStream?.cancel();
    //здесь наш камера двигается когда юсер тоже двигается
    userPositionStream = gl.Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((gl.Position? position) async {
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
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );
          if (placemarks.isNotEmpty) {
            final street = placemarks[0].street ?? 'Неизвестная улица';
            setState(() {
              _currentAddress = street;
            });
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
            _displayBottomSheet(context);
          }
        } catch (e) {
          print('Ошибка при получении адреса: $e');
        }
      }
      // if (position != null) {
      //   print(position);
      // }
    });
  }

//Добавлено поле _pointAnnotationManager для хранения менеджера аннотаций
// Добавьте это как поле вашего класса
mp.PointAnnotationManager? _pointAnnotationManager;

Future<void> _searchStreet(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      
      // Удаляем все аннотации при пустом запросе
      await _pointAnnotationManager?.deleteAll();
      return;
    }

    final encodedQuery = Uri.encodeComponent(query);

    final url = Uri.parse(
      'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json'
      '?access_token=$mapboxAccessToken'
      '&autocomplete=true'
      '&limit=5'
      '&language=ru'
      '&bbox=71.20,42.70,71.60,43.10'
      '&country=kz',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        if (features.isEmpty) {
          print('Нет результатов для запроса: $query');
        }

        // Удаляем старые аннотации перед добавлением новых
        await _pointAnnotationManager?.deleteAll();
        
        // Создаем менеджер аннотаций (если еще не создан)
        //??= равен на null
        _pointAnnotationManager ??= await mapboxController?.annotations.createPointAnnotationManager();
        final Uint8List imageData = await loadHQMarkerImage();

        // Обрабатываем каждый найденный результат
        features.forEach((feature) {
          final coordinates = feature['geometry']['coordinates'] as List;
          final lng = coordinates[0] as double;
          final lat = coordinates[1] as double;
          
          print('Место: ${feature['place_name']}, Координаты: $lng, $lat');

          final pointAnnotationOptions = mp.PointAnnotationOptions(
            image: imageData,
            iconSize: 0.1,
            geometry: mp.Point(
              coordinates: mp.Position(lng, lat),
            ),
          );

          _pointAnnotationManager?.create(pointAnnotationOptions);
        });

        setState(() {
          _searchResults = features.map((f) => f['place_name'] as String).toList();
        });
      } else {
        print('Ошибка: ${response.statusCode}');
        setState(() => _searchResults = []);
        await _pointAnnotationManager?.deleteAll();
      }
    } catch (e) {
      print('Ошибка при поиске: $e');
      setState(() => _searchResults = []);
      await _pointAnnotationManager?.deleteAll();
    }
  }

  //  Future<void> _onMapCreated(MapboxMap controller) async{
  //   setState(() {
  //     mapboxController = controller;
  //   });
  //   final status = await Permission.location.request();
  //   if (status.isGranted) {
  //     await mapboxController?.location.updateSettings(
  //     LocationComponentSettings(
  //       enabled: true,
  //       pulsingEnabled: true
  //     )
  //   );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Разрешение на местоположение не получено'))
  //     );
  //   }

  //  }
  Future _displayBottomSheet(BuildContext context) {
    // double _initialHeight = 250;
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      //для не затемнее заднего фона
      barrierColor: Colors.transparent,
      builder: (context) {
        // double _bottomSheetHeight = 250;
        // double _height = _initialHeight;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
            final expandedHeight = 650.0;
            final initialHeight = 250.0;
            final currentHeight =
                keyboardHeight > 0 ? expandedHeight : initialHeight;

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                height: currentHeight,
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _currentAddress,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Divider(),
                    Row(
                      children: [
                        Icon(Icons.flag),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              if (_debounce?.isActive ?? false) {
                                _debounce?.cancel();
                              }
                              _debounce = Timer(
                                Duration(milliseconds: 200),
                                () {
                                  _searchStreet(value);
                                },
                              );
                            },
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              labelText: 'Куда едем?',
                              labelStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      color: Colors.black,
                      width: double.infinity,
                      height: 1,
                    ),
                    Expanded(
                      child:
                          _searchResults.isEmpty
                              ? Center(
                                child: Text(
                                  'Начните вводить адрес',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                              : ListView.builder(
                                itemCount: _searchResults.length,
                                itemBuilder: (context, index) {
                                  // Добавляем проверку на валидность индекса
                                  if (index >= _searchResults.length) {
                                    return SizedBox.shrink();
                                  }
                                  final place = _searchResults[index];
                                  if (place! is String) {
                                    return ListTile(
                                      title: Text(place),
                                      onTap: () {
                                        setState(() {
                                          _searchController.text = place;
                                          _searchResults = [];
                                        });
                                        FocusScope.of(context).unfocus();
                                        // Here you can add code to move the map to the selected location
                                      },
                                    );
                                  }
                                },
                              ),
                    ),
                    if (!(keyboardHeight > 0))
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                          ),
                          child: Text('Продолжить'),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  //делает image Uint8List и дает нам чтобы показалась в mapbox
  Future<Uint8List> loadHQMarkerImage() async {
    var byteData = await rootBundle.load('assets/icons/flag.png');
    return byteData.buffer.asUint8List();
  }
}
