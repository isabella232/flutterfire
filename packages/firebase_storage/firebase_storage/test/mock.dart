// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

typedef Callback(MethodCall call);

final String kBucket = 'gs://fake-storage-bucket-url.com';
final String kSecondaryBucket = 'gs://fake-storage-bucket-url-2.com';

setupFirebaseStorageMocks([Callback customHandlers]) {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFirebase.channel.setMockMethodCallHandler((call) async {
    print('storage bucket ${kBucket}');
    if (call.method == 'Firebase#initializeCore') {
      print('initializeCore storage bucket ${kBucket}');
      return [
        {
          'name': defaultFirebaseAppName,
          'options': {
            'apiKey': '123',
            'appId': '123',
            'messagingSenderId': '123',
            'projectId': '123',
            'storageBucket': kBucket
          },
          'pluginConstants': {},
        }
      ];
    }

    if (call.method == 'Firebase#initializeApp') {
      print('initializeApp storage bucket ${kBucket}');
      return {
        'name': call.arguments['appName'],
        'options': call.arguments['options'],
        'pluginConstants': {},
      };
    }

    if (customHandlers != null) {
      customHandlers(call);
    }

    return null;
  });
}

class MockFirebaseStorage extends Mock
    with MockPlatformInterfaceMixin
    implements TestFirebaseStoragePlatform {
  MockFirebaseStorage() {
    TestFirebaseStoragePlatform();
  }
}

class TestFirebaseStoragePlatform extends FirebaseStoragePlatform {
  TestFirebaseStoragePlatform() : super();

  instanceFor({FirebaseApp app, Map<dynamic, dynamic> pluginConstants}) {}

  FirebaseStoragePlatform get instance {
    return this;
  }

  FirebaseStoragePlatform delegateFor({FirebaseApp app, String bucket}) {
    return this;
  }

  @override
  FirebaseStoragePlatform setInitialValues(
      {int maxOperationRetryTime,
      int maxDownloadRetryTime,
      int maxUploadRetryTime}) {
    return this;
  }
}

class MockReferencePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements TestReferencePlatform {
  String path;
  FirebaseStoragePlatform storage;
  MockReferencePlatform(this.storage, this.path) {
    TestReferencePlatform(storage, path);
  }
}

class TestReferencePlatform extends ReferencePlatform {
  String path;
  FirebaseStoragePlatform storage;
  TestReferencePlatform(this.storage, this.path) : super(storage, path);
}
