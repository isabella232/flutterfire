// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import '../../firebase_storage_platform_interface.dart';
import './method_channel_reference.dart';

class MethodChannelTaskSnapshot extends TaskSnapshotPlatform {
  MethodChannelTaskSnapshot(this.storage, TaskState state, this._data)
      : super(state, _data);

  final FirebaseStoragePlatform storage;

  final Map<String, dynamic> _data;

  @override
  ReferencePlatform get ref {
    return MethodChannelReference(storage, _data['path']);
  }
}
