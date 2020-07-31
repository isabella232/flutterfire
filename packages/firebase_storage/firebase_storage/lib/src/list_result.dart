// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage;

class ListResult {
  ListResultPlatform _delegate;

  final FirebaseStorage storage;

  ListResult._(this.storage, this._delegate) {
    ListResultPlatform.verifyExtends(_delegate);
  }

  List<Reference> get items {
    return _delegate.items
        .map((referencePlatform) => Reference._(storage, referencePlatform))
        .toList();
  }

  String get nextPageToken => _delegate.nextPageToken;

  List<Reference> get prefixes {
    return _delegate.prefixes
        .map((referencePlatform) => Reference._(storage, referencePlatform))
        .toList();
  }
}
