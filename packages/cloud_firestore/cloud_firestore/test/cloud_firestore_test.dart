// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import './mock.dart';

void main() {
  setupCloudFirestoreMocks();
  Firestore firestore;
  Firestore firestoreSecondary;
  FirebaseApp secondayApp;

  group('$Firestore', () {
    setUpAll(() async {
      await Firebase.initializeApp();
      secondayApp = await Firebase.initializeApp(
          name: 'foo',
          options: FirebaseOptions(
            apiKey: '123',
            appId: '123',
            messagingSenderId: '123',
            projectId: '123',
          ));

      firestore = Firestore.instance;
      firestoreSecondary = Firestore.instanceFor(app: secondayApp);
    });

    test('equality', () {
      expect(firestore, equals(Firestore.instance));
      expect(
          firestoreSecondary, equals(Firestore.instanceFor(app: secondayApp)));
    });

    test('returns the correct $FirebaseApp', () {
      expect(firestore.app, equals(Firebase.app()));
      expect(firestoreSecondary.app, equals(Firebase.app('foo')));
    });

    group('.collection()', () {
      test('returns a $CollectionReference', () {
        expect(firestore.collection('foo'), isA<CollectionReference>());
      });

      test('does not expect a null path', () {
        expect(() => firestore.collection(null), throwsAssertionError);
      });

      test('does not expect an empty path', () {
        expect(() => firestore.collection(''), throwsAssertionError);
      });

      test('does accept an invalid path', () {
        // 'foo/bar' points to a document
        expect(() => firestore.collection('foo/bar'), throwsAssertionError);
      });
    });

    group('.collectionGroup()', () {
      test('returns a $Query', () {
        expect(firestore.collectionGroup('foo'), isA<Query>());
      });

      test('does not expect a null path', () {
        expect(() => firestore.collectionGroup(null), throwsAssertionError);
      });

      test('does not expect an empty path', () {
        expect(() => firestore.collectionGroup(''), throwsAssertionError);
      });

      test('does accept a path containing "/"', () {
        expect(() => firestore.collectionGroup('foo/bar/baz'),
            throwsAssertionError);
      });
    });

    group('.document()', () {
      test('returns a $DocumentReference', () {
        expect(firestore.doc('foo/bar'), isA<DocumentReference>());
      });

      test('does not expect a null path', () {
        expect(() => firestore.doc(null), throwsAssertionError);
      });

      test('does not expect an empty path', () {
        expect(() => firestore.doc(''), throwsAssertionError);
      });

      test('does accept an invalid path', () {
        // 'foo' points to a collection
        expect(() => firestore.doc('bar'), throwsAssertionError);
      });
    });
  });
}
