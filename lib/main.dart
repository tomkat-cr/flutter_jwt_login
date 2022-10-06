import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert' show json, base64, ascii, utf8;

// CR: Only for debuggin while developing:
import 'dart:developer';

// const apiServerIp = 'http://192.168.1.167:5000';
const apiServerIp = 'http://127.0.0.1:5000/';

const apiUrlUsersLogin = "$apiServerIp/users/login";
const apiUrlUsersSignIn = "$apiServerIp/users";
const apiUrlUsersGetData = "$apiServerIp/users";

const storage = FlutterSecureStorage();

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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

              log('CR snapshot.data: '+snapshot.data.toString());

              var str = snapshot.data.toString();
              var jwt = str.split(".");

              if(jwt.length !=3) {
                return LoginPage();
              } else {
                var payload = json.decode(ascii.decode(base64.decode(base64.normalize(jwt[1]))));
                if(DateTime.fromMillisecondsSinceEpoch(payload["exp"]*1000).isAfter(DateTime.now())) {
                  return HomePage(str, payload);
                } else {
                  return LoginPage();
                }
              }
            } else {
              return LoginPage();
            }
          }
      ),
    );
  }
}

class LoginPage extends StatelessWidget {

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void displayDialog(context, title, text) => showDialog(
    context: context,
    builder: (context) =>
        AlertDialog(
            title: Text(title),
            content: Text(text)
        ),
  );

  String bToA(str) {
    final bytes = utf8.encode(str);
    final base64Str = base64.encode(bytes);
    return base64Str;
  }

  Future<String> attemptLogIn(String username, String password) async {
    var res = await http.post(
        // Uri.parse("$apiServerIp/login"),
        Uri.parse(apiUrlUsersLogin),
        // body: {
        //   "username": username,
        //   "password": password
        // }
        headers: {"Authorization": "Basic " + bToA(username + ":" + password)}
    );
    log('CR res.statusCode: '+res.statusCode.toString());
    log('CR res.body: '+res.body);
    if(res.statusCode == 200) {
      return res.body.toString();
    }
    // return null;
    return '{"error": true, "error_message": "' + res.body + '", "status_code": "' + res.statusCode.toString() + '"}';
  }

  Future<int> attemptSignUp(String username, String password) async {
    var res = await http.post(
        // Uri.parse('$apiServerIp/signup'),
        Uri.parse(apiUrlUsersSignIn),
        body: {
          "username": username,
          "password": password
        }
    );
    return res.statusCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text("Log In"),),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: <Widget>[
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                    labelText: 'Username'
                ),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                    labelText: 'Password'
                ),
              ),
              FlatButton(
                  onPressed: () async {
                    var username = _usernameController.text;
                    var password = _passwordController.text;
                    // var jwt = await attemptLogIn(username, password);
                    var apiRawResponse = await attemptLogIn(username, password);
                    var apiResponse = json.decode(apiRawResponse);

                    log('CR apiRawResponse');
                    log(apiRawResponse.toString());
                    log('CR apiResponse');
                    log(apiResponse.toString());

                    var jwt = (apiResponse == null || apiResponse['error'] ? null : apiResponse['resultset']['token']);
                    var error_message = (apiResponse == null ?  apiRawResponse.toString() : (apiResponse['error'] ? apiResponse['error_message'] : ''));

                    if(jwt != null) {
                      storage.write(key: "jwt", value: jwt);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => HomePage.fromBase64(jwt)
                          )
                      );
                    } else {
                      displayDialog(context, "An Error Occurred", "No account was found matching that username and password. [E-060]. " + "\n" + error_message);
                    }
                  },
                  child: Text("Log In")
              ),
              FlatButton(
                  onPressed: () async {
                    var username = _usernameController.text;
                    var password = _passwordController.text;

                    if(username.length < 4) {
                      displayDialog(context, "Invalid Username", "The username should be at least 4 characters long [E-050]");
                    } else if(password.length < 4) {
                      displayDialog(context, "Invalid Password",
                          "The password should be at least 4 characters long [E-040]");
                    } else {
                      var res = await attemptSignUp(username, password);
                      if(res == 201) {
                        displayDialog(context, "Success",
                            "The user was created. Log in now. [M-010]");
                      } else if(res == 409) {
                        displayDialog(
                            context, "That username is already registered",
                            "Please try to sign up using another username or log in if you already have an account. [E-030]");
                      } else {
                        displayDialog(context, "Error", "An unknown error occurred. [E-020]");
                      }
                    }
                  },
                  child: Text("Sign Up")
              )
            ],
          ),
        )
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage(this.jwt, this.payload);

  factory HomePage.fromBase64(String jwt) =>
      HomePage(
          jwt,
          json.decode(
              ascii.decode(
                  base64.decode(base64.normalize(jwt.split(".")[1]))
              )
          )
      );

  final String jwt;
  final Map<String, dynamic> payload;

  String getApiDataResponse(snapshotData) {
    var apiResponse = json.decode(snapshotData.toString());
    if(apiResponse['error']) {
      return apiResponse['error_message'];
    }
    return apiResponse['resultset'];
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
        appBar: AppBar(title: const Text("Secret Data Screen")),
        body: Center(
          child: FutureBuilder(
              // future: http.read(Uri.parse('$apiServerIp/data'), headers: {"Authorization": jwt}),
              future: http.read(
                  Uri.parse(apiUrlUsersGetData),
                  // headers: {"Authorization": jwt}
                  headers: {"x-access-tokens": jwt}
              ),
              builder: (context, snapshot) =>
                snapshot.hasData ?
                    Column(children: <Widget>[
                      Text("${payload['username']}, here's the data:"),
                      Text(getApiDataResponse(snapshot.data).toString(), style: Theme.of(context).textTheme.displaySmall) // Originally: Theme.of(context).textTheme.display1
                    ],)
                :
                snapshot.hasError ? Text("An error occurred [E-010]") : CircularProgressIndicator()
          ),
        ),
      );
}