// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('$MethodChannelFirebaseCore', () {
    final MethodChannelFirebaseCore channelPlatform =
        MethodChannelFirebaseCore();
    final List<MethodCall> log = <MethodCall>[];
    const FirebaseOptions testOptions = FirebaseOptions(
      apiKey: 'testAPIKey',
      bundleID: 'testBundleID',
      clientID: 'testClientID',
      trackingID: 'testTrackingID',
      gcmSenderID: 'testGCMSenderID',
      projectID: 'testProjectID',
      androidClientID: 'testAndroidClientID',
      googleAppID: 'testGoogleAppID',
      databaseURL: 'testDatabaseURL',
      deepLinkURLScheme: 'testDeepLinkURLScheme',
      storageBucket: 'testStorageBucket',
    );

    final FirebaseAppPlatform testApp =
        FirebaseAppPlatform('testApp', testOptions);

    setUp(() async {
      // TODO: No longer static, needs fixing
      MethodChannelFirebaseCore.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'FirebaseApp#appNamed':
            if (methodCall.arguments != 'testApp') return null;
            return <dynamic, dynamic>{
              'name': 'testApp',
              'options': <dynamic, dynamic>{
                'APIKey': 'testAPIKey',
                'bundleID': 'testBundleID',
                'clientID': 'testClientID',
                'trackingID': 'testTrackingID',
                'GCMSenderID': 'testGCMSenderID',
                'projectID': 'testProjectID',
                'androidClientID': 'testAndroidClientID',
                'googleAppID': 'testGoogleAppID',
                'databaseURL': 'testDatabaseURL',
                'deepLinkURLScheme': 'testDeepLinkURLScheme',
                'storageBucket': 'testStorageBucket',
              },
            };
          case 'FirebaseApp#allApps':
            return <Map<dynamic, dynamic>>[
              <dynamic, dynamic>{
                'name': 'testApp',
                'options': <dynamic, dynamic>{
                  'APIKey': 'testAPIKey',
                  'bundleID': 'testBundleID',
                  'clientID': 'testClientID',
                  'trackingID': 'testTrackingID',
                  'GCMSenderID': 'testGCMSenderID',
                  'projectID': 'testProjectID',
                  'androidClientID': 'testAndroidClientID',
                  'googleAppID': 'testGoogleAppID',
                  'databaseURL': 'testDatabaseURL',
                  'deepLinkURLScheme': 'testDeepLinkURLScheme',
                  'storageBucket': 'testStorageBucket',
                },
              },
            ];
          default:
            return null;
        }
      });
      log.clear();
    });

    test('configure', () async {
      await channelPlatform.initializeApp(
        name: 'testApp',
        options: testOptions,
      );
      await channelPlatform.initializeApp(
        name: 'newApp',
        options: testOptions,
      );
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'FirebaseApp#configure',
            arguments: <String, dynamic>{
              'name': 'testApp',
              'options': testOptions.asMap,
            },
          ),
          isMethodCall(
            'FirebaseApp#configure',
            arguments: <String, dynamic>{
              'name': 'newApp',
              'options': testOptions.asMap,
            },
          ),
        ],
      );
    });

    test('appNamed', () async {
      final FirebaseAppPlatform existingApp =
          await channelPlatform.app('testApp');
      expect(existingApp.name, equals('testApp'));
      expect(existingApp.options, equals(testOptions));
      final FirebaseAppPlatform missingApp =
          await channelPlatform.app('missingApp');
      expect(missingApp, isNull);
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'FirebaseApp#appNamed',
            arguments: 'testApp',
          ),
          isMethodCall(
            'FirebaseApp#appNamed',
            arguments: 'missingApp',
          ),
        ],
      );
    });

    test('allApps', () async {
      final List<FirebaseAppPlatform> allApps = await channelPlatform.apps;
      expect(allApps, equals(<FirebaseAppPlatform>[testApp]));
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'FirebaseApp#allApps',
            arguments: null,
          ),
        ],
      );
    });
  });
}
