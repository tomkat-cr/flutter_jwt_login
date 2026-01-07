import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:http/http.dart' as http;

import 'package:jwt_test/services/http_service.dart';
import 'package:jwt_test/services/message_services.dart';

class CrudEditor extends StatefulWidget {
  final FlutterSecureStorage storage;

  const CrudEditor(this.storage, {Key? key}) : super(key: key);

  @override
  _CrudEditorState createState() => _CrudEditorState();
}

class _CrudEditorState extends State<CrudEditor> {
  Map<String, dynamic> configItems = {};
  String jwtToken = '';
  String apiBaseUrl = '';

  String urlGenSuffix = 'dishes';

  List<dynamic> items = [];
  dynamic selectedItem;
  bool isEditMode = false;
  bool isCreation = false;
  bool errorStatus = false;
  Map<String, dynamic> apiResponse = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadConfig().then((result) {
      _loadItems().then((result) {
        return true;
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (errorStatus) {
        log('CR _CrudEditorState | (3) BAD | apiResponse: $apiResponse');
        // return ErrorReporter(message: apiResponse['error_message']);
        String errorMessage = "${apiResponse['error_message']} [FGCE-E010]";
        showScaffoldMessage(errorMessage, context);
      }
    });
  }

  Future<bool> _loadConfig() async {
    log('CRUD | 1) loadconfig...');
    return loadConfig(widget.storage).then((configStr) {
      var config = json.decode(configStr);
      jwtToken = config["jwtToken"];
      configItems = config["configItems"];
      apiBaseUrl = configItems['API_URL'];
      log('CRUD | 2) loadconfig | apiBaseUrl: $apiBaseUrl | configItems: $configItems | jwtToken: $jwtToken');
      return true;
    });
  }

  Future<Map<String, dynamic>> _runApiCall(String urlSuffix, String requestMethod, dynamic bodyParams, Map<String, dynamic> getParams) async {
    setState(() {
      _isLoading = true;
    });
    HttpUtilities api = HttpUtilities(widget.storage);
    Map<String, dynamic> body = bodyParams.cast<String, dynamic>();
    log('CRUD | _runApiCall | urlSuffix: $urlSuffix | body: $body | getParams: $getParams');
    final localApiResp = await api.httpsCall(requestMethod, '$apiBaseUrl/$urlSuffix', {}, body, getParams);
    setState(() {
      if (localApiResp['error']) {
        errorStatus = true;
      } else {
        items = json.decode(localApiResp['resultset']);
      }
      apiResponse = localApiResp;
      _isLoading = false;
    });
    return localApiResp;
  }

  Future<void> _loadItems() async {
    log('CRUD | (1) _loadItems | apiBaseUrl: $apiBaseUrl | configItems: $configItems | jwtToken: $jwtToken');
    dynamic body = {};
    Map<String, dynamic> getParams = {};
    final localApiResp = await _runApiCall(urlGenSuffix, 'get', body, getParams);
    log('CRUD | (2) _loadItems | localApiResp: $localApiResp');
    // final localApiResp = await api.httpsCall("get", '$apiBaseUrl/dishes', {}, {}, {});
    // if (localApiResp['error']) {
    //   setState(() {
    //     errorStatus = true;
    //     apiResponse = localApiResp;
    //   });
    // } else {
    //   setState(() {
    //     items = json.decode(localApiResp['resultset']);
    //     apiResponse = localApiResp;
    //   });
    // }
  }

  Future<void> _saveItem(dynamic item) async {
    Map<String, dynamic> getParams = {};
    final localApiResp = await _runApiCall(urlGenSuffix, (isCreation ? 'post' : 'put'), item, getParams);
    if (localApiResp['error'] == false) {
      _loadItems();
      setState(() {
        isEditMode = false;
        isCreation = false;
      });
    }
    // final response = await http.put(
    //   Uri.parse('$apiBaseUrl/dishes/${item['_id']}'),
    //   headers: {
    //     'Content-Type': 'application/json',
    //     'Authorization': 'Bearer $jwtToken'
    //   },
    //   body: jsonEncode(item),
    // );
    // if (response.statusCode == 200) {
    //   _loadItems();
    //   setState(() {
    //     isEditMode = false;
    //   });
    // }
  }

  Future<void> _deleteItem(String itemId) async {
    dynamic body = {};
    Map<String, dynamic> getParams = {
      'id': itemId,
    };
    final localApiResp = await _runApiCall(urlGenSuffix, 'get', body, getParams);
    if (localApiResp['error'] == false) {
      _loadItems();
    }
    // final response = await http.delete(
    //   Uri.parse('$apiBaseUrl/dishes/$itemId'),
    //   headers: {'Authorization': 'Bearer $jwtToken'},
    // );
    // if (response.statusCode == 200) {
    //   _loadItems();
    // }
  }

  void _showDeleteConfirmation(String itemId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this item?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteItem(itemId);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    var item = items[index];
    return ListTile(
      title: Text(item['name']),
      onTap: () => setState(() {
        selectedItem = item;
        isEditMode = true;
      }),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: _buildListItem,
    );
  }

  Widget _buildDataFormBody() {
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController(text: selectedItem['name']);
    TextEditingController caloriesValueController = TextEditingController(text: selectedItem['calories_value'].toString());
    TextEditingController caloriesUnitController = TextEditingController(text: selectedItem['calories_unit']);
    TextEditingController servingSizeController = TextEditingController(text: selectedItem['serving_size'].toString());
    TextEditingController servingSizeUnitController = TextEditingController(text: selectedItem['serving_size_unit']);
    TextEditingController brandNameController = TextEditingController(text: selectedItem['brand_name']);
    TextEditingController observationsController = TextEditingController(text: selectedItem['observations']);

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: <Widget>[
          TextFormField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Dish Name'),
            validator: (value) {
              if (value != null && value.isEmpty) return 'Please enter a dish name';
              return null;
            },
            onSaved: (value) => selectedItem['name'] = value,
          ),
          TextFormField(
            controller: caloriesValueController,
            decoration: const InputDecoration(labelText: 'Calories Value'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isEmpty) return 'Please enter the calories value';
              return null;
            },
            onSaved: (value) => selectedItem['calories_value'] = double.parse(value!),
          ),
          TextFormField(
            controller: caloriesUnitController,
            decoration: const InputDecoration(labelText: 'Calories Unit'),
            validator: (value) {
              if (value != null && value.isEmpty) return 'Please enter the calories unit';
              return null;
            },
            onSaved: (value) => selectedItem['calories_unit'] = value,
          ),
          TextFormField(
            controller: servingSizeController,
            decoration: const InputDecoration(labelText: 'Serving Size'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isEmpty) return 'Please enter the serving size';
              return null;
            },
            onSaved: (value) => selectedItem['serving_size'] = double.parse(value!),
          ),
          TextFormField(
            controller: servingSizeUnitController,
            decoration: const InputDecoration(labelText: 'Serving Size Unit'),
            validator: (value) {
              if (value != null && value.isEmpty) return 'Please enter the serving size unit';
              return null;
            },
            onSaved: (value) => selectedItem['serving_size_unit'] = value,
          ),
          TextFormField(
            controller: brandNameController,
            decoration: const InputDecoration(labelText: 'Brand Name'),
            onSaved: (value) => selectedItem['brand_name'] = value,
          ),
          TextFormField(
            controller: observationsController,
            decoration: const InputDecoration(labelText: 'Observations'),
            maxLines: 3,
            onSaved: (value) => selectedItem['observations'] = value,
          ),
          // Additional form fields for ingredients can be added here
          ElevatedButton(
            child: const Text('Save'),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                _saveItem(selectedItem);
              }
            },
          ),
          ElevatedButton(
            child: const Text('Cancel'),
            onPressed: () {
              setState(() {
                isEditMode = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDataForm() {
    return Scaffold(
        appBar: AppBar(
          title: Text(selectedItem['name']),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (String result) {
                if (result == 'delete') {
                  _showDeleteConfirmation(selectedItem['_id']);
                } else if (result == 'save') {
                  _saveItem(selectedItem);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Text('Delete'),
                ),
                const PopupMenuItem<String>(
                  value: 'save',
                  child: Text('Save'),
                ),
              ],
            ),
          ],
        ),
        body: _buildDataFormBody(), // Form fields here,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dishes CRUD Editor'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isEditMode ? _buildDataForm() : _buildList(),
      floatingActionButton: isEditMode
          ? null
          : FloatingActionButton(
        onPressed: () => setState(() {
          selectedItem = {
            'name': '',
            'calories_value': 0,
            'calories_unit': '',
            'serving_size': 0,
            'serving_size_unit': '',
            'brand_name': '',
            'observations': '',
          };
          isEditMode = true;
          isCreation = true;
        }),
        child: const Icon(Icons.add),
      ),
    );
  }
}
