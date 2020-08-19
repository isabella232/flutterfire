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
    HttpsCallable callable = CloudFunctions.instanceFor(region: 'us-central1')
        // .useFunctionsEmulator(origin: 'http://api.rnfirebase.io')
        .httpsCallable('testFunctionDefaultRegion',
            HttpsCallableOptions(timeout: Duration(seconds: 10)));

    callable(true).then(print).catchError(print);

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
