// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$FirebaseOptions', () {
    test('should return true if instances are the same', () {
      const options1 = FirebaseOptions(
          apiKey: 'apiKey',
          appId: 'appId',
          messagingSenderId: 'messagingSenderId',
          projectId: 'projectId');

      const options2 = FirebaseOptions(
          apiKey: 'apiKey',
          appId: 'appId',
          messagingSenderId: 'messagingSenderId',
          projectId: 'projectId');

      expect(options1 == options2, true);
    });

    test('should return equal if instances are the different', () {
      const options1 = FirebaseOptions(
          apiKey: 'apiKey',
          appId: 'appId',
          messagingSenderId: 'messagingSenderId',
          projectId: 'projectId');

      const options2 = FirebaseOptions(
          apiKey: 'apiKey2',
          appId: 'appId2',
          messagingSenderId: 'messagingSenderId2',
          projectId: 'projectId2');

      expect(options1 == options2, false);
    });

    test('should construct an instance from a Map', () {
      FirebaseOptions options1 = FirebaseOptions.fromMap({
        'apiKey': 'apiKey',
        'appId': 'appId',
        'messagingSenderId': 'messagingSenderId',
        'projectId': 'projectId'
      });

      const options2 = FirebaseOptions(
          apiKey: 'apiKey',
          appId: 'appId',
          messagingSenderId: 'messagingSenderId',
          projectId: 'projectId');

      expect(options1 == options2, true);
    });

    test('should return a Map', () {
      const options = FirebaseOptions(
        apiKey: 'apiKey',
        appId: 'appId',
        messagingSenderId: 'messagingSenderId',
        projectId: 'projectId',
        authDomain: 'authDomain',
        databaseURL: 'databaseURL',
        storageBucket: 'storageBucket',
        measurementId: 'measurementId',
        trackingId: 'trackingId',
        deepLinkURLScheme: 'deepLinkURLScheme',
        androidClientId: 'androidClientId',
        iosBundleId: 'iosBundleId',
      );

      expect(options.asMap, {
        'apiKey': 'apiKey',
        'appId': 'appId',
        'messagingSenderId': 'messagingSenderId',
        'projectId': 'projectId',
        'authDomain': 'authDomain',
        'databaseURL': 'databaseURL',
        'storageBucket': 'storageBucket',
        'measurementId': 'measurementId',
        'trackingId': 'trackingId',
        'deepLinkURLScheme': 'deepLinkURLScheme',
        'androidClientId': 'androidClientId',
        'iosBundleId': 'iosBundleId',
      });
    });
  });
}
