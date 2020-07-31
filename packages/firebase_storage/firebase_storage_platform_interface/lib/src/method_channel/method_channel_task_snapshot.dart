// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import './method_channel_reference.dart';

class MethodChannelTaskSnapshot extends TaskSnapshotPlatform {
  MethodChannelTaskSnapshot(this.storage, this.path, Map<String, dynamic> data)
      : super(data);

  final FirebaseStoragePlatform storage;

  final String path;

  @override
  ReferencePlatform get ref {
    return MethodChannelReference(storage, path);
  }
}
