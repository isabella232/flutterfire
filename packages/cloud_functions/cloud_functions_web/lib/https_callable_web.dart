// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:cloud_functions_web/utils.dart';
import 'package:firebase/firebase.dart' as firebase;

class HttpsCallableWeb extends HttpsCallablePlatform {
  HttpsCallableWeb(CloudFunctionsPlatform functions, this._webFunctions,
      String origin, String name, HttpsCallableOptions options)
      : super(functions, origin, name, options);

  final firebase.Functions _webFunctions;

  @override
  Future<dynamic> call([parameters]) async {
    firebase.HttpsCallableOptions callableOptions =
        firebase.HttpsCallableOptions(timeout: options.timeout.inMicroseconds);

    firebase.HttpsCallable callable =
        _webFunctions.httpsCallable(name, callableOptions);

    return callable(parameters).then((result) {
      // TODO(ehesp): firebase.HttpsCallableResult types `data` as a Map (should be dynamic)
      return result.data;
      // return result.data as dynamic;
    }).catchError((e, s) {
      throw throwFirebaseAuthException(e, s);
    });
  }
}
