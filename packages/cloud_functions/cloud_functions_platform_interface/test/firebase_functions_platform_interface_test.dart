// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:cloud_functions_platform_interface/src/method_channel/method_channel_firebase_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$FirebaseFunctionsPlatform()', () {
    test('$MethodChannelFirebaseFunctions is the default instance', () {
      expect(FirebaseFunctionsPlatform.instance,
          isA<MethodChannelFirebaseFunctions>());
    });

    test('Cannot be implemented with `implements`', () {
      expect(() {
        FirebaseFunctionsPlatform.instance = ImplementsCloudFunctionsPlatform();
      }, throwsAssertionError);
    });

    test('Can be extended', () {
      FirebaseFunctionsPlatform.instance =
          ExtendsCloudFunctionsPlatform(null, null);
    });

    test('Can be mocked with `implements`', () {
      final FirebaseFunctionsPlatform mock = MocksCloudFunctionsPlatform();
      FirebaseFunctionsPlatform.instance = mock;
    });
  });
}

class ImplementsCloudFunctionsPlatform extends Mock
    implements FirebaseFunctionsPlatform {}

class MocksCloudFunctionsPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseFunctionsPlatform {}

class ExtendsCloudFunctionsPlatform extends FirebaseFunctionsPlatform {
  ExtendsCloudFunctionsPlatform(FirebaseApp app, String region)
      : super(app, region);
}
