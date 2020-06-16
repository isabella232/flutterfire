// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_firestore.dart';
import 'package:cloud_firestore_platform_interface/src/method_channel/method_channel_query.dart';

import '../utils/test_common.dart';

void main() {
  initializeMethodChannel();
  MethodChannelQuery query;
  final List<MethodCall> log = <MethodCall>[];

  const Map<String, dynamic> kMockSnapshotMetadata = <String, dynamic>{
    "hasPendingWrites": false,
    "isFromCache": false,
  };
  const Map<String, dynamic> kMockSnapshotData = <String, dynamic>{
    "1": 2,
  };
  const Map<String, dynamic> kMockDocumentSnapshotDocument = <String, dynamic>{
    'path': 'foo/bar',
    'data': [kMockSnapshotData],
    'metadata': [kMockSnapshotMetadata]
  };

  group("$MethodChannelQuery", () {
    setUpAll(() async {
      await FirebaseCore.instance.initializeApp(
        name: 'testApp',
        options: const FirebaseOptions(
          appId: '1:1234567890:ios:42424242424242',
          apiKey: '123',
          projectId: '123',
          messagingSenderId: '1234567890',
        ),
      );

      query = MethodChannelQuery(
          FirestorePlatform.instance, '$kCollectionId/$kDocumentId',
          parameters: {
            'where': [],
            'orderBy': ['foo'],
            'startAt': null,
            'startAfter': null,
            'endAt': ['0'],
            'endBefore': null,
            'limit': null,
            'limitToLast': null
          },
          isCollectionGroupQuery: false);
    });

    test("endAtDocument()", () {
      List<List<dynamic>> orders = List.from([
        ['bar']
      ]);
      List<dynamic> values = [1];
      MethodChannelQuery q = query.endAtDocument(orders, values);

      expect(q, isNot(same(query)));
      expect(q.parameters['endAt'], equals([1]));
      expect(
          q.parameters['orderBy'],
          equals([
            ['bar']
          ]));
      expect(q.parameters['endBefore'], equals(null));
    });

    test("endAt()", () {
      List<List<dynamic>> fields = List.from([
        ['bar']
      ]);
      MethodChannelQuery q = query.endAt(
        fields,
      );

      expect(q, isNot(same(query)));
      expect(
          q.parameters['endAt'],
          equals([
            ['bar']
          ]));
      expect(q.parameters['endBefore'], equals(null));
    });

    test("endBeforeDocument()", () {
      List<List<dynamic>> orders = List.from([
        ['bar']
      ]); // orderby
      List<dynamic> values = [1]; // where
      MethodChannelQuery q = query.endBeforeDocument(orders, values);

      expect(q, isNot(same(query)));
      expect(q.parameters['endAt'], equals(null));
      expect(
          q.parameters['orderBy'],
          equals([
            ['bar']
          ]));
      expect(q.parameters['endBefore'], equals([1]));
    });

    test("endBefore()", () {
      List<dynamic> fields = List.from(['bar']);
      MethodChannelQuery q = query.endBefore(fields);

      expect(q, isNot(same(query)));
      expect(q.parameters['endAt'], equals(null));
      expect(q.parameters['orderBy'], equals(['foo']));
      expect(q.parameters['endBefore'], equals(fields));
    });
    group("get()", () {
      setUp(() async {
        log.clear();
        MethodChannelFirestore.channel
            .setMockMethodCallHandler((MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'Query#getDocuments':
              if (methodCall.arguments['path'] == 'foo/unknown') {
                throw PlatformException(
                    code: 'ERROR', details: {'code': 'UNKNOWN_PATH'});
              }

              return <String, dynamic>{
                'paths': <String>["${methodCall.arguments['path']}/0"],
                'documents': <dynamic>[kMockDocumentSnapshotDocument],
                'metadatas': <Map<String, dynamic>>[kMockSnapshotMetadata],
                'metadata': kMockSnapshotMetadata,
                'documentChanges': <dynamic>[
                  <String, dynamic>{
                    'oldIndex': -1,
                    'newIndex': 0,
                    'type': 'DocumentChangeType.added',
                    'document': kMockDocumentSnapshotDocument,
                  },
                ]
              };
            default:
              return null;
          }
        });
      });
      test("returns a [QuerySnapshotPlatform]", () async {
        final GetOptions getOptions = const GetOptions(source: Source.cache);
        QuerySnapshotPlatform snapshot = await query.get(getOptions);
        expect(snapshot, isA<QuerySnapshotPlatform>());
        expect(snapshot.docs.length, 1);

        // TODO(helenaford) fix log
        // expect(
        //   log,
        //   equals(<Matcher>[
        //     isMethodCall(
        //       'Query#getDocuments',
        //       arguments: <String, dynamic>{
        //         'appName': FirestorePlatform.instance.app,
        //         'path': 'foo/bar',
        //         'source': 'cache',
        //       },
        //     ),
        //   ]),
        // );
      });

      test('listeners throws a [FirebaseException]', () async {
        Stream<QuerySnapshotPlatform> stream = query.snapshots();

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
      test("throws a [FirebaseException]", () async {
        MethodChannelQuery testQuery =
            MethodChannelQuery(FirestorePlatform.instance, 'foo/unknown',
                parameters: {
                  'where': [],
                  'orderBy': [],
                },
                isCollectionGroupQuery: false);
        final GetOptions getOptions = const GetOptions(source: Source.cache);

        try {
          await testQuery.get(getOptions);
        } on FirebaseException catch (e) {
          expect(e.code, equals('UNKNOWN_PATH'));
          return;
        }
        fail("Should have thrown a [FirebaseException]");
      });
    });

    test("limit()", () {
      MethodChannelQuery q = query.limit(1);

      expect(q, isNot(same(query)));
      expect(q.parameters['limit'], equals(1));
    });
    test("limitToLast()", () {
      MethodChannelQuery q = query.limitToLast(1);

      expect(q, isNot(same(query)));
      expect(q.parameters['limitToLast'], equals(1));
    });

    test("orderBy()", () {
      List<List<dynamic>> orders = List.from([
        ['bar']
      ]);
      MethodChannelQuery q = query.orderBy(orders);
      expect(q, isNot(same(query)));
      expect(
          q.parameters['orderBy'],
          equals([
            ['bar']
          ]));
    });

    group("snapshots()", () {
      test('sets a default value for includeMetadataChanges', () {
        try {
          query.snapshots();
        } on AssertionError catch (_) {
          fail("Default value not set for includeMetadataChanges");
        }
      });
      test('should throw if includeMetadataChanges is null', () {
        expect(() => query.snapshots(includeMetadataChanges: null),
            throwsAssertionError);
      });

      test('returns a [Stream]', () {
        Stream<QuerySnapshotPlatform> stream = query.snapshots();
        expect(stream, isA<Stream<QuerySnapshotPlatform>>());
      });

      test('listens to a single response', () async {
        Stream<QuerySnapshotPlatform> stream = query.snapshots();
        int call = 0;

        await stream.listen(expectAsync1((QuerySnapshotPlatform snapshot) {
          call++;
          if (call == 1) {
            expect(snapshot.docs.length, equals(1));
            expect(snapshot.docs[0], isA<DocumentSnapshotPlatform>());
            DocumentSnapshotPlatform documentSnapshot = snapshot.docs[0];
            expect(documentSnapshot.data()['foo'], equals('bar'));
          } else {
            fail("Should not have been called");
          }
        }, count: 1, reason: "Stream should only have been called once."));

        await Future.delayed(Duration(seconds: 1));
      });

      test('listens to a multiple changes response', () async {
        Stream<QuerySnapshotPlatform> stream = query.snapshots();
        int call = 0;

        StreamSubscription subscription = stream.listen(expectAsync1(
            (QuerySnapshotPlatform snapshot) {
          call++;
          if (call == 1) {
            expect(snapshot.docs.length, equals(1));
            DocumentSnapshotPlatform documentSnapshot = snapshot.docs[0];
            expect(documentSnapshot.data()['foo'], equals('bar'));
          } else if (call == 2) {
            expect(snapshot.docs.length, equals(2));
            DocumentSnapshotPlatform documentSnapshot =
                snapshot.docs.firstWhere((doc) => doc.id == 'doc1');
            expect(documentSnapshot.data()['bar'], equals('baz'));
          } else if (call == 3) {
            expect(snapshot.docs.length, equals(1));
            expect(
                snapshot.docs.where((doc) => doc.id == 'doc1').isEmpty, isTrue);
          } else if (call == 4) {
            expect(snapshot.docs.length, equals(2));
            DocumentSnapshotPlatform documentSnapshot =
                snapshot.docs.firstWhere((doc) => doc.id == 'doc2');
            expect(documentSnapshot.data()['foo'], equals('bar'));
          } else if (call == 5) {
            expect(snapshot.docs.length, equals(2));
            DocumentSnapshotPlatform documentSnapshot =
                snapshot.docs.firstWhere((doc) => doc.id == 'doc2');
            expect(documentSnapshot.data()['foo'], equals('baz'));
          } else {
            fail("Should not have been called");
          }
        },
            count: 5,
            reason: "Stream should only have been called five times."));

        await Future.delayed(Duration(milliseconds: 500));
        // await snapshot.doc('doc1').set({'bar': 'baz'});
        // await collection.doc('doc1').delete();
        // await collection.doc('doc2').set({'foo': 'bar'});
        // await collection.doc('doc2').update({'foo': 'baz'});

        await subscription.cancel();
      });
      test('onListen should invoke Query#addSnapshotListener', () {
        // final DocumentSnapshotPlatform snapshot = await firestore
        // .document('path/to/foo')
        // .snapshots(includeMetadataChanges: true)
        // .first;
        // expect(snapshot.id, equals('foo'));
        //  expect(snapshot.reference.path, equals('path/to/foo'));
        // expect(snapshot.data, equals(kMockDocumentSnapshotData));
        // // Flush the async removeListener call
        // await Future<void>.delayed(Duration.zero);
        // expect(
        //   log,
        //   <Matcher>[
        //     isMethodCall(
        //       'DocumentReference#addSnapshotListener',
        //       arguments: <String, dynamic>{
        //         'app': app.name,
        //         'path': 'path/to/foo',
        //         'includeMetadataChanges': true,
        //       },
        //     ),
        //     isMethodCall(
        //       'removeListener',
        //       arguments: <String, dynamic>{'handle': 0},
        //     ),
        //   ],
        // );
      });

      test('onCancel should invoke Firestore#removeListener', () {});
    });

    test("startAfterDocument()", () {
      List<List<dynamic>> orders = List.from([
        ['bar']
      ]); // orderby
      List<dynamic> values = [1]; // where
      MethodChannelQuery q = query.startAfterDocument(orders, values);

      expect(q, isNot(same(query)));
      expect(q.parameters['startAt'], equals(null));
      expect(
          q.parameters['orderBy'],
          equals([
            ['bar']
          ]));
      expect(q.parameters['startAfter'], equals([1]));
    });
    test("startAfter()", () {
      List<dynamic> fields = List.from(['bar']);
      MethodChannelQuery q = query.startAfter(fields);

      expect(q, isNot(same(query)));
      expect(q.parameters['startAt'], equals(null));
      expect(q.parameters['orderBy'], equals(['foo']));
      expect(q.parameters['startAfter'], equals(fields));
    });
    test("startAtDocument()", () {
      List<List<dynamic>> orders = List.from([
        ['bar']
      ]); // orderby
      List<dynamic> values = [1]; // where
      MethodChannelQuery q = query.startAtDocument(orders, values);

      expect(q, isNot(same(query)));
      expect(q.parameters['startAt'], equals([1]));
      expect(
          q.parameters['orderBy'],
          equals([
            ['bar']
          ]));
      expect(q.parameters['startAfter'], equals(null));
    });
    test("startAt()", () {
      List<dynamic> fields = List.from(['bar']);
      MethodChannelQuery q = query.startAt(fields);

      expect(q, isNot(same(query)));
      expect(q.parameters['startAt'], equals(['bar']));
      expect(q.parameters['startAfter'], equals(null));
    });

    test("where()", () {
      List<List<dynamic>> conditions = List.from([
        ['bar']
      ]);
      MethodChannelQuery q = query.where(conditions);

      expect(q, isNot(same(query)));
      expect(
          q.parameters['where'],
          equals([
            ['bar']
          ]));
    });
  });
}
