// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import '../method_channel/method_channel_firebase_storage.dart';

/// The Firebase Storage platform interface.
///
/// This class should be extended by any classes implementing the plugin on
/// other Flutter supported platforms.
abstract class FirebaseStoragePlatform extends PlatformInterface {
  @protected
  final FirebaseApp appInstance;

  /// Create an instance using [app]
  FirebaseStoragePlatform({this.appInstance}) : super(token: _token);

  static final Object _token = Object();

  /// Returns the [FirebaseApp] for the current instance.
  FirebaseApp get app {
    if (appInstance == null) {
      return Firebase.app();
    }

    return appInstance;
  }

  static FirebaseStoragePlatform _instance;

  /// The current default [FirebaseFirestorePlatform] instance.
  ///
  /// It will always default to [MethodChannelFirebaseFirestore]
  /// if no other implementation was provided.
  static FirebaseStoragePlatform get instance {
    if (_instance == null) {
      _instance = MethodChannelFirebaseStorage(app: Firebase.app());
    }
    return _instance;
  }

  /// Sets the [FirebaseStoragePlatform.instance]
  static set instance(FirebaseStoragePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Enables delegates to create new instances of themselves if a none default
  /// [FirebaseApp] instance is required by the user.
  @protected
  FirebaseStoragePlatform delegateFor({FirebaseApp app}) {
    throw UnimplementedError('delegateFor() is not implemented');
  }
}
