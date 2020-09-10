// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_storage_platform_interface/src/method_channel/method_channel_firebase_storage.dart';
import '../mock.dart';

void main() {
  setupFirebaseStorageMocks();

  FirebaseStoragePlatform storage;
  FirebaseApp app;
  FirebaseApp secondaryApp;
  final List<MethodCall> logger = <MethodCall>[];

  // mock props
  bool mockPlatformExceptionThrown = false;
  bool mockExceptionThrown = false;

  int kTime = 10;
  String kBucket = 'foo';

  group('$MethodChannelFirebaseStorage', () {
    setUpAll(() async {
      app = await Firebase.initializeApp();
      secondaryApp = await Firebase.initializeApp(
        name: 'testApp',
        options: const FirebaseOptions(
          appId: '1:1234567890:ios:42424242424242',
          apiKey: '123',
          projectId: '123',
          messagingSenderId: '1234567890',
        ),
      );

      handleMethodCall((call) async {
        logger.add(call);

        if (mockExceptionThrown) {
          throw Exception();
        } else if (mockPlatformExceptionThrown) {
          throw PlatformException(code: 'UNKNOWN');
        }

        switch (call.method) {
          default:
            return true;
        }
      });

      storage = MethodChannelFirebaseStorage(app: app);
    });

    setUp(() async {
      mockPlatformExceptionThrown = false;
      mockExceptionThrown = false;
      logger.clear();
    });

    group('constructor', () {
      test('should create an instance with no args', () {
        MethodChannelFirebaseStorage test =
            MethodChannelFirebaseStorage(app: app, bucket: kBucket);
        expect(test.app, equals(Firebase.app()));
      });

      test('create an instance with default app', () {
        MethodChannelFirebaseStorage test =
            MethodChannelFirebaseStorage(app: Firebase.app());
        expect(test.app, equals(Firebase.app()));
      });
      test('create an instance with a secondary app', () {
        MethodChannelFirebaseStorage test =
            MethodChannelFirebaseStorage(app: secondaryApp);
        expect(test.app, equals(secondaryApp));
      });

      test('allow multiple instances', () {
        MethodChannelFirebaseStorage test1 = MethodChannelFirebaseStorage();
        MethodChannelFirebaseStorage test2 =
            MethodChannelFirebaseStorage(app: secondaryApp);
        expect(test1.app, equals(Firebase.app()));
        expect(test2.app, equals(secondaryApp));
      });
    });

    test('instance', () {
      expect(MethodChannelFirebaseStorage.instance,
          isInstanceOf<MethodChannelFirebaseStorage>());
    });

    test('nextMethodChannelHandleId', () {
      final handleId = MethodChannelFirebaseStorage.nextMethodChannelHandleId;

      expect(
          MethodChannelFirebaseStorage.nextMethodChannelHandleId, handleId + 1);

      nextMockHandleId;
      nextMockHandleId;
    });

    test('taskObservers', () {
      expect(MethodChannelFirebaseStorage.taskObservers,
          isInstanceOf<Map<int, StreamController<TaskSnapshotPlatform>>>());
    });

    group('delegateFor()', () {
      test('returns a [FirebaseStoragePlatform] with arguments', () {
        final testStorage = TestMethodChannelFirebaseStorage(Firebase.app());
        final result = testStorage.delegateFor(app: Firebase.app());
        expect(result, isA<FirebaseStoragePlatform>());
        expect(result.app, isA<FirebaseApp>());
      });
    });

    group('setInitialValues', () {
      test('should set properties correctly', () {
        final result = storage.setInitialValues(
            maxDownloadRetryTime: 10,
            maxOperationRetryTime: 20,
            maxUploadRetryTime: 30);
        expect(result, isInstanceOf<FirebaseStoragePlatform>());
        expect(storage.maxDownloadRetryTime, equals(10));
        expect(storage.maxOperationRetryTime, equals(20));
        expect(storage.maxUploadRetryTime, equals(30));
      });
    });

    group('ref', () {
      test('should return a [ReferencePlatform]', () {
        final result = storage.ref('foo.bar');
        expect(result, isInstanceOf<ReferencePlatform>());
      });
    });

    group('setMaxOperationRetryTime', () {
      test('should invoke native method with correct args', () async {
        await storage.setMaxOperationRetryTime(kTime);

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Storage#setMaxOperationRetryTime',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'time': kTime,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;
        Function callMethod = () => storage.setMaxOperationRetryTime(kTime);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('setMaxUploadRetryTime', () {
      test('should invoke native method with correct args', () async {
        await storage.setMaxUploadRetryTime(kTime);

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Storage#setMaxUploadRetryTime',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'time': kTime,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;
        Function callMethod = () => storage.setMaxUploadRetryTime(kTime);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('setMaxDownloadRetryTime', () {
      test('should call native method with correct args', () async {
        await storage.setMaxDownloadRetryTime(kTime);

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Storage#setMaxDownloadRetryTime',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'time': kTime,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;
        Function callMethod = () => storage.setMaxDownloadRetryTime(kTime);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });
  });
}

class TestMethodChannelFirebaseStorage extends MethodChannelFirebaseStorage {
  TestMethodChannelFirebaseStorage(FirebaseApp app) : super(app: app);
}
