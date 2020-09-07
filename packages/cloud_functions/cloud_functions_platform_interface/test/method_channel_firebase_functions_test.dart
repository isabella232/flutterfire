// Copyright 2018-2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:cloud_functions_platform_interface/src/method_channel/method_channel_firebase_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_common.dart';

void main() {
  initializeMethodChannel();
  group('$FirebaseFunctionsPlatform', () {
    final List<MethodCall> log = <MethodCall>[];
    FirebaseApp app;
    setUp(() async {
      app = await Firebase.initializeApp();
      MethodChannelFirebaseFunctions.channel
          .setMockMethodCallHandler((MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'FirebaseFunctions#call':
            return <String, dynamic>{
              'foo': 'bar',
            };
          default:
            return true;
        }
      });
      log.clear();
    });
// TODO refactor as `callCloudFunction` no longer exists on PI, use httpsCallable instead
//    test('call', () async {
//      final String appName = app.name;
//      await FirebaseFunctionsPlatform.instance
//          .callCloudFunction(appName: appName, functionName: 'baz');
//
//      Map<String, String> params = {'quux': 'quuz'};
//      await FirebaseFunctionsPlatform.instance.callCloudFunction(
//        appName: '1337',
//        functionName: 'qux',
//        region: 'space',
//        timeout: Duration(days: 300),
//        parameters: params,
//      );
//
//      await FirebaseFunctionsPlatform.instance.callCloudFunction(
//        appName: appName,
//        functionName: 'bez',
//        origin: 'http://localhost:5001',
//      );
//
//      expect(
//        log,
//        <Matcher>[
//          isMethodCall(
//            'CloudFunctions#call',
//            arguments: <String, dynamic>{
//              'app': '[DEFAULT]',
//              'region': null,
//              'origin': null,
//              'functionName': 'baz',
//              'timeoutMicroseconds': null,
//              'parameters': null,
//            },
//          ),
//          isMethodCall(
//            'CloudFunctions#call',
//            arguments: <String, dynamic>{
//              'app': '1337',
//              'region': 'space',
//              'origin': null,
//              'functionName': 'qux',
//              'timeoutMicroseconds': (const Duration(days: 300)).inMicroseconds,
//              'parameters': <String, dynamic>{'quux': 'quuz'},
//            },
//          ),
//          isMethodCall(
//            'CloudFunctions#call',
//            arguments: <String, dynamic>{
//              'app': '[DEFAULT]',
//              'region': null,
//              'origin': 'http://localhost:5001',
//              'functionName': 'bez',
//              'timeoutMicroseconds': null,
//              'parameters': null,
//            },
//          ),
//        ],
//      );
//    });
  });
}
