// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_storage;

class Reference {
  ReferencePlatform _delegate;

  final FirebaseStorage storage;

  Reference._(this.storage, this._delegate) {
    ReferencePlatform.verifyExtends(_delegate);
  }

  String get bucket => _delegate.bucket;

  String get fullPath => _delegate.fullPath;

  String get name => _delegate.name;

  Reference get parent {
    ReferencePlatform referenceParentPlatform = _delegate.parent;

    if (referenceParentPlatform == null) {
      return null;
    }

    return Reference._(storage, referenceParentPlatform);
  }

  Reference get root => Reference._(storage, _delegate.root);

  Reference child(String path) {
    assert(path != null);
    return Reference._(storage, _delegate.child(path));
  }

  Future<void> delete() => _delegate.delete();

  Future<String> getDownloadURL() => _delegate.getDownloadURL();

  Future<FullMetadata> getMetadata() => _delegate.getMetadata();

  Future<ListResult> list(ListOptions options) async {
    return ListResult._(storage, await _delegate.list(options));
  }

  Future<ListResult> listAll() async {
    return ListResult._(storage, await _delegate.listAll());
  }

  Task put(ByteBuffer buffer, [SettableMetadata metadata]) {
    assert(buffer != null);
    return Task._(storage, _delegate.put(buffer, metadata));
  }

  Task putBlob(dynamic blob, [SettableMetadata metadata]) {
    assert(blob != null);
    return Task._(storage, _delegate.putBlob(blob, metadata));
  }

  Task putFile(File file, [SettableMetadata metadata]) {
    assert(file != null);
    assert(file.existsSync()); // TODO required?
    return Task._(storage, _delegate.putFile(file, metadata));
  }

  Task putString(
    String data, {
    PutStringFormat format = PutStringFormat.raw,
    SettableMetadata metadata,
  }) {
    assert(data != null);
    assert(format != null);
    return Task._(storage, _delegate.putString(data, format, metadata));
  }

  Future<FullMetadata> updateMetadata(SettableMetadata metadata) {
    assert(metadata != null);
    return _delegate.updateMetadata(metadata);
  }

  // TODO writeToFile?
}
