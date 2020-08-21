// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:cloud_functions_platform_interface/src/method_channel/method_channel_cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// The interface that implementations of `cloud_functions` must extend.
///
/// Platform implementations should extend this class rather than implement it
/// as `cloud_functions` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [CloudFunctionsPlatform] methods.
abstract class CloudFunctionsPlatform extends PlatformInterface {
  static final Object _token = Object();

  /// Constructs a CloudFunctionsPlatform.
  CloudFunctionsPlatform(this.app, this.region) : super(token: _token);

  static CloudFunctionsPlatform _instance;

  final FirebaseApp app;

  final String region;

  /// The current default [CloudFunctionsPlatform] instance.
  ///
  /// It will always default to [MethodChannelCloudFunctions]
  /// if no other implementation was provided.
  static CloudFunctionsPlatform get instance {
    if (_instance == null) {
      _instance = MethodChannelCloudFunctions.instance;
    }

    return _instance;
  }

  /// Sets the [CloudFunctionsPlatform.instance]
  static set instance(CloudFunctionsPlatform instance) {
    assert(instance != null);
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Create an instance using [app] using the existing implementation
  factory CloudFunctionsPlatform.instanceFor({FirebaseApp app, String region}) {
    return CloudFunctionsPlatform.instance
        .delegateFor(app: app, region: region);
  }

  /// Enables delegates to create new instances of themselves if a none default
  /// [FirebaseApp] instance or region is required by the user.
  @protected
  CloudFunctionsPlatform delegateFor({FirebaseApp app, String region}) {
    throw UnimplementedError('delegateFor() is not implemented');
  }

  HttpsCallablePlatform httpsCallable(
      String origin, String name, HttpsCallableOptions options) {
    throw UnimplementedError('httpsCallable() is not implemented');
  }
}
