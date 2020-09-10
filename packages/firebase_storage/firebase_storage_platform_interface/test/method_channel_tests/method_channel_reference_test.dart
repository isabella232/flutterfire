// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_storage_platform_interface/src/method_channel/method_channel_firebase_storage.dart';
import 'package:firebase_storage_platform_interface/src/method_channel/method_channel_reference.dart';
import '../mock.dart';
import 'package:flutter/services.dart';

void main() {
  setupFirebaseStorageMocks();

  FirebaseStoragePlatform storage;
  ReferencePlatform ref;
  final List<MethodCall> logger = <MethodCall>[];

  // mock props
  bool mockPlatformExceptionThrown = false;
  bool mockExceptionThrown = false;
  File kFile;
  final kMetadata = SettableMetadata(
      contentLanguage: 'en',
      customMetadata: <String, String>{'activity': 'test'});
  final kListOptions = ListOptions(maxResults: 20, pageToken: null);

  group('$MethodChannelReference', () {
    setUpAll(() async {
      FirebaseApp app = await Firebase.initializeApp();
      kFile = await File('flt-ok.txt').create();

      handleMethodCall((call) async {
        logger.add(call);

        if (mockExceptionThrown) {
          throw Exception();
        } else if (mockPlatformExceptionThrown) {
          throw PlatformException(code: 'UNKNOWN');
        }

        switch (call.method) {
          case 'Reference#getDownloadURL':
            return {};
          case 'Reference#list':
            return {
              'nextPageToken': '',
              'items': ['foo', 'bar'],
              'prefixes': ['foo', 'bar'],
            };
          case 'Reference#listAll':
            return {
              'nextPageToken': '',
              'items': ['foo', 'bar'],
              'prefixes': ['foo', 'bar'],
            };
          case 'Reference#updateMetadata':
            return {};
          case 'Task#startPutFile':
            return {};
          default:
            return null;
        }
      });

      storage = MethodChannelFirebaseStorage(app: app);
      ref = MethodChannelReference(storage, '/');
    });

    setUp(() async {
      mockPlatformExceptionThrown = false;
      mockExceptionThrown = false;
      logger.clear();
    });

    group('constructor', () {
      test('should create an instance', () {
        MethodChannelReference test = MethodChannelReference(storage, '/');
        expect(test, isInstanceOf<ReferencePlatform>());
      });
    });

    group('delete', () {
      test('should invoke native method with correct args', () async {
        await ref.delete();

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Reference#delete',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'path': '/',
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;
        Function callMethod = () => ref.delete();
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('getDownloadURL', () {
      test('should invoke native method with correct args', () async {
        await ref.getDownloadURL();

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Reference#getDownloadURL',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'path': '/',
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;

        Function callMethod = () => ref.getDownloadURL();
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('getMetadata', () {
      test('should invoke native method with correct args', () async {
        await ref.getMetadata();

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Reference#getMetadata',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'path': '/',
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseStorageException] error',
          () async {
        mockPlatformExceptionThrown = true;

        Function callMethod = () => ref.getMetadata();
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('list', () {
      test('should invoke native method with correct args', () async {
        await ref.list(kListOptions);

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Reference#list',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'path': '/',
              'options': <String, dynamic>{
                'maxResults': 20,
                'pageToken': null,
              }
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseStorageException] error',
          () async {
        mockPlatformExceptionThrown = true;

        Function callMethod = () => ref.list(kListOptions);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('listAll', () {
      test('should invoke native method with correct args', () async {
        await ref.listAll();

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Reference#listAll',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'path': '/',
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseStorageException] error',
          () async {
        mockPlatformExceptionThrown = true;

        Function callMethod = () => ref.listAll();
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('put', () {
      List<int> list = utf8.encode('hello world');
      ByteBuffer buffer = Uint8List.fromList(list).buffer;

      test('should invoke native method with correct args', () async {
        await ref.put(buffer, kMetadata);

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Task#startPut',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'path': '/',
              'handle': 0,
              'data': list,
              'metadata': {
                'cacheControl': null,
                'contentDisposition': null,
                'contentEncoding': null,
                'contentLanguage': 'en',
                'contentType': null,
                'customMetadata': {'activity': 'test'}
              }
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;

        Function callMethod = () => ref.put(buffer, kMetadata);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('putBlob', () {
      List<int> list = utf8.encode('hello world');
      ByteBuffer buffer = Uint8List.fromList(list).buffer;

      test('should throw [UnimplementedError]', () async {
        expect(() => ref.putBlob(buffer, kMetadata), throwsUnimplementedError);
      });
    });

    group('putFile', () {
      test('should invoke native method with correct args', () async {
        await ref.putFile(kFile, kMetadata);

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Task#startPutFile',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'path': '/',
              'handle': 2,
              'filePath': kFile.absolute.path,
              'metadata': {
                'cacheControl': null,
                'contentDisposition': null,
                'contentEncoding': null,
                'contentLanguage': 'en',
                'contentType': null,
                'customMetadata': {'activity': 'test'}
              }
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;

        Function callMethod = () => ref.putFile(kFile, kMetadata);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('putString', () {
      test('should invoke native method with correct args', () async {
        final String data = 'foo';
        await ref.putString(data, PutStringFormat.raw, kMetadata);

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Task#startPutString',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'path': '/',
              'handle': 4,
              'data': data,
              'format': PutStringFormat.raw.toString(),
              'metadata': {
                'cacheControl': null,
                'contentDisposition': null,
                'contentEncoding': null,
                'contentLanguage': 'en',
                'contentType': null,
                'customMetadata': {'activity': 'test'}
              }
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;
        final String data = 'foo';

        Function callMethod =
            () => ref.putString(data, PutStringFormat.raw, kMetadata);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('updateMetadata', () {
      test('should update successfully', () async {
        final fullMetadata = await ref.updateMetadata(kMetadata);
        expect(fullMetadata, isInstanceOf<FullMetadata>());
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;
        Function callMethod = () => ref.updateMetadata(kMetadata);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });

    group('writeToFile', () {
      test('should invoke native method with correct args', () async {
        await ref.writeToFile(kFile);

        // check native method was called
        expect(logger, <Matcher>[
          isMethodCall(
            'Task#writeToFile',
            arguments: <String, dynamic>{
              'appName': '[DEFAULT]',
              'bucket': null,
              'path': '/',
              'handle': 6,
              'filePath': kFile.path,
            },
          ),
        ]);
      });

      test(
          'catch a [PlatformException] error and throws a [FirebaseException] error',
          () async {
        mockPlatformExceptionThrown = true;

        Function callMethod = () => ref.writeToFile(kFile);
        await testExceptionHandling('PLATFORM', callMethod);
      });
    });
  });
}
