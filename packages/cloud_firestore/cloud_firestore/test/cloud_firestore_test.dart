// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$Firestore', () {
    MockFirebaseCore mock;

    setUp(() async {
      mock = MockFirebaseCore();
      FirebaseCorePlatform.instance = mock;

      final FirebaseAppPlatform platformApp =
      FirebaseAppPlatform(testAppName, testOptions);

      when(mock.apps).thenReturn([platformApp]);
      when(mock.app(testAppName)).thenReturn(platformApp);
      when(mock.initializeApp(name: testAppName, options: testOptions))
          .thenAnswer((_) {
        return Future.value(platformApp);
      });
    });

    test('.apps', () {
      List<FirebaseApp> apps = FirebaseCore.instance.apps;
      verify(mock.apps);
      expect(apps[0], FirebaseCore.instance.app(testAppName));
    });

    test('.app()', () {
      FirebaseApp app = FirebaseCore.instance.app(testAppName);
      verify(mock.app(testAppName));

      expect(app.name, testAppName);
      expect(app.options, testOptions);
    });

    test('.initializeApp()', () async {
      FirebaseApp initializedApp = await FirebaseCore.instance
          .initializeApp(name: testAppName, options: testOptions);
      FirebaseApp app = FirebaseCore.instance.app(testAppName);

      expect(initializedApp, app);
      verifyInOrder([
        mock.initializeApp(name: testAppName, options: testOptions),
        mock.app(testAppName),
      ]);
    });
  });
}

class MockFirestore extends Mock
    with MockPlatformInterfaceMixin
    implements FirestorePlatform {}