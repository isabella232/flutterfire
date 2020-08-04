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
    if (options?.maxResults != null) {
      assert(options.maxResults > 0);
      assert(options.maxResults <= 1000);
    }

    return ListResult._(storage, await _delegate.list(options));
  }

  Future<ListResult> listAll() async {
    return ListResult._(storage, await _delegate.listAll());
  }

  UploadTask put(ByteBuffer buffer, [SettableMetadata metadata]) {
    assert(buffer != null);
    return UploadTask._(storage, _delegate.put(buffer, metadata));
  }

  UploadTask putBlob(dynamic blob, [SettableMetadata metadata]) {
    assert(blob != null);
    return UploadTask._(storage, _delegate.putBlob(blob, metadata));
  }

  UploadTask putFile(File file, [SettableMetadata metadata]) {
    assert(file != null);
    assert(file.existsSync());
    return UploadTask._(storage, _delegate.putFile(file, metadata));
  }

  UploadTask putString(
    String data, {
    PutStringFormat format = PutStringFormat.raw,
    SettableMetadata metadata,
  }) {
    assert(data != null);
    assert(format != null);

    // Convert any raw string values into a Base64 format
    if (format == PutStringFormat.raw) {
      data = base64.encode(utf8.encode(data));
      format = PutStringFormat.base64;
    }

    // Convert a data_url into a Base64 format
    if (format == PutStringFormat.dataUrl) {
      format = PutStringFormat.base64;
      UriData uri = UriData.fromUri(Uri.parse(data));
      assert(uri.isBase64);
      data = uri.contentText;

      if (metadata == null && uri.mimeType.isNotEmpty) {
        metadata = SettableMetadata(
          contentType: uri.mimeType,
        );
      }

      // If the data_url contains a mime-type & the user has not provided it,
      // set it
      if ((metadata.contentType == null || metadata.contentType.isEmpty) &&
          uri.mimeType.isNotEmpty) {
        metadata = SettableMetadata(
          cacheControl: metadata.cacheControl,
          contentDisposition: metadata.contentDisposition,
          contentEncoding: metadata.contentEncoding,
          contentLanguage: metadata.contentLanguage,
          contentType: uri.mimeType,
        );
      }
    }
    return UploadTask._(storage, _delegate.putString(data, format, metadata));
  }

  Future<FullMetadata> updateMetadata(SettableMetadata metadata) {
    assert(metadata != null);
    return _delegate.updateMetadata(metadata);
  }

  DownloadTask writeToFile(File file) {
    assert(file != null);
    return DownloadTask._(storage, _delegate.writeToFile(file));
  }
}
