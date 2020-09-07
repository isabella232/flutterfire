// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_functions_platform_interface/src/method_channel/method_channel_firebase_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_common.dart';

void main() {
  initializeMethodChannel();

  group('$FirebaseFunctions', () {
    final List<MethodCall> log = <MethodCall>[];

    setUp(() async {
      await Firebase.initializeApp();
      await Firebase.initializeApp(
        name: '1337',
        options: Firebase.app().options,
      );

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

    test('call', () async {
      await FirebaseFunctions.instance
          .getHttpsCallable(functionName: 'baz')
          .call();
      final HttpsCallable callable =
          FirebaseFunctions(app: Firebase.app('1337'), region: 'space')
              .getHttpsCallable(functionName: 'qux')
                ..timeout = const Duration(days: 300);
      await callable.call(<String, dynamic>{
        'quux': 'quuz',
      });
      FirebaseFunctions.instance
          .useFunctionsEmulator(origin: 'http://localhost:5001');
      await FirebaseFunctions.instance
          .getHttpsCallable(functionName: 'bez')
          .call();
      expect(
        log,
        <Matcher>[
          isMethodCall(
            'FirebaseFunctions#call',
            arguments: <String, dynamic>{
              'app': '[DEFAULT]',
              'region': null,
              'origin': null,
              'functionName': 'baz',
              'timeoutMicroseconds': null,
              'parameters': null,
            },
          ),
          isMethodCall(
            'FirebaseFunctions#call',
            arguments: <String, dynamic>{
              'app': '1337',
              'region': 'space',
              'origin': null,
              'functionName': 'qux',
              'timeoutMicroseconds': (const Duration(days: 300)).inMicroseconds,
              'parameters': <String, dynamic>{'quux': 'quuz'},
            },
          ),
          isMethodCall(
            'FirebaseFunctions#call',
            arguments: <String, dynamic>{
              'app': '[DEFAULT]',
              'region': null,
              'origin': 'http://localhost:5001',
              'functionName': 'bez',
              'timeoutMicroseconds': null,
              'parameters': null,
            },
          ),
        ],
      );
    });
  });
}
