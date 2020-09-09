// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quiver/core.dart';

import 'mock.dart';

import 'package:mockito/mockito.dart';

MockFirebaseStorage mockStoragePlatform = MockFirebaseStorage();

void main() {
  setupFirebaseStorageMocks();
  FirebaseApp app;
  FirebaseStorage storage;
  FirebaseStorage storageSecondary;
  FirebaseApp secondaryApp;

  print('${MockReferencePlatform(mockStoragePlatform, 'no')}');
  group('$FirebaseStorage', () {
    setUpAll(() async {
      FirebaseStoragePlatform.instance = mockStoragePlatform;

      app = await Firebase.initializeApp();

      storage = FirebaseStorage.instance;
      secondaryApp = await Firebase.initializeApp(
          name: 'foo',
          options: FirebaseOptions(
              apiKey: '123',
              appId: '123',
              messagingSenderId: '123',
              projectId: '123',
              storageBucket: kSecondaryBucket));
      storageSecondary = FirebaseStorage.instanceFor(app: secondaryApp);
      when(mockStoragePlatform.delegateFor(
              app: anyNamed("app"), bucket: anyNamed("bucket")))
          .thenReturn(mockStoragePlatform);

      when(mockStoragePlatform.setInitialValues(
              maxDownloadRetryTime: anyNamed("maxDownloadRetryTime"),
              maxOperationRetryTime: anyNamed("maxOperationRetryTime"),
              maxUploadRetryTime: anyNamed("maxUploadRetryTime")))
          .thenReturn(mockStoragePlatform);
      when(mockStoragePlatform.maxOperationRetryTime).thenReturn(0);
      when(mockStoragePlatform.maxDownloadRetryTime).thenReturn(0);
      when(mockStoragePlatform.maxUploadRetryTime).thenReturn(0);

      when(mockStoragePlatform.ref(any))
          .thenReturn(MockReferencePlatform(mockStoragePlatform, '/'));
    });

    test('instance', () async {
      expect(storage, isA<FirebaseStorage>());
      expect(storage, equals(FirebaseStorage.instance));
    });

    test('returns the correct $FirebaseApp', () {
      expect(storage.app, isA<FirebaseApp>());
    });

    group('instanceFor()', () {
      test('instance', () async {
        expect(storageSecondary.bucket,
            kSecondaryBucket.replaceFirst("gs://", ""));
        expect(storageSecondary.app.name, 'foo');
      });

      test('returns the correct $FirebaseApp', () {
        expect(storageSecondary.app, isA<FirebaseApp>());
        expect(storageSecondary.app.name, 'foo');
      });
    });

    group('get.maxOperationRetryTime', () {
      test('verify delegate method is called', () {
        expect(storage.maxOperationRetryTime, 0);

        verify(mockStoragePlatform.maxOperationRetryTime);
      });
    });

    group('get.maxUploadRetryTime', () {
      test('verify delegate method is called', () {
        expect(storage.maxUploadRetryTime, 0);
        verify(mockStoragePlatform.maxUploadRetryTime);
      });
    });

    group('get.maxDownloadRetryTime', () {
      test('verify delegate method is called', () {
        expect(storage.maxDownloadRetryTime, 0);
        verify(mockStoragePlatform.maxDownloadRetryTime);
      });
    });

    // ref
    group('.ref()', () {
      test('accepts null', () {
        final reference = storage.ref();

        expect(reference, isA<Reference>());
        verify(mockStoragePlatform.ref('/'));
      });

      test('accepts an empty string', () {
        const String testPath = '/';
        final reference = storage.ref('');

        expect(reference, isA<Reference>());
        verify(mockStoragePlatform.ref(testPath));
      });

      test('accepts a specified path', () {
        const String testPath = '/foo';
        final reference = storage.ref(testPath);

        expect(reference, isA<Reference>());
        verify(mockStoragePlatform.ref(testPath));
      });
    });

    group('.refFromURL()', () {
      test('throws AssertionError when value is null', () {
        expect(() => storage.refFromURL(null), throwsAssertionError);
      });

      test(
          "throws AssertionError when value does not start with 'gs://' or 'http'",
          () {
        expect(() => storage.refFromURL("invalid.com"), throwsAssertionError);
      });

      test("throws AssertionError when http url is not a valid storage url",
          () {
        const String url = 'https://test.com';
        expect(() => storage.refFromURL(url), throwsAssertionError);
      });

      test("verify delegate method is called for encoded http urls", () {
        const String customBucket = 'test.appspot.com';
        const String testPath = '1mbTestFile.gif';
        const String url =
            'https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2F$customBucket%2Fo%2F$testPath%3Falt%3Dmedia';

        final ref = storage.refFromURL(url);

        expect(ref, isA<Reference>());
        print('ref $ref');
        verify(mockStoragePlatform.ref(testPath));
      });

      test("verify delegate method when url starts with 'gs://'", () {
        const String testPath = 'bar/baz.png';
        const String url = 'gs://foo/$testPath';

        final ref = storage.refFromURL(url);

        expect(ref, isA<Reference>());
        verify(mockStoragePlatform.ref(testPath));
      });
    });

    group('setMaxDownloadRetryTime()', () {
      test('verify delegate method is called', () async {
        await storage.setMaxDownloadRetryTime(200);

        verify(mockStoragePlatform.setMaxDownloadRetryTime(200));
      });

      test('throws AssertionError if null', () async {
        expect(
            () => storage.setMaxDownloadRetryTime(null), throwsAssertionError);
      });
      test('throws AssertionError if 0', () async {
        expect(() => storage.setMaxDownloadRetryTime(0), throwsAssertionError);
      });
    });

    group('setMaxOperationRetryTime()', () {
      test('verify delegate method is called', () async {
        await storage.setMaxOperationRetryTime(200);
        verify(mockStoragePlatform.setMaxOperationRetryTime(200));
      });

      test('throws AssertionError if null', () async {
        expect(
            () => storage.setMaxOperationRetryTime(null), throwsAssertionError);
      });

      test('throws AssertionError if 0', () async {
        expect(() => storage.setMaxOperationRetryTime(0), throwsAssertionError);
      });
    });

    group('setMaxUploadRetryTime()', () {
      test('verify delegate method is called', () async {
        await storage.setMaxUploadRetryTime(200);
        verify(mockStoragePlatform.setMaxUploadRetryTime(200));
      });

      test('throws AssertionError if null', () async {
        expect(() => storage.setMaxUploadRetryTime(null), throwsAssertionError);
      });

      test('throws AssertionError if 0', () async {
        expect(() => storage.setMaxUploadRetryTime(0), throwsAssertionError);
      });
    });

    group('hashCode()', () {
      test('returns the correct value', () {
        expect(storage.hashCode,
            hash2(app.name, kBucket.replaceFirst("gs://", "")));
      });
    });

    group('toString()', () {
      test('returns the correct value', () {
        expect(storage.toString(),
            '$FirebaseStorage(app: ${app.name}, bucket: ${kBucket.replaceFirst("gs://", "")})');
      });
    });
  });
}
