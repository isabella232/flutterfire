import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

void runInstanceTests() {
  group('$FirebaseStorage.instance', () {
    FirebaseStorage storage;
    FirebaseApp secondaryApp;

    setUpAll(() async {
      storage = FirebaseStorage.instance;
      secondaryApp = Firebase.app('testapp');
    });

    test('instance', () {
      expect(storage, isA<FirebaseStorage>());
    });

    test('instanceFor', () {
      FirebaseStorage secondaryStorage = FirebaseStorage.instanceFor(
        app: secondaryApp,
      );
      expect(secondaryStorage, isA<FirebaseStorage>());
      expect(secondaryStorage.app.name, 'testapp');
    });

    group('ref', () {
      test('uses default path if none provided', () {
        Reference ref = storage.ref();
        expect(ref.fullPath, '/');
      });

      test('accepts a custom path', () async {
        Reference ref = storage.ref('foo/bar/baz.png');
        expect(ref.fullPath, 'foo/bar/baz.png');
      });

      test('strips leading / from custom path', () async {
        Reference ref = storage.ref('/foo/bar/baz.png');
        expect(ref.fullPath, 'foo/bar/baz.png');
      });
    });

    group('refFromURL', () {
      test('accepts a gs url', () async {
        const url = 'gs://foo/bar/baz.png';
        Reference ref = storage.refFromURL(url);
        expect(ref.toString(), url);
      });

      test('accepts a https url', () async {
        const url =
            'https://firebasestorage.googleapis.com/v0/b/react-native-firebase-testing.appspot.com/o/1mbTestFile.gif?alt=media';
        Reference ref = storage.refFromURL(url);
        expect(ref.bucket, 'react-native-firebase-testing');
        expect(ref.name, '1mbTestFile.gif');
        expect(ref.toString(),
            'gs://react-native-firebase-testing/1mbTestFile.gif');
      });

      test('accepts a https encoded url', () async {
        const url =
            'https%3A%2F%2Ffirebasestorage.googleapis.com%2Fv0%2Fb%2Freact-native-firebase-testing.appspot.com%2Fo%2F1mbTestFile.gif%3Falt%3Dmedia';
        Reference ref = storage.refFromURL(url);
        expect(ref.bucket, 'react-native-firebase-testing');
        expect(ref.name, '1mbTestFile.gif');
        expect(ref.toString(),
            'gs://react-native-firebase-testing/1mbTestFile.gif');
      });

      test('throws an error if https url could not be parsed', () async {
        try {
          storage.refFromURL('https://invertase.io');
          fail('Did not throw an Error.');
        } catch (error) {
          expect(error.message, contains("unable to parse 'url'"));
          return;
        }
      });

      test('accepts a gs url without a fullPath', () async {
        const url = 'gs://some-bucket';
        Reference ref = storage.refFromURL(url);
        expect(ref.toString(), url);
      });

      test('throws an error if url does not start with gs:// or https://',
          () async {
        try {
          storage.refFromURL('bs://foo/bar/cat.gif');
          fail('Did not throw an Error.');
        } catch (error) {
          expect(error.message, contains("begin with 'gs://'"));
          return;
        }
      });
    });

    group('setMaxOperationRetryTime', () {
      test('should set', () async {
        expect(storage.maxOperationRetryTime, 120000);
        await storage.setMaxOperationRetryTime(100000);
        expect(storage.maxOperationRetryTime, 100000);
      });
    });

    group('setMaxUploadRetryTime', () {
      test('should set', () async {
        expect(storage.maxUploadRetryTime, 600000);
        await storage.setMaxUploadRetryTime(120000);
        expect(storage.maxUploadRetryTime, 120000);
      });
    });

    group('setMaxDownloadRetryTime', () {
      test('should set', () async {
        expect(storage.maxDownloadRetryTime, 600000);
        await storage.setMaxDownloadRetryTime(120000);
        expect(storage.maxDownloadRetryTime, 120000);
      });
    });

    test('toString', () {
      expect(storage.toString(), '');
    });
  });
}
