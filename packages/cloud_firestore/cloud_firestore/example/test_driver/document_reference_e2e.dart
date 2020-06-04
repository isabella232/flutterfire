// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void runDocumentReferenceTests() {
  group('$DocumentReference', () {
    Firestore firestore;

    setUpAll(() async {
      firestore = Firestore.instance;
    });

    Future<DocumentReference> initializeTest(String path) async {
      String prefixedPath = 'flutter-tests/$path';
      await firestore.document(prefixedPath).delete();
      return firestore.document(prefixedPath);
    }

    group('snapshots()', () {
      testWidgets('returns a [Stream]', (WidgetTester tester) async {
        DocumentReference document = await initializeTest('document-snapshot');
        Stream<DocumentSnapshot> stream = document.snapshots();
        expect(stream, isA<Stream<DocumentSnapshot>>());
      });

      testWidgets('listens to a single response', (WidgetTester tester) async {
        DocumentReference document = await initializeTest('document-snapshot');
        Stream<DocumentSnapshot> stream = document.snapshots();
        int call = 0;

        stream.listen(expectAsync1((DocumentSnapshot snapshot) {
          call++;
          if (call == 1) {
            expect(snapshot.exists, isFalse);
          } else {
            fail("Should not have been called");
          }
        }, count: 1, reason: "Stream should only have been called once."));
      });

      testWidgets('listens to a multiple changes response',
          (WidgetTester tester) async {
        DocumentReference document =
            await initializeTest('document-snapshot-multiple');
        Stream<DocumentSnapshot> stream = document.snapshots();
        int call = 0;

        StreamSubscription subscription = stream.listen(expectAsync1(
            (DocumentSnapshot snapshot) {
          call++;
          if (call == 1) {
            expect(snapshot.exists, isFalse);
          } else if (call == 2) {
            expect(snapshot.exists, isTrue);
            expect(snapshot.data()['bar'], equals('baz'));
          } else if (call == 3) {
            expect(snapshot.exists, isFalse);
          } else if (call == 4) {
            expect(snapshot.exists, isTrue);
            expect(snapshot.data()['foo'], equals('bar'));
          } else if (call == 5) {
            expect(snapshot.exists, isTrue);
            expect(snapshot.data()['foo'], equals('baz'));
          } else {
            fail("Should not have been called");
          }
        },
            count: 5,
            reason: "Stream should only have been called five times."));

        await Future.delayed(
            Duration(seconds: 1)); // allow stream to return a noop-doc
        await document.setData({'bar': 'baz'});
        await document.delete();
        await document.setData({'foo': 'bar'});
        await document.updateData({'foo': 'baz'});

        subscription.cancel();
      });

      testWidgets('listeners throws a [FirebaseException]',
          (WidgetTester tester) async {
        DocumentReference document = firestore.document('not-allowed/document');
        Stream<DocumentSnapshot> stream = document.snapshots();

        try {
          await stream.first;
        } catch (error) {
          expect(error, isA<FirebaseException>());
          expect(
              (error as FirebaseException).code, equals('permission-denied'));
          return;
        }

        fail("Should have thrown a [FirebaseException]");
      });
    });

    group('delete()', () {
      testWidgets('delete() deletes a document', (WidgetTester tester) async {
        DocumentReference document = await initializeTest('document-delete');
        await document.setData({
          'foo': 'bar',
        });
        DocumentSnapshot snapshot = await document.get();
        expect(snapshot.exists, isTrue);
        await document.delete();
        DocumentSnapshot snapshot2 = await document.get();
        expect(snapshot2.exists, isFalse);
      });

      testWidgets('throws a [FirebaseException] on error',
          (WidgetTester tester) async {
        DocumentReference document = firestore.document('not-allowed/document');

        try {
          await document.delete();
        } catch (error) {
          expect(error, isA<FirebaseException>());
          expect(
              (error as FirebaseException).code, equals('permission-denied'));
          return;
        }
        fail("Should have thrown a [FirebaseException]");
      });
    });

    group('get()', () {
      testWidgets('gets a document from server', (WidgetTester tester) async {
        DocumentReference document =
            await initializeTest('document-get-server');
        await document.setData({'foo': 'bar'});
        DocumentSnapshot snapshot =
            await document.get(GetOptions(source: Source.server));
        expect(snapshot.data(), {'foo': 'bar'});
        expect(snapshot.metadata.isFromCache, isFalse);
      });

      testWidgets('gets a document from cache', (WidgetTester tester) async {
        DocumentReference document = await initializeTest('document-get-cache');
        await document.setData({'foo': 'bar'});
        DocumentSnapshot snapshot =
            await document.get(GetOptions(source: Source.cache));
        expect(snapshot.data(), equals({'foo': 'bar'}));
        expect(snapshot.metadata.isFromCache, isTrue);
      });

      testWidgets('gets a document from cache', (WidgetTester tester) async {
        DocumentReference document = await initializeTest('document-get-cache');
        await document.setData({'foo': 'bar'});
        DocumentSnapshot snapshot =
            await document.get(GetOptions(source: Source.cache));
        expect(snapshot.data(), equals({'foo': 'bar'}));
        expect(snapshot.metadata.isFromCache, isTrue);
      });

      testWidgets('throws a [FirebaseException] on error',
          (WidgetTester tester) async {
        DocumentReference document = firestore.document('not-allowed/document');

        try {
          await document.get();
        } catch (error) {
          expect(error, isA<FirebaseException>());
          expect(
              (error as FirebaseException).code, equals('permission-denied'));
          return;
        }
        fail("Should have thrown a [FirebaseException]");
      });
    });

    group('setData()', () {
      testWidgets('sets data', (WidgetTester tester) async {
        DocumentReference document = await initializeTest('document-set');
        await document.setData({'foo': 'bar'});
        DocumentSnapshot snapshot = await document.get();
        expect(snapshot.data(), equals({'foo': 'bar'}));
        await document.setData({'bar': 'baz'});
        DocumentSnapshot snapshot2 = await document.get();
        expect(snapshot2.data(), equals({'bar': 'baz'}));
      });

      testWidgets('set() merges data', (WidgetTester tester) async {
        DocumentReference document = await initializeTest('document-set-merge');
        await document.setData({'foo': 'bar'});
        DocumentSnapshot snapshot = await document.get();
        expect(snapshot.data(), equals({'foo': 'bar'}));
        await document
            .setData({'foo': 'ben', 'bar': 'baz'}, SetOptions(merge: true));
        DocumentSnapshot snapshot2 = await document.get();
        expect(snapshot2.data(), equals({'foo': 'ben', 'bar': 'baz'}));
      });

      testWidgets('set() merges fields', (WidgetTester tester) async {
        DocumentReference document =
            await initializeTest('document-set-merge-fields');
        Map<String, dynamic> initialData = {
          'foo': 'bar',
          'bar': 123,
          'baz': '456',
        };
        Map<String, dynamic> dataToSet = {
          'foo': 'should-not-merge',
          'bar': 456,
          'baz': 'foo',
        };
        await document.setData(initialData);
        DocumentSnapshot snapshot = await document.get();
        expect(snapshot.data(), equals(initialData));
        await document.setData(
            dataToSet,
            SetOptions(mergeFields: [
              'bar',
              FieldPath(['baz'])
            ]));
        DocumentSnapshot snapshot2 = await document.get();
        expect(
            snapshot2.data(), equals({'foo': 'bar', 'bar': 456, 'baz': 'foo'}));
      });

      testWidgets('throws a [FirebaseException] on error',
          (WidgetTester tester) async {
        DocumentReference document = firestore.document('not-allowed/document');

        try {
          await document.setData({'foo': 'bar'});
        } catch (error) {
          expect(error, isA<FirebaseException>());
          expect(
              (error as FirebaseException).code, equals('permission-denied'));
          return;
        }
        fail("Should have thrown a [FirebaseException]");
      });

      testWidgets('set and return all possible datatypes',
          (WidgetTester tester) async {
        DocumentReference document = await initializeTest('document-types');

        await document.setData({
          'string': 'foo bar',
          'number-32': 123,
          'number-64': 1233453453453453453,
          'bool-true': true,
          'bool-false': false,
          'map': {
            'foo': 'bar',
            'bar': {'baz': 'ben'}
          },
          'list': [
            1,
            '2',
            true,
            false,
            {'foo': 'bar'}
          ],
          'null': null,
          'timestamp': Timestamp.now(),
          'geopoint': GeoPoint(1, 2),
          'reference': firestore.document('foo/bar'),
        });

        DocumentSnapshot snapshot = await document.get();
        Map<String, dynamic> data = snapshot.data();

        expect(data['string'], equals('foo bar'));
        expect(data['number-32'], equals(123));
        expect(data['number-64'], equals(1233453453453453453));
        expect(data['bool-true'], isTrue);
        expect(data['bool-false'], isFalse);
        expect(
            data['map'],
            equals(<String, dynamic>{
              'foo': 'bar',
              'bar': {'baz': 'ben'}
            }));
        expect(
            data['list'],
            equals([
              1,
              '2',
              true,
              false,
              {'foo': 'bar'}
            ]));
        expect(data['null'], equals(null));
        expect(data['timestamp'], isA<Timestamp>());
        expect(data['geopoint'], isA<GeoPoint>());
        expect((data['geopoint'] as GeoPoint).latitude, equals(1));
        expect((data['geopoint'] as GeoPoint).longitude, equals(2));
        expect(data['reference'], isA<DocumentReference>());
        expect((data['reference'] as DocumentReference).id, equals('bar'));
      });
    });

    group('updateData()', () {
      testWidgets('updates data', (WidgetTester tester) async {
        DocumentReference document = await initializeTest('document-update');
        await document.setData({'foo': 'bar'});
        DocumentSnapshot snapshot = await document.get();
        expect(snapshot.data(), equals({'foo': 'bar'}));
        await document.updateData({'bar': 'baz'});
        DocumentSnapshot snapshot2 = await document.get();
        expect(snapshot2.data(), equals({'foo': 'bar', 'bar': 'baz'}));
      });

      testWidgets('throws if document does not exist',
          (WidgetTester tester) async {
        DocumentReference document =
            await initializeTest('document-update-not-exists');
        try {
          await document.updateData({'foo': 'bar'});
          fail("Should have thrown");
        } catch (e) {
          expect(e, isA<FirebaseException>());
          expect(e.code, equals('not-found'));
        }
      });
    });
  });
}
