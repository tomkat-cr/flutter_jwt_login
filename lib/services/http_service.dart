import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HttpUtilities {
  final FlutterSecureStorage storage;

  HttpUtilities(this.storage);

  String jwtToken = '';
  Map<String, dynamic> configItems = {};

  Future<Map<String, dynamic>> httpsCall(
      String requestType,
      String apiUrl,
      Map<String, dynamic> customHeaders,
      Map<String, dynamic> bodyParams,
      Map<String, dynamic> getParams,
    ) async {

    return loadConfig(storage).then((configStr) async {
      var config = json.decode(configStr);
      jwtToken = config["jwtToken"];
      configItems = config["configItems"];
      log('CR HttpUtilities | 2) _loadConfig() } | jwtToken: $jwtToken | configItems: $configItems');

      log('CR httpsCall | jwt: $jwtToken');
      log('CR httpsCall | configItems: $configItems');

      HttpClient client = HttpClient();
      if (configItems['ENV'] == "local") {
        client.badCertificateCallback = ((X509Certificate cert, String host, int port) => true);
      }
      String url = apiUrl;
      if (getParams.isNotEmpty) {
        url += '?';
        getParams.forEach((key, value) {
          url += '$key=${Uri.encodeComponent(value.toString())}&';
        });
        // Remove the last '&' or replace with a more efficient method
        url = url.substring(0, url.length - 1);
      }
      HttpClientRequest request;
      switch(requestType) {
        case "get":
          request = await client.getUrl(Uri.parse(url));
          break;
        case "put":
          request = await client.putUrl(Uri.parse(url));
          break;
        case "delete":
          request = await client.deleteUrl(Uri.parse(url));
          break;
        default:
          request = await client.postUrl(Uri.parse(url));
      }
      if (jwtToken != '') {
        request.headers.set('Authorization', jwtToken);
      }
      customHeaders.forEach((key, value) {
        request.headers.set(key, value);
      });
      if (bodyParams.isNotEmpty) {
        // request.add(utf8.encode(json.encode(bodyParams)));
        var jsonPayload = json.encode(bodyParams);
        request.headers.set('Content-Type', 'application/json; charset=UTF-8');
        request.write(jsonPayload);
      }
      HttpClientResponse response = await request.close();
      String reply = await response.transform(utf8.decoder).join();
      log('CR httpsCall | res.statusCode: ${response.statusCode}');
      log('CR httpsCall | res.body: $reply');
      String result;
      if(response.statusCode == 200) {
        result = reply;
      } else {
        result = '{"error": true, "error_message": "$reply", "status_code": "${response.statusCode}", "resultset": {}}';
      }
      return json.decode(result);
    });
  }
}

String getApiDataResponse(AsyncSnapshot snapshot) {
  String errorMessage = "";
  if (snapshot.hasError) {
    errorMessage = "An error occurred [GADR-E010]";
  }
  if (!snapshot.hasData) {
    errorMessage = "No data [GADR-E020]";
  }
  if (errorMessage.isNotEmpty) {
    return "$errorMessage | $snapshot";
  }
  var apiResponse = snapshot.data;
  if(apiResponse['error']) {
    return apiResponse['error_message'];
  }
  return apiResponse['resultset'];
}

String bToA(str) {
  final bytes = utf8.encode(str);
  final base64Str = base64.encode(bytes);
  return base64Str;
}

Map<String, dynamic> getJwtPayload(String jwtTokenRaw) {
  log('CR getJwtPayload | jwtTokenRaw: $jwtTokenRaw');
  var jwt = jwtTokenRaw.split(".");
  Map<String, dynamic> jwtPayload = {};
  if(jwt.length ==3) {
    jwtPayload = json.decode(
        ascii.decode(
            base64.decode(base64.normalize(jwt[1]))
        )
    );
  }
  return jwtPayload;
}

Future<String> loadConfig(FlutterSecureStorage storage) async {
  String jwtToken = '';
  Map<String, dynamic> configItems = {};
  return storage.read(key: "jwt").then((jwtTokenValue) {
    return storage.read(key: "configItems").then((configItemsValue) {
      log('http_service | loadConfig | configItemsValue: $configItemsValue');
      if (jwtTokenValue != null) {
        jwtToken = jwtTokenValue;
      }
      if (configItemsValue != null) {
        configItems = json.decode(configItemsValue);
      }
      return json.encode({
        'jwtToken': jwtToken,
        'configItems': configItems,
      });
    });
  });
}
