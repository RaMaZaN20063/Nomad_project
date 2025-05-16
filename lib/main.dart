import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:my_part_project/screens/home_page.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await setup();
  runApp(const MyApp());
}

//здесь мы получаем токен из папки env
Future<void> setup() async{
  await dotenv.load(fileName: ".env",
  );
  MapboxOptions.setAccessToken(
    dotenv.env["MAPBOX_ACCESS_TOKEN"]!,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true
      ),
      home: HomePage(),
    );
  }
}