// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage_platform_interface/src/method_channel/method_channel_reference.dart';
import 'package:firebase_storage_platform_interface/src/method_channel/method_channel_task.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_storage_platform_interface/src/method_channel/method_channel_firebase_storage.dart';
import '../mock.dart';

void main() {
  setupFirebaseStorageMocks();

  FirebaseStoragePlatform storage;
  MethodChannelReference ref;
  FirebaseApp app;
  final List<MethodCall> logger = <MethodCall>[];

  // mock props
  bool mockPlatformExceptionThrown = false;
  bool mockExceptionThrown = false;

  final kMockData = 'Hello World';
  MethodChannelPutStringTask kMockTask;

  group('$MethodChannelTask', () {
    setUpAll(() async {
      app = await Firebase.initializeApp();
      storage = MethodChannelFirebaseStorage(app: app);
      ref = MethodChannelReference(storage, '/');
      kMockTask = ref.putString(kMockData, PutStringFormat.raw);

      handleMethodCall((call) {
        logger.add(call);

        if (mockExceptionThrown) {
          throw Exception();
        } else if (mockPlatformExceptionThrown) {
          throw PlatformException(code: 'UNKNOWN');
        }

        switch (call.method) {
          case 'Task#startPutString':
            return null;
          case 'Task#pause':
            return {
              'status': true,
            };
          case 'Task#resume':
            return {
              'status': true,
            };
          case 'Task#cancel':
            return {
              'status': true,
            };
          default:
            return true;
        }
      });
    });

    setUp(() {
      mockPlatformExceptionThrown = false;
      mockExceptionThrown = false;
      logger.clear();
    });

    test('snapshotEvents should return a stream of snapshots', () {
      final result = kMockTask.snapshotEvents;
      expect(result, isA<Stream<TaskSnapshotPlatform>>());
    });

    test('onComplete should return snapshot', () async {
      final result = await kMockTask.onComplete;
      expect(result, isA<Future<TaskSnapshotPlatform>>());
    });

    group('pause', () {
      test('should call native method with correct args', () async {
        final result = await kMockTask.pause();
        expect(result, isA<bool>());
        expect(result, isTrue);
        expect(logger, <Matcher>[
          isMethodCall(
            'Task#pause',
            arguments: <String, dynamic>{
              'handle': 0,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        Function callMethod = () => kMockTask.pause();
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('resume', () {
      test('should call native method with correct args', () async {
        final result = await kMockTask.resume();
        expect(result, isA<bool>());
        expect(result, isTrue);
        expect(logger, <Matcher>[
          isMethodCall(
            'Task#resume',
            arguments: <String, dynamic>{
              'handle': 0,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;
        Function callMethod = () => kMockTask.resume();
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('cancel', () {
      test('should call native method with correct args', () async {
        final result = await kMockTask.cancel();
        expect(result, isA<bool>());
        expect(result, isTrue);
        expect(logger, <Matcher>[
          isMethodCall(
            'Task#cancel',
            arguments: <String, dynamic>{
              'handle': 0,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;
        Function callMethod = () => kMockTask.cancel();
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });
  });
}
