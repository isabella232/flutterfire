// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import 'method_channel_https_callable.dart';

/// Method Channel delegate for [CloudFunctionsPlatform].
class MethodChannelCloudFunctions extends CloudFunctionsPlatform {
  /// Returns a stub instance to allow the platform interface to access
  /// the class instance statically.
  static MethodChannelCloudFunctions get instance {
    return MethodChannelCloudFunctions._();
  }

  /// The [MethodChannelFirebaseAuth] method channel.
  static const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/cloud_functions',
  );

  /// Internal stub class initializer.
  ///
  /// When the user code calls an storage method, the real instance is
  /// then initialized via the [delegateFor] method.
  MethodChannelCloudFunctions._() : super(null, null);

  MethodChannelCloudFunctions({FirebaseApp app, String region})
      : super(app, region);

  CloudFunctionsPlatform delegateFor({FirebaseApp app, String region}) {
    return MethodChannelCloudFunctions(app: app, region: region);
  }

  @override
  httpsCallable(String origin, String name, HttpsCallableOptions options) {
    return MethodChannelHttpsCallable(this, origin, name, options);
  }
}
