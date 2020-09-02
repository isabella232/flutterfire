// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage;

/// A [TaskSnapshot] is returned as the result or on-going process of a [Task].
class TaskSnapshot {
  TaskSnapshotPlatform _delegate;

  /// The [FirebaseStorage] instance used to create the task.
  final FirebaseStorage storage;

  TaskSnapshot._(this.storage, this._delegate) {
    TaskSnapshotPlatform.verifyExtends(_delegate);
  }

  /// The current transferred bytes of this task.
  int get bytesTransferred => _delegate.bytesTransferred;

  /// The [FullMetadata] associated with this task.
  ///
  /// May be `null` if no metadata exists.
  FullMetadata get metadata => _delegate.metadata;

  /// The [Reference] for this snapshot.
  Reference get ref {
    return Reference._(storage, _delegate.ref);
  }

  /// The current task snapshot state.
  ///
  /// The state indicates the current progress of the task, such as whether it
  /// is running, paused or completed.
  TaskState get state => _delegate.state;

  /// The total bytes of the task.
  int get totalBytes => _delegate.totalBytes;

  @override
  bool operator ==(dynamic o) =>
      o is TaskSnapshot && o.ref == ref && o.storage == storage;

  @override
  int get hashCode => hash2(storage, ref);

  @override
  String toString() => '$TaskSnapshot(app: ${storage.app.name}, ref: $ref)';
}
