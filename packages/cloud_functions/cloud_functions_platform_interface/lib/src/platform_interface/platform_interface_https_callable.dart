// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class HttpsCallablePlatform extends PlatformInterface {
  HttpsCallablePlatform(this.functions, this.origin, this.name, this.options)
      : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [HttpsCallablePlatform].
  ///
  /// This is used by the app-facing [HttpsCallable] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static verifyExtends(HttpsCallablePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  final FirebaseFunctionsPlatform functions;

  final String origin;

  final String name;

  HttpsCallableOptions options;

  Future<dynamic> call([dynamic parameters]) {
    throw UnimplementedError('call() is not implemented');
  }

  Duration get timeout {
    return options.timeout;
  }

  set timeout(Duration duration) {
    options = HttpsCallableOptions(timeout: duration);
  }
}
