// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library cloud_functions_platform_interface;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart' show protected, required, visibleForTesting;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

part 'method_channel_cloud_functions.dart';

/// The interface that implementations of `cloud_functions` must extend.
///
/// Platform implementations should extend this class rather than implement it
/// as `cloud_functions` does not consider newly added methods to be breaking
/// changes. Extending this class (using `extends`) ensures that the subclass
/// will get the default implementation, while platform implementations that
/// `implements` this interface will be broken by newly added
/// [CloudFunctionsPlatform] methods.
abstract class CloudFunctionsPlatform extends PlatformInterface {
  @protected
  // ignore: public_member_api_docs
  final FirebaseApp appInstance;

  final String region;

  CloudFunctionsPlatform({this.appInstance, this.region})
      : super(token: _token);

  static final Object _token = Object();

  /// Returns a [CloudFunctionsPlatform] with the provided arguments.
  factory CloudFunctionsPlatform.instanceFor({FirebaseApp app, String region}) {
    return CloudFunctionsPlatform.instance
        .delegateFor(app: app, region: region);
  }

  /// Returns the [FirebaseApp] for the current instance.
  FirebaseApp get app {
    if (appInstance == null) {
      return Firebase.app();
    }

    return appInstance;
  }

  static CloudFunctionsPlatform _instance;

  /// The current default [FirebaseFirestorePlatform] instance.
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
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Enables delegates to create new instances of themselves if a none default
  /// [FirebaseApp] instance is required by the user.
  @protected
  CloudFunctionsPlatform delegateFor({FirebaseApp app, String region}) {
    throw UnimplementedError('delegateFor() is not implemented');
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
  Future<dynamic> callCloudFunction({
    @required String appName,
    @required String functionName,
    String region,
    String origin,
    Duration timeout,
    dynamic parameters,
  }) {
    throw UnimplementedError('callCloudFunction() has not been implemented');
  }
}
