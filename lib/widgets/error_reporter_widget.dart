// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:jwt_test/widgets/back_button.dart';

const showScaffold = true;

class ErrorReporter extends StatelessWidget {
  final String message;

  const ErrorReporter({Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
      var errorMessage = "Error: $message";
      if (showScaffold) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage))
        );
        return const Text('');
      } else {
        return
          Column(
            children: <Widget>[
              const ButtonBack(),
              Text(errorMessage),
            ],
        );
      }
  }
}
