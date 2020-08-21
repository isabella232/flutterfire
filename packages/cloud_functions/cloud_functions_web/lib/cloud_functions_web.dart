// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:cloud_functions_web/https_callable_web.dart';
import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web implementation of [CloudFunctionsPlatform].
class CloudFunctionsWeb extends CloudFunctionsPlatform {
  /// Instance of functions from the web plugin
  final firebase.Functions _webFunctions;

  /// Create the default instance of the [CloudFunctionsPlatform] as a [CloudFunctionsWeb]
  static void registerWith(Registrar registrar) {
    CloudFunctionsPlatform.instance = CloudFunctionsWeb.instance;
  }

  static CloudFunctionsWeb get instance {
    return CloudFunctionsWeb._();
  }

  /// Stub initializer to allow the [registerWith] to create an instance without
  /// registering the web delegates or listeners.
  CloudFunctionsWeb._()
      : _webFunctions = null,
        super(null, null);

  /// The entry point for the [CloudFunctionsWeb] class.
  CloudFunctionsWeb({FirebaseApp app, String region})
      : _webFunctions = firebase.app(app?.name).functions(region),
        super(app, region);

  @override
  CloudFunctionsPlatform delegateFor({FirebaseApp app, String region}) {
    return CloudFunctionsWeb(app: app, region: region);
  }

  @override
  HttpsCallablePlatform httpsCallable(
      String origin, String name, HttpsCallableOptions options) {
    return HttpsCallableWeb(this, _webFunctions, origin, name, options);
  }

  /// Invokes the specified cloud function.
  ///
  /// The required parameters, [appName] and [functionName], specify which
  /// cloud function will be called.
  ///
  /// The rest of the parameters are optional and used to invoke the function
  /// with something other than the defaults. [region] defaults to `us-central1`
  /// and [timeout] defaults to 60 seconds.
  ///
  /// The [origin] parameter may be used to provide the base URL for the function.
  /// This can be used to send requests to a local emulator.
  ///
  /// The data passed into the cloud function via [parameters] can be any of the following types:
  ///
  /// `null`
  /// `String`
  /// `num`
  /// [List], where the contained objects are also one of these types.
  /// [Map], where the values are also one of these types.
  @override
  Future<dynamic> callCloudFunction({
    @required String appName,
    @required String functionName,
    String region,
    String origin,
    Duration timeout,
    dynamic parameters,
  }) {
    firebase.App app = firebase.app(appName);
    firebase.Functions functions = app.functions(region);
    if (origin != null) {
      functions.useFunctionsEmulator(origin);
    }
    firebase.HttpsCallable hc;
    if (timeout != null) {
      hc = functions.httpsCallable(functionName,
          firebase.HttpsCallableOptions(timeout: timeout.inMicroseconds));
    } else {
      hc = functions.httpsCallable(functionName);
    }
    return hc.call(parameters).then((result) {
      return result.data;
    });
  }
}
