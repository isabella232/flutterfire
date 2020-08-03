// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

abstract class TaskSnapshotPlatform extends PlatformInterface {
  TaskSnapshotPlatform(this._state, this._data) : super(token: _token);

  static final Object _token = Object();

  final TaskState _state;

  final Map<String, dynamic> _data;

  /// Throws an [AssertionError] if [instance] does not extend
  /// [TaskSnapshotPlatform].
  ///
  /// This is used by the app-facing [TaskSnapshot] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static verifyExtends(TaskSnapshotPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  int get bytesTransferred => _data['bytesTransferred'];

  FullMetadata get metadata => _data['metadata'] == null
      ? null
      : FullMetadata(Map<String, dynamic>.from(_data['metadata']));

  ReferencePlatform get ref {
    throw UnimplementedError('ref is not implemented');
  }

  TaskState get state {
    return _state;
  }

  int get totalBytes => _data['totalBytes'];
}
