import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import './test_utils.dart';

void runReferenceTests() {
  group('$Reference', () {
    FirebaseStorage storage;

    setUpAll(() async {
      storage = FirebaseStorage.instance;
    });

    group('bucket', () {
      test('returns the storage bucket as a string', () async {
        // TODO: failing, bucket is null
        expect(
            storage.ref('/ok.jpeg').bucket, storage.app.options.storageBucket);
      });
    });

    group('fullPath', () {
      test('returns the full path as a string', () async {
        expect(storage.ref('/foo/uploadNope.jpeg').fullPath,
            'foo/uploadNope.jpeg');

        expect(
            storage.ref('foo/uploadNope.jpeg').fullPath, 'foo/uploadNope.jpeg');
      });
    });

    group('name', () {
      test('returns the file name as a string', () async {
        Reference ref = storage.ref('/foo/uploadNope.jpeg');
        expect(ref.name, 'uploadNope.jpeg');
      });
    });

    group('parent', () {
      test('returns the parent directory as a reference', () async {
        expect(storage.ref('/foo/uploadNope.jpeg').parent.fullPath, 'foo');
      });

      test('returns null if already at root', () async {
        Reference ref = storage.ref('/');
        expect(ref.parent, isNull);
      });
    });

    group('root', () {
      test('returns a reference to the root of the bucket', () async {
        expect(storage.ref('/foo/uploadNope.jpeg').root.fullPath, '/');
      });
    });

    group('child()', () {
      test('returns a reference to a child path', () async {
        Reference parentRef = storage.ref('/foo');
        Reference childRef = parentRef.child('someFile.json');

        expect(childRef.fullPath, 'foo/someFile.json');
      });
    });

    group('delete()', () {
      setUpAll(() async {
        File file = await createFile('deleteMe.jpeg');
        await storage.ref('/ok.jpeg').writeToFile(file);
        await storage.ref('/deleteMe.jpeg').putFile(file);
      });

      test('should delete a file', () async {
        Reference ref = storage.ref('/deleteMe.jpeg');
        await ref.delete();

        try {
          await ref.getMetadata();
          // TODO: failing, returning Future.error
        } on FirebaseException catch (error) {
          expect(error.code, 'object-not-found');
          expect(error.message, 'No object exists at the desired reference.');
          return;
        }
        fail('Did not throw');
      });

      test('throws error if file does not exist', () async {
        Reference ref = storage.ref('/iDoNotExist.jpeg');

        try {
          await ref.delete();
        } on FirebaseException catch (error) {
          expect(error.code, 'object-not-found');
          expect(error.message, 'No object exists at the desired reference.');
          return;
        }

        fail('Did not throw');
      });

      test('throws error if no write permission', () async {
        Reference ref = storage.ref('/uploadNope.jpeg');

        try {
          await ref.delete();
        } on FirebaseException catch (error) {
          expect(error.code, 'permission-denied');
          expect(error.message,
              'User is not authorized to perform the desired action.');

          return;
        }

        fail('Did not throw');
      });
    });

    group('getDownloadURL', () {
      test('gets a download url', () async {
        Reference ref = storage.ref('/ok.jpeg');
        String downloadUrl = await ref.getDownloadURL();
        expect(downloadUrl, isA<String>());
        print('download url $downloadUrl');
        expect(downloadUrl, contains('/ok.jpeg'));
        expect(downloadUrl, contains(storage.app.options.projectId));
      });

      test('errors if permission denied', () async {
        Reference ref = storage.ref('/not.jpeg');
        try {
          String downloadUrl = await ref.getDownloadURL();
          expect(downloadUrl, isA<String>());
          // TODO: failing, returning Future.error
        } on FirebaseException catch (error) {
          expect(error.plugin, 'firebase_storage');
          expect(error.code, 'permission-denied');
          expect(error.message,
              'User is not authorized to perform the desired action.');
          return;
        } catch (_) {
          fail('Should have thrown an [FirebaseException] error');
        }

        fail('Should have thrown an error');
      });

      test('throws error if file does not exist', () async {
        Reference ref = storage.ref('/iDoNotExist.jpeg');

        try {
          await ref.getDownloadURL();
          // TODO: failing, returning Future.error
        } on FirebaseException catch (error) {
          expect(error.plugin, 'firebase_storage');
          expect(error.code, 'object-not-found');
          expect(error.message, 'No object exists at the desired reference.');
          return;
        } catch (_) {
          fail('Should have thrown an [FirebaseException] error');
        }

        fail('Should have thrown an error');
      });
    });

    group('list', () {
      test('returns list results', () async {
        Reference ref = storage.ref('/list');
        ListResult result = await ref.list(ListOptions(maxResults: 25));

        expect(result.items.length, greaterThan(0));
        expect(result.prefixes, isA<List<Reference>>());
        expect(result.prefixes.length, greaterThan(0));
      });

      test('errors if maxResults is less than 0 ', () async {
        Reference ref = storage.ref('/list');
        expect(
            () => ref.list(ListOptions(maxResults: -1)), throwsAssertionError);
      });

      test('errors if maxResults is 0 ', () async {
        Reference ref = storage.ref('/list');
        expect(
            () => ref.list(ListOptions(maxResults: 0)), throwsAssertionError);
      });

      test('errors if maxResults is more than 1000 ', () async {
        Reference ref = storage.ref('/list');
        expect(() => ref.list(ListOptions(maxResults: 1001)),
            throwsAssertionError);
      });
    });

    test('listAll', () async {
      Reference ref = storage.ref('/list');
      ListResult result = await ref.listAll();
      expect(result.items, isNotNull);
      expect(result.items.length, greaterThan(0));
      expect(result.nextPageToken, isNull);

      expect(result.prefixes, isA<List<Reference>>());
      expect(result.prefixes.length, greaterThan(0));
    });

    group('put', () {
      test('uploads a file with buffer', () async {
        List<int> list = utf8.encode('hello world');

        ByteBuffer buffer = Uint8List.fromList(list).buffer;

        final Reference ref = storage.ref('/playground').child('flt-ok.txt');
        final UploadTask uploadTask = ref.put(
            buffer,
            SettableMetadata(
              contentLanguage: 'en',
              customMetadata: <String, String>{'activity': 'test'},
            ));
        final TaskSnapshot complete = await uploadTask.onComplete;

        expect(complete.metadata.size, kTestString.length);
        expect(complete.metadata.contentLanguage, 'en');
        expect(complete.metadata.customMetadata['activity'], 'test');
      });

      test('errors if permission denied', () async {
        try {
          List<int> list = utf8.encode('hello world');

          ByteBuffer buffer = Uint8List.fromList(list).buffer;

          UploadTask uploadTask = storage.ref('/uploadNope.jpeg').put(buffer);
          await uploadTask.onComplete;
          fail('Should have thrown an error');
        } on FirebaseException catch (error) {
          expect(error.plugin, 'firebase_storage');
          expect(error.code, 'permission-denied');
          expect(error.message,
              'User is not authorized to perform the desired action.');
        } catch (_) {
          fail('Should have thrown an [FirebaseException] error');
        }
      });
    });

    group('putBlob', () {
      test('throws [UnimplementedError] for native platforms', () async {
        final File file = await createFile('flt-ok.txt');
        final Reference ref = storage.ref('/playground').child('flt-ok.txt');

        try {
          final UploadTask uploadTask = ref.putBlob(
              file,
              SettableMetadata(
                contentLanguage: 'en',
                customMetadata: <String, String>{'activity': 'test'},
              ));
          await uploadTask.onComplete;
        } on UnimplementedError catch (error) {
          expect(error.message,
              'putBlob() is not supported on native platforms. Use [put], [putFile] or [putString] instead.');
        }
      }, skip: !kIsWeb);
    });

    group('putFile', () {
      test('uploads a file', () async {
        final File file = await createFile('flt-ok.txt');
        final Reference ref = storage.ref('/playground').child('flt-ok.txt');

        final UploadTask uploadTask = ref.putFile(
          file,
          SettableMetadata(
            contentLanguage: 'en',
            customMetadata: <String, String>{'activity': 'test'},
          ),
        );

        final TaskSnapshot complete = await uploadTask.onComplete;
        expect(complete.metadata.size, kTestString.length);
        expect(complete.metadata.contentLanguage, 'en');
        expect(complete.metadata.customMetadata['activity'], 'test');
      });

      test('errors if permission denied', () async {
        try {
          File file = await createFile('flt-ok.txt');
          UploadTask uploadTask = storage.ref('/uploadNope.jpeg').putFile(file);
          await uploadTask.onComplete;
        } on FirebaseException catch (error) {
          expect(error.plugin, 'firebase_storage');
          expect(error.code, 'permission-denied');
          expect(error.message,
              'User is not authorized to perform the desired action.');
          return;
        } catch (_) {
          fail('Should have thrown an [FirebaseException] error');
        }

        fail('Should have thrown an error');
      });
    });

    group('putString', () {
      test('uploads a string', () async {
        final Reference ref = storage.ref('/playground').child('flt-ok.txt');

        final UploadTask uploadTask = ref.putString('data');
        final TaskSnapshot complete = await uploadTask.onComplete;
        expect(complete.totalBytes, greaterThan(0));
      });

      test('errors if permission denied', () async {
        try {
          UploadTask uploadTask =
              storage.ref('/uploadNope.jpeg').putString('data');
          await uploadTask.onComplete;
        } on FirebaseException catch (error) {
          expect(error.plugin, 'firebase_storage');
          expect(error.code, 'permission-denied');
          expect(error.message,
              'User is not authorized to perform the desired action.');
          return;
        } catch (_) {
          fail('Should have thrown an [FirebaseException] error');
        }

        fail('Should have thrown an error');
      });
    });

    group('updateMetadata', () {
      test('updates metadata', () async {
        Reference ref = storage.ref('/playground').child('flt-ok.txt');
        FullMetadata fullMetadata =
            await ref.updateMetadata(SettableMetadata(contentLanguage: 'fr'));
        expect(fullMetadata.contentLanguage, 'fr');
      });

      test('errors if property does not exist', () async {
        Reference ref = storage.ref('/not.jpeg');
        try {
          await ref.updateMetadata(SettableMetadata(contentType: 'unknown'));
          // TODO: failing, returning Future.error
        } on FirebaseException catch (e) {
          expect(e.code, 'object-not-found');
          expect(e.message, 'No object exists at the desired reference.');
          return;
        } catch (e) {
          print('not a firebase exp $e');
          fail('should have thrown an [FirebaseException] error');
        }

        fail('should have thrown an error');
      });

      test('errors if permission denied', () async {
        try {
          Reference ref = storage.ref('/ok.jpeg');

          await ref.updateMetadata(SettableMetadata(contentType: 'jpeg'));
          // TODO: failing, returning Future.error
        } on FirebaseException catch (error) {
          expect(error.plugin, 'firebase_storage');
          expect(error.code, 'permission-denied');
          expect(error.message,
              'User is not authorized to perform the desired action.');
          return;
        } catch (_) {
          fail('Should have thrown an [FirebaseException] error');
        }

        fail('Should have thrown an error');
      });
    });

    group('writeToFile', () {
      test('downloads a file', () async {
        File file = await createFile('ok.jpeg');
        DownloadTask downloadTask = storage.ref('/ok.jpeg').writeToFile(file);
        TaskSnapshot complete = await downloadTask.onComplete;
        expect(complete.bytesTransferred, complete.totalBytes);
        expect(complete.state, TaskState.complete);
      });

      test('errors if permission denied', () async {
        try {
          File file = await createFile('not.jpeg');
          DownloadTask downloadTask =
              storage.ref('/not.jpeg').writeToFile(file);
          await downloadTask.onComplete;
        } on FirebaseException catch (error) {
          expect(error.plugin, 'firebase_storage');
          expect(error.code, 'permission-denied');
          expect(error.message,
              'User is not authorized to perform the desired action.');
          return;
        } catch (_) {
          fail('Should have thrown an [FirebaseException] error');
        }

        fail('Should have thrown an error');
      });
    });

    test('toString', () async {
      expect(storage.ref('/uploadNope.jpeg').toString(),
          equals('Reference(app: [DEFAULT], fullPath: uploadNope.jpeg)'));
    });
  });
}
