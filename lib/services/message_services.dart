import 'package:flutter/material.dart';
import 'dart:async';

void showScaffoldMessage(String message, BuildContext context) {
  final Completer<bool> response = Completer<bool>();
  final snackBar = SnackBar(
    content: Text(message),
    action: SnackBarAction(
      label: 'Close',
      onPressed: () {
        // Use the Completer to wait for user input in a SnackBar
        response.complete(true); // User chose to close the SnackBar
      },
    ),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}