import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import './test_utils.dart';

void runTaskTests() {
  group('$Task', () {
    FirebaseStorage storage;
    File file;
    Reference uploadRef;
    Reference downloadRef;

    setUpAll(() async {
      storage = FirebaseStorage.instance;
      file = await createFile('ok.jpeg');
      uploadRef = storage.ref('/playground').child('flt-ok.txt');
      downloadRef = storage.ref('/ok.jpeg');
    });

    group('pause() resume() onComplete()', () {
      Task task;
      bool hadRunningStatus;
      bool hadPausedStatus;
      bool hadResumedStatus;

      setUp(() {
        task = null;
        hadRunningStatus = false;
        hadPausedStatus = false;
        hadResumedStatus = false;
      });

      final _testPauseTask = (String type) async {
        final subscription =
            task.snapshotEvents.listen((TaskSnapshot snapshot) async {
          // 1) pause when we receive first running event
          if (snapshot.state == TaskState.running && !hadRunningStatus) {
            hadRunningStatus = true;
            await task.pause();
          }
          // 2) resume when we receive first paused event
          if (snapshot.state == TaskState.paused) {
            hadPausedStatus = true;
            await task.resume();
          }
          // 3) track that we resumed on 2nd running status whilst paused
          if (snapshot.state == TaskState.running &&
              hadRunningStatus &&
              hadPausedStatus &&
              !hadResumedStatus) {
            hadResumedStatus = true;
          }
          // 4) finally confirm we received all statuses
          if (snapshot.state == TaskState.complete) {
            expect(hadRunningStatus, true);
            expect(hadPausedStatus, true);
            expect(hadResumedStatus, true);
          }
        });
        await task.onComplete.then((snapshot) {
          expect(hadPausedStatus, isTrue);
          expect(hadResumedStatus, isTrue);
          expect(hadRunningStatus, isTrue);

          // Only check bytesTransferred against totalBytes for upload task
          if (type == 'Upload') {
            expect(snapshot.totalBytes, snapshot.bytesTransferred);
          }
        });
        await subscription.cancel();
      };

      test('successfully pauses and resumes a download task', () async {
        task = downloadRef.writeToFile(file);
        await _testPauseTask('Download');
      });

      test('successfully pauses and resumes a upload task', () async {
        task = uploadRef.putFile(file);
        await _testPauseTask('Upload');
      });
    });

    group('snapshot', () {
      test('returns the latest snapshot for download task', () async {
        final downloadTask = downloadRef.writeToFile(file);

        expect(downloadTask.snapshot, isNull);

        TaskSnapshot completedSnapshot = await downloadTask.onComplete;
        final snapshot = downloadTask.snapshot;

        expect(snapshot, isA<TaskSnapshot>());
        expect(snapshot.state, TaskState.complete);
        expect(snapshot.bytesTransferred, completedSnapshot.bytesTransferred);
        expect(snapshot.totalBytes, completedSnapshot.totalBytes);
        expect(snapshot.metadata, isNull);
      });

      test('returns the latest snapshot for upload task', () async {
        final uploadTask = uploadRef.putFile(file);
        expect(uploadTask.snapshot, isNull);

        TaskSnapshot completedSnapshot = await uploadTask.onComplete;
        final snapshot = uploadTask.snapshot;
        expect(snapshot, isA<TaskSnapshot>());
        expect(snapshot.bytesTransferred, completedSnapshot.bytesTransferred);
        expect(snapshot.totalBytes, completedSnapshot.totalBytes);
        expect(snapshot.metadata, isA<FullMetadata>());
      });
    });

    group('cancel()', () {
      Task task;
      bool hadRunningStatus;
      bool isCancelled;

      setUp(() {
        task = null;
        hadRunningStatus = false;
        isCancelled = false;
      });

      final _testCancelTask = (String type) async {
        final subscription =
            task.snapshotEvents.listen((TaskSnapshot snapshot) async {
          // 1) cancel it when we receive first running event
          if (snapshot.state == TaskState.running && !hadRunningStatus) {
            hadRunningStatus = true;
            isCancelled = await task.cancel();
            expect(isCancelled, isTrue);
          }
          if (snapshot.state == TaskState.complete) {
            fail('$type task did not cancel!');
          }
        });

        await task.onComplete.then((snapshot) {
          fail('$type task did not cancel!');
        }).catchError((error) {
          // TODO(helenaford): when error is thrown correctly check the output
          // expect(error.code, "canceled");
          // expect(error.message, "User canceled the upload/download.");
          expect(isCancelled, isTrue);
        });

        await subscription.cancel();
      };

      test('successfully cancels download task', () async {
        task = downloadRef.writeToFile(file);
        await _testCancelTask('Download');
      });

      test('successfully cancels upload task', () async {
        task = uploadRef.putFile(file);
        await _testCancelTask('Upload');
      });
    });
  });
}
