import 'dart:developer';

import 'package:flutter/material.dart';

import 'package:jwt_test/views/homepage_screen.dart';
import 'package:jwt_test/views/dishes_screen.dart';

const redirectToCrud = true;

void redirectMainScreen(storage, context) {
  if (redirectToCrud) {
    log('>>>> Va para el CRUD...');
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => CrudEditor(storage)
        )
    );
  } else {
    log('>>>> Va para el Homee...');
    Navigator.push(
        context,
        MaterialPageRoute(
          // builder: (context) => HomePage.fromBase64(configItems, jwt)
            builder: (context) => HomePage(storage)
        )
    );
  }
}