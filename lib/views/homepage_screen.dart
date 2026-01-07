import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert' show json; // , ascii, base64, jsonDecode, utf8;
import 'dart:developer';

import 'package:jwt_test/services/http_service.dart';

class HomePage extends StatelessWidget {
  final FlutterSecureStorage storage;
  String jwtToken = '';
  Map<String, dynamic> configItems = {};
  Map<String, dynamic> payload = {};

  HomePage(this.storage, {Key? key}) : super(key: key);

  Future<Map<String, dynamic>> loadHomeData() {
    return loadConfig(storage).then((configStr) {
      var config = json.decode(configStr);
      jwtToken = config["jwtToken"];
      configItems = config["configItems"];
      payload = getJwtPayload(jwtToken);
      String apiUrlUsersGetData = configItems['API_URL'] + "/users";
      var api = HttpUtilities(storage);
      log('HomePage | payload: $payload');
      return api.httpsCall("get", apiUrlUsersGetData, {}, {}, {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Secret Data Screen")),
        body: Center(
          child:
          FutureBuilder(
            future: loadHomeData(),
              builder: (context, snapshot) =>
                snapshot.hasData ?
                  ListView(
                    padding: const EdgeInsets.only(
                      top: 10.0,
                      left: 20.00,
                      right: 20.00,
                    ),
                    children: <Widget>[
                      Text("${payload['public_id']}, here's the data:\n"),
                      Text(
                          getApiDataResponse(snapshot),
                      )
                    ],
                  )
                    :
                  snapshot.hasError ?
                    ListView(
                      padding: const EdgeInsets.only(
                        top: 10.0,
                        left: 20.00,
                        right: 20.00,
                      ),
                      children: <Widget>[
                        Text(getApiDataResponse(snapshot))
                      ]
                    )
                      :
                    const CircularProgressIndicator()
          ),
        )
    );
  }
}