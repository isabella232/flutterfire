// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage;

abstract class Task {
  TaskPlatform _delegate;

  final FirebaseStorage storage;

  Task._(this.storage, this._delegate) {
    TaskPlatform.verifyExtends(_delegate);
  }

  @Deprecated('events has been deprecated in favor of snapshotEvents')
  Stream<dynamic> get events {
    return snapshotEvents;
  }

  Stream<TaskSnapshot> get snapshotEvents {
    return _delegate.snapshotEvents
        .map((snapshotDelegate) => TaskSnapshot._(storage, snapshotDelegate));
  }

  @Deprecated("Deprecated in favor of [snapshot]")
  TaskSnapshot get lastSnapshot => snapshot;

  TaskSnapshot get snapshot => TaskSnapshot._(storage, _delegate.snapshot);

  Future<dynamic> get onComplete => _delegate.onComplete;

  Future<void> pause() => _delegate.pause();

  Future<void> resume() => _delegate.resume();

  Future<void> cancel() => _delegate.cancel();
}

class UploadTask extends Task {
  UploadTask._(FirebaseStorage storage, TaskPlatform delegate)
      : super._(storage, delegate);
}

class DownloadTask extends Task {
  DownloadTask._(FirebaseStorage storage, TaskPlatform delegate)
      : super._(storage, delegate);
}
