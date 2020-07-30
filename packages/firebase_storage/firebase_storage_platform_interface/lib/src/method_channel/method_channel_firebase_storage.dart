// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

/// Method Channel delegate for [FirebaseStoragePlatform].
class MethodChannelFirebaseStorage extends FirebaseStoragePlatform {
  /// The [MethodChannelFirebaseAuth] method channel.
  static const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_storage',
  );

  /// Internal stub class initializer.
  ///
  /// When the user code calls an auth method, the real instance is
  /// then initialized via the [delegateFor] method.
  MethodChannelFirebaseStorage._() : super(appInstance: null);

  MethodChannelFirebaseStorage({FirebaseApp app}) : super(appInstance: app);
}
