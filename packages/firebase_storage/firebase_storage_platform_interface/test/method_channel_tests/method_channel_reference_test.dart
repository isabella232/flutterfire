// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

  final List<MethodCall> log = <MethodCall>[];
  bool mockPlatformExceptionThrown = false;
  bool mockExceptionThrown = false;
  FirebaseStoragePlatform storage;
  ReferencePlatform ref;

  group('$MethodChannelReference', () {
    setUpAll(() async {
      FirebaseApp app = await Firebase.initializeApp();

      handleMethodCall((call) async {
        log.add(call);

        if (mockExceptionThrown) {
          throw Exception();
        } else if (mockPlatformExceptionThrown) {
          throw PlatformException(code: 'UNKNOWN');
        }

        switch (call.method) {
          case 'Reference#updateMetadata':
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

      log.clear();
    });
    group('Reference.updateMetadata', () {
      test('', () async {
        mockPlatformExceptionThrown = true;

        try {
          await ref.updateMetadata(SettableMetadata(contentType: 'jpeg'));
        } on FirebaseException catch (error) {
          expect(error.plugin, 'firebase_storage');
          return;
        } catch (_) {
          fail('Should have thrown an [FirebaseException] error');
        }
        fail('Should have thrown an error');
      });
    });
  });
}
