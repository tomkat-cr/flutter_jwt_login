import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:developer';

import 'package:jwt_test/services/http_service.dart';
import 'package:jwt_test/services/message_services.dart';
import 'package:jwt_test/services/redirect_services.dart';

class LoginPage extends StatelessWidget {

  final FlutterSecureStorage storage;

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  LoginPage(this.storage, {Key? key}) : super(key: key);

  void displayDialog(context, title, text) => showDialog(
    context: context,
    builder: (context) =>
        AlertDialog(
            title: Text(title),
            content: Text(text)
        ),
  );

  Future<Map<String, dynamic>> attemptLogIn(String username, String password) async {
    return loadConfig(storage).then((configStr) {
      var config = json.decode(configStr);
      // String jwtToken = '';
      // jwtToken = config["jwtToken"];
      Map<String, dynamic> configItems = {};
      configItems = config["configItems"];
      log('LoginPage | attemptLogIn | $configItems');
      String apiUrlUsersLogin = configItems['API_URL'] + "/users/login";
      Map<String, dynamic> headers = {
        'Authorization': "Basic ${bToA("$username:$password")}"
      };
      HttpUtilities api = HttpUtilities(storage);
      return api.httpsCall("post", apiUrlUsersLogin, headers, {}, {});
    });
  }

  Future<Map<String, dynamic>> attemptSignUp(String username, String password) async {
    return loadConfig(storage).then((configStr) {
      var config = json.decode(configStr);
      // String jwtToken = '';
      // jwtToken = config["jwtToken"];
      Map<String, dynamic> configItems = {};
      configItems = config["configItems"];
      String apiUrlUsersSignIn = configItems['API_URL'] + "/users";
      HttpUtilities api = HttpUtilities(storage);
      var body = {
        "username": username,
        "password": password
      };
      return api.httpsCall("post", apiUrlUsersSignIn, {}, body, {});
    });
  }

  @override
  Widget build(BuildContext context) {
    const title = "Log In";
    return Scaffold(
      appBar: AppBar(title: const Text(title),),
      body: ListView(
        padding: const EdgeInsets.only(
          top: 10.0,
          left: 20.00,
          right: 20.00,
        ),
        children: <Widget>[
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
                labelText: 'Username'
            ),
          ),
          TextFormField(
            controller: _passwordController,
            obscureText: true,
            decoration: const InputDecoration(
                labelText: 'Password'
            ),
          ),
          const SizedBox(height: 24.0),
          Center(
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    ElevatedButton(
                      child: const Text("Log In"),
                      onPressed: () async {
                        String username = _usernameController.text;
                        String password = _passwordController.text;

                        Map<
                            String,
                            dynamic> apiResponse = await attemptLogIn(
                            username, password);

                        log('CR apiResponse');
                        log(apiResponse.toString());

                        String jwt, errorMessage;
                        if (apiResponse['error']) {
                          jwt = '';
                          errorMessage = apiResponse['error_message'];
                        } else {
                          jwt = apiResponse['resultset']['token'];
                          errorMessage = '';
                        }
                        if (jwt.isNotEmpty) {
                          storage.write(key: "jwt", value: jwt);
                          apiResponse['resultset'].remove("token");
                          storage.write(key: "user_data", value: apiResponse['resultset'].toString());
                          redirectMainScreen(storage, context);
                        } else {
                          var message = "No account was found matching that username and password. [E-060]. \n$errorMessage";
                          // displayDialog(context, "An Error Occurred", message);

                          // ErrorReporter(
                          //   message: message
                          // );
                          showScaffoldMessage(message, context);
                        }
                      },
                    ),
                    const Text("    "),
                    ElevatedButton(
                      child: const Text("Sign Up"),
                      onPressed: () async {
                        var username = _usernameController.text;
                        var password = _passwordController.text;

                        if (username.length < 4) {
                          displayDialog(context, "Invalid Username",
                              "The username should be at least 4 characters long [E-050]");
                        } else if (password.length < 4) {
                          displayDialog(context, "Invalid Password",
                              "The password should be at least 4 characters long [E-040]");
                        } else {
                          // var res = await attemptSignUp(username, password);
                          // if(res == 201) {
                          // } else if(res == 409) {
                          //   displayDialog(
                          //       context, "That username is already registered",
                          //       "Please try to sign up using another username or log in if you already have an account. [E-030]");
                          // } else {
                          //   displayDialog(context, "Error", "An unknown error occurred. [E-020]");
                          // }
                          Map<String,
                              dynamic> apiResponse = await attemptSignUp(
                              username, password);
                          if (apiResponse['error'] == false) {
                            displayDialog(context, "Success",
                                "The user was created. Log in now. [M-010]");
                          } else {
                            displayDialog(context, "Error",
                                apiResponse['error_message']);
                          }
                        }
                      },
                    ),
                  ]
              )
          )
        ],
      ),
    );
  }
}
