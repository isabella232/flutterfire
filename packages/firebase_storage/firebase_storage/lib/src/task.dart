// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage;

/// A class representing an on-going storage task.
abstract class Task {
  TaskPlatform _delegate;

  /// The [FirebaseStorage] instance associated with this task.
  final FirebaseStorage storage;

  Task._(this.storage, this._delegate) {
    TaskPlatform.verifyExtends(_delegate);
  }

  @Deprecated('events has been deprecated in favor of snapshotEvents')
  // ignore: public_member_api_docs
  Stream<dynamic> get events {
    return snapshotEvents;
  }

  /// Returns a [Stream] of [TaskSnapshot] events.
  ///
  /// If the task is canceled or fails, the stream will send an error event.
  /// See [TaskState] for more information of the different event types.
  ///
  /// If you do not need to know about on-going stream events, you can instead
  /// wait for the stream to complete via [onComplete].
  Stream<TaskSnapshot> get snapshotEvents {
    return _delegate.snapshotEvents
        .map((snapshotDelegate) => TaskSnapshot._(storage, snapshotDelegate));
  }

  @Deprecated("Deprecated in favor of [snapshot]")
  // ignore: public_member_api_docs
  TaskSnapshot get lastSnapshot => snapshot;

  /// The latest [TaskSnapshot] for this task.
  TaskSnapshot get snapshot {
    if (_delegate.snapshot == null) return null;
    return TaskSnapshot._(storage, _delegate.snapshot);
  }

  /// Returns a [Future] once the task has completed.
  ///
  /// Waiting for the future is not required, instead you can wait for a
  /// completion event via [snapshotEvents].
  Future<TaskSnapshot> get onComplete async {
    return TaskSnapshot._(storage, await _delegate.onComplete);
  }

  /// Pauses the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.paused]
  /// state.
  Future<bool> pause() => _delegate.pause();

  /// Resumes the current task.
  ///
  /// Calling this method will trigger a snapshot event with a [TaskState.running]
  /// state.
  Future<bool> resume() => _delegate.resume();

  /// Cancels the current task.
  ///
  /// Calling this method will cause the task to fail. Both the Future ([onComplete])
  /// and stream ([streamEvents]) will trigger an error with a [FirebaseException].
  Future<bool> cancel() => _delegate.cancel();
}

/// A class which indicates an on-going upload task.
class UploadTask extends Task {
  UploadTask._(FirebaseStorage storage, TaskPlatform delegate)
      : super._(storage, delegate);
}

/// A class which indicates an on-going download task.
class DownloadTask extends Task {
  DownloadTask._(FirebaseStorage storage, TaskPlatform delegate)
      : super._(storage, delegate);
}
