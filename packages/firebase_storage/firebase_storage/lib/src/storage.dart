// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of firebase_storage;

/// The entrypoint for [FirebaseStorage].
class FirebaseStorage extends FirebasePluginPlatform {
  // Cached and lazily loaded instance of [FirestorePlatform] to avoid
  // creating a [MethodChannelFirestore] when not needed or creating an
  // instance with the default app before a user specifies an app.
  FirebaseStoragePlatform _delegatePackingProperty;

  FirebaseStoragePlatform get _delegate {
    if (_delegatePackingProperty == null) {
      _delegatePackingProperty = FirebaseStoragePlatform.instanceFor(app: app);
    }
    return _delegatePackingProperty;
  }

  /// The [FirebaseApp] for this current [FirebaseFirestore] instance.
  FirebaseApp app;

  String storageBucket;

  FirebaseStorage._({this.app, this.storageBucket})
      : super(app.name, 'plugins.flutter.io/firebase_storage');

  static final Map<String, FirebaseStorage> _cachedInstances = {};

  /// Returns an instance using the default [FirebaseApp].
  static FirebaseStorage get instance {
    return FirebaseStorage.instanceFor(
      app: Firebase.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp].
  static FirebaseStorage instanceFor({FirebaseApp app, String storageBucket}) {
    assert(app != null);
    String key = '${app.name}|${storageBucket ?? ''}';

    if (_cachedInstances.containsKey(key)) {
      return _cachedInstances[key];
    }

    FirebaseStorage newInstance =
        FirebaseStorage._(app: app, storageBucket: storageBucket);
    _cachedInstances[key] = newInstance;

    return newInstance;
  }

  // ignore: public_member_api_docs
  @Deprecated(
      "Constructing Storage is deprecated, use 'FirebaseStorage.instance' or 'FirebaseStorage.instanceFor' instead")
  factory FirebaseStorage({FirebaseApp app, String storageBucket}) {
    return FirebaseStorage.instanceFor(app: app, storageBucket: storageBucket);
  }

  Reference ref(String path) {
    return Reference._(this, _delegate.ref(path));
  }

  Reference refFromURL(String url) {
    assert(url != null);
    assert(url.startsWith('gs://') || url.startsWith('http'));

    // TODO validate URL
    return Reference._(this, _delegate.refFromURL(url));
  }

  Future<void> setMaxOperationRetryTime(int time) {
    assert(time != null);
    assert(time > 0);
    return _delegate.setMaxOperationRetryTime(time);
  }

  Future<void> setMaxUploadRetryTime(int time) {
    assert(time != null);
    assert(time > 0);
    return _delegate.setMaxUploadRetryTime(time);
  }

  Future<void> setMaxDownloadRetryTime(int time) {
    assert(time != null);
    assert(time > 0);
    return _delegate.setMaxDownloadRetryTime(time);
  }
}
