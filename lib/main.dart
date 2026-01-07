import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert' show json; //, base64, ascii, utf8;
// CR: Only for debugging while developing:
import 'dart:developer';

import 'services/http_service.dart';
import 'services/config_service.dart';
import 'views/login_screen.dart';
import 'views/dishes_screen.dart';
// import 'views/homepage_screen.dart';

const storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final Map<String, dynamic> configItems = await ConfigService.getConfigItems();
  runApp(MyApp(configItems));
}

class MyApp extends StatelessWidget {
  final Map<String, dynamic> configItems;

  const MyApp(this.configItems, {Key? key}) : super(key: key);

  Future<String> get jwtOrEmpty async {
    var jwt = await storage.read(key: "jwt");
    if(jwt == null) return "";
    return jwt;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authentication Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FutureBuilder(
          future: jwtOrEmpty,
          builder: (context, snapshot) {
            if(!snapshot.hasData) return const CircularProgressIndicator();
            if(snapshot.data != "") {

              log('MyApp | configItems: $configItems');
              storage.write(key: "configItems", value: json.encode(configItems));
              log('CR MyApp | storage: $storage');

              log('CR MyApp | snapshot.data: ${snapshot.data}');

              var str = snapshot.data.toString();
              var jwt = str.split(".");

              if(jwt.length !=3) {
                // return LoginPage(storage, configItems);
                return LoginPage(storage);
              } else {
                var payload = getJwtPayload(str);
                // var payload = json.decode(ascii.decode(base64.decode(base64.normalize(jwt[1]))));
                if(DateTime.fromMillisecondsSinceEpoch(payload["exp"]*1000).isAfter(DateTime.now())) {
                  // return HomePage(configItems, str, payload);
                  // return (!redirectToCrud ? HomePage(storage) : CrudEditor(storage));
                  return const CrudEditor(storage);
                } else {
                  // return LoginPage(storage, configItems);
                  return LoginPage(storage);
                }
              }
            } else {
              // return LoginPage(storage, configItems);
              return LoginPage(storage);
            }
          }
      ),
    );
  }
}
