// Copyright 2018, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_functions/cloud_functions.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    HttpsCallable callable = CloudFunctions.instance
        // .useFunctionsEmulator(origin: 'https://api.rnfirebase.io')
        .httpsCallable('testFunctionDefaultRegion');

    callable().then((v) => print('success ${v.data}')).catchError((e) {
      print('ERROR: $e');
      // print(e.code);
      // print(e.message);
      // print(e.details);
    });

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cloud Functions example app'),
        ),
        body: Center(child: Text("Cloud Functions!")),
      ),
    );
  }
}
