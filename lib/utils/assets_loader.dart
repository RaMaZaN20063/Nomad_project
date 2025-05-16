import 'package:flutter/services.dart';
import 'dart:typed_data';

class AssetsLoader {
  static Future<Uint8List> loadHQMarkerImage() async {
    final byteData = await rootBundle.load('assets/icons/flag.png');
    return byteData.buffer.asUint8List();
  }
}
