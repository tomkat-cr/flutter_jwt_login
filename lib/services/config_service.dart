import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class ConfigService {
  static Future<Map<String, dynamic>> getConfigItems() {
    // Here you would fetch the base URL from a config file
    return _readConfigFile();
  }

  static Future<Map<String, dynamic>> _readConfigFile() async {
    // https://stackoverflow.com/questions/44816042/flutter-read-text-file-from-assets
    var configContent = await rootBundle.loadString('assets/config/config.json');
    return json.decode(configContent);
  }
}
