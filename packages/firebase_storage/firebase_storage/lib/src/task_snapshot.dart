// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage;

class TaskSnapshot {
  TaskSnapshotPlatform _delegate;

  final FirebaseStorage storage;

  TaskSnapshot._(this.storage, this._delegate) {
    TaskSnapshotPlatform.verifyExtends(_delegate);
  }

  int get bytesTransferred => _delegate.bytesTransferred;

  FullMetadata get metadata => _delegate.metadata;

  Reference get ref {
    return Reference._(storage, _delegate.ref);
  }

  TaskState get state => _delegate.state;

  int get totalBytes => _delegate.totalBytes;

  @override
  bool operator ==(dynamic o) =>
      o is TaskSnapshot && o.ref == ref && o.storage == storage;

  @override
  int get hashCode => hash2(storage, ref);

  @override
  String toString() => '$TaskSnapshot(app: ${storage.app.name}, ref: $ref)';
}
