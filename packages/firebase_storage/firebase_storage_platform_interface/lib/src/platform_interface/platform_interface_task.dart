// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import '../../firebase_storage_platform_interface.dart';

abstract class TaskPlatform extends PlatformInterface {
  TaskPlatform() : super(token: _token);

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [TaskPlatform].
  ///
  /// This is used by the app-facing [Task] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static verifyExtends(TaskPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  Stream<TaskSnapshotPlatform> get snapshotEvents {
    throw UnimplementedError('snapshotEvents is not implemented');
  }

  TaskSnapshotPlatform get snapshot {
    throw UnimplementedError('snapshot is not implemented');
  }

  Future<TaskSnapshotPlatform> get onComplete {
    throw UnimplementedError('onComplete is not implemented');
  }

  Future<void> pause() {
    throw UnimplementedError('pause() is not implemented');
  }

  Future<void> resume() {
    throw UnimplementedError('resume() is not implemented');
  }

  Future<void> cancel() {
    throw UnimplementedError('cancel() is not implemented');
  }
}
