// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_functions/cloud_functions.dart';
import 'package:drive/drive.dart' as drive;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'sample.dart' as data;

String kDefaultCallable = 'testFunctionDefaultRegion';
String kCallableRegion = 'testFunctionCustomRegion';
String kOriginCallable = 'FlutterFireFunctionsEmulator';

void testsMain() {
  setUpAll(() async {
    await Firebase.initializeApp();
  });

  group('httpsCallable', () {
    HttpsCallable callable;

    setUpAll(() async {
      callable = FirebaseFunctions.instance.httpsCallable(kDefaultCallable);
    });

    test('returns a [HttpsCallableResult]', () async {
      var result = await callable();
      expect(result, isA<HttpsCallableResult>());
    });

    test('accepts no arguments', () async {
      HttpsCallableResult result = await callable();
      expect(result.data, equals('null'));
    });

    test('accepts `null arguments', () async {
      HttpsCallableResult result = await callable(null);
      expect(result.data, equals('null'));
    });

    test('accepts string primitive', () async {
      HttpsCallableResult result = await callable('foo');
      expect(result.data, equals('string'));
    });

    test('accepts number primitive', () async {
      HttpsCallableResult result = await callable(123);
      expect(result.data, equals('number'));
      HttpsCallableResult result2 = await callable(12.3);
      expect(result2.data, equals('number'));
    });

    test('accepts boolean primitive', () async {
      HttpsCallableResult result = await callable(true);
      expect(result.data, equals('boolean'));
      HttpsCallableResult result2 = await callable(false);
      expect(result2.data, equals('boolean'));
    });

    test('accepts a [List]', () async {
      HttpsCallableResult result = await callable(data.list);
      expect(result.data, equals('array'));
    });

    test('accepts a deep [Map]', () async {
      HttpsCallableResult result = await callable({
        'type': 'deepMap',
        'inputData': data.deepMap,
      });
      expect(result.data, equals(data.deepMap));
    });

    test('accepts a deep [List]', () async {
      HttpsCallableResult result = await callable({
        'type': 'deepList',
        'inputData': data.deepList,
      });
      expect(result.data, equals(data.deepList));
    });
  });

  group('CloudFunctionsException', () {
    HttpsCallable callable;

    setUpAll(() async {
      callable = FirebaseFunctions.instance.httpsCallable(kDefaultCallable);
    });

    test('it returns a correct instance', () async {
      try {
        await callable({});
        fail('Should have thrown');
      } on FirebaseFunctionsException catch (e) {
        expect(e.code, equals('invalid-argument'));
        expect(e.message, equals('Invalid test requested.'));
        return;
      } catch (e) {
        fail(e);
      }
    });

    test('it returns details of complex data', () async {
      try {
        await callable({
          'type': 'deepMap',
          'inputData': data.deepMap,
          'asError': true,
        });
        fail('Should have thrown');
      } on FirebaseFunctionsException catch (e) {
        expect(e.code, equals('cancelled'));
        expect(
            e.message,
            equals(
                'Response data was requested to be sent as part of an Error payload, so here we are!'));

        // TODO(ehesp): firebase-dart does not provide `details` from HTTP errors.
        if (!kIsWeb) {
          expect(e.details, equals(data.deepMap));
        }
      } catch (e) {
        fail(e);
      }
    });
  });

  group('region', () {
    HttpsCallable callable;

    setUpAll(() async {
      callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable(kCallableRegion);
    });

    test('uses a non-default region', () async {
      HttpsCallableResult result = await callable();
      expect(result.data, equals('europe-west1'));
    });
  });

  group('HttpsCallableOptions', () {
    HttpsCallable callable;

    setUpAll(() async {
      callable = FirebaseFunctions.instanceFor(region: 'europe-west2')
          .useFunctionsEmulator(origin: 'https://api.rnfirebase.io')
          .httpsCallable(kOriginCallable,
              options: HttpsCallableOptions(timeout: Duration(seconds: 5)));
    });

    test('times out when the provided timeout is exceeded', () async {
      try {
        await callable({
          'testTimeout': '10000',
        });
        fail('Should have thrown');
      } on FirebaseFunctionsException catch (e) {
        expect(e.code, equals('deadline-exceeded'));
      } catch (e) {
        fail(e);
      }
    });
  });

  group('useFunctionsEmulator', () {
    HttpsCallable callable;

    setUpAll(() async {
      callable = FirebaseFunctions.instanceFor(region: 'europe-west2')
          .useFunctionsEmulator(origin: 'https://api.rnfirebase.io')
          .httpsCallable(kOriginCallable);
    });

    test('uses a provided emulator origin', () async {
      HttpsCallableResult result = await callable();
      expect(result.data, isNotNull);
      expect(result.data['region'], equals('europe-west2'));
      expect(result.data['fnName'], equals(kOriginCallable));
    });
  });
}

void main() => drive.main(testsMain);
