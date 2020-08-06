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
      _delegatePackingProperty = FirebaseStoragePlatform.instanceFor(
        app: app,
        bucket: bucket,
        pluginConstants: pluginConstants,
      );
    }
    return _delegatePackingProperty;
  }

  /// The [FirebaseApp] for this current [FirebaseFirestore] instance.
  FirebaseApp app;

  /// The storage bucket of this instance.
  String bucket;

  /// The maximum time to retry operations other than uploads or downloads in milliseconds.
  int get maxOperationRetryTime {
    return _delegate.maxOperationRetryTime;
  }

  /// The maximum time to retry uploads in milliseconds.
  int get maxUploadRetryTime {
    return _delegate.maxUploadRetryTime;
  }

  /// The maximum time to retry downloads in milliseconds.
  int get maxDownloadRetryTime {
    return _delegate.maxDownloadRetryTime;
  }

  FirebaseStorage._({this.app, this.bucket})
      : super(app.name, 'plugins.flutter.io/firebase_storage');

  static final Map<String, FirebaseStorage> _cachedInstances = {};

  /// Returns an instance using the default [FirebaseApp].
  static FirebaseStorage get instance {
    return FirebaseStorage.instanceFor(
      app: Firebase.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp].
  static FirebaseStorage instanceFor(
      {FirebaseApp app,
      String bucket,
      @Deprecated("Deprecated in favour of using the [bucket] argument.")
          String storageBucket}) {
    assert(app != null);
    bucket ??= storageBucket;
    String key = '${app.name}|${bucket ?? ''}';

    if (_cachedInstances.containsKey(key)) {
      return _cachedInstances[key];
    }

    FirebaseStorage newInstance = FirebaseStorage._(app: app, bucket: bucket);
    _cachedInstances[key] = newInstance;

    return newInstance;
  }

  // ignore: public_member_api_docs
  @Deprecated(
      "Constructing Storage is deprecated, use 'FirebaseStorage.instance' or 'FirebaseStorage.instanceFor' instead")
  factory FirebaseStorage({FirebaseApp app, String bucket}) {
    return FirebaseStorage.instanceFor(app: app, bucket: bucket);
  }

  /// Returns a new [Reference].
  ///
  /// If the [path] is empty, the reference will point to the root of the
  /// storage bucket.
  Reference ref([String path]) {
    path ??= '/';
    return Reference._(this, _delegate.ref(path));
  }

  /// Returns a new [Reference] from a given URL.
  ///
  /// The [url] can either be a HTTP or Google Storage URL pointing to an object.
  /// If the URL contains a storage bucket which is differen to the current
  /// [FirebaseStorage.bucket], a new [FirebaseStorage] instance for the
  /// [Reference] will be used instead.
  Reference refFromURL(String url) {
    assert(url != null);
    assert(url.startsWith('gs://') || url.startsWith('http'));

    String bucket;
    String path;

    if (url.startsWith('http')) {
      // TODO REGEX https://regex101.com/r/ZimjV0/1
    } else {
      bucket = bucketFromGoogleStorageUrl(url);
      path = pathFromGoogleStorageUrl(url);
    }

    return FirebaseStorage.instanceFor(app: app, bucket: bucket).ref(path);
  }

  @Deprecated("Deprecated in favor of refFromURL")
  // ignore: public_member_api_docs
  Future<Reference> getReferenceFromUrl(String url) async {
    return refFromURL(url);
  }

  @Deprecated("Deprecated in favor of get.maxOperationRetryTime")
  // ignore: public_member_api_docs
  Future<int> getMaxOperationRetryTimeMillis() async {
    return maxOperationRetryTime;
  }

  @Deprecated("Deprecated in favor of get.maxUploadRetryTime")
  // ignore: public_member_api_docs
  Future<int> getMaxUploadRetryTimeMillis() async {
    return maxUploadRetryTime;
  }

  @Deprecated("Deprecated in favor of get.maxDownloadRetryTime")
  // ignore: public_member_api_docs
  Future<int> getMaxDownloadRetryTimeMillis() async {
    return maxDownloadRetryTime;
  }

  /// The new maximum operation retry time in milliseconds.
  Future<void> setMaxOperationRetryTime(int time) {
    assert(time != null);
    assert(time > 0);
    return _delegate.setMaxOperationRetryTime(time);
  }

  @Deprecated("Deprecated in favor of setMaxUploadRetryTime()")
  // ignore: public_member_api_docs
  Future<void> setMaxOperationRetryTimeMillis(int time) {
    return setMaxUploadRetryTime(time);
  }

  /// The new maximum upload retry time in milliseconds.
  Future<void> setMaxUploadRetryTime(int time) {
    assert(time != null);
    assert(time > 0);
    return _delegate.setMaxUploadRetryTime(time);
  }

  @Deprecated("Deprecated in favor of setMaxUploadRetryTime()")
  // ignore: public_member_api_docs
  Future<void> setMaxUploadRetryTimeMillis(int time) {
    return setMaxUploadRetryTime(time);
  }

  /// The new maximum download retry time in milliseconds.
  Future<void> setMaxDownloadRetryTime(int time) {
    assert(time != null);
    assert(time > 0);
    return _delegate.setMaxDownloadRetryTime(time);
  }

  @Deprecated("Deprecated in favor of setMaxDownloadRetryTime()")
  // ignore: public_member_api_docs
  Future<void> setMaxDownloadRetryTimeMillis(int time) {
    return setMaxDownloadRetryTime(time);
  }

  @override
  bool operator ==(dynamic o) =>
      o is FirebaseStorage && o.app.name == app.name && o.bucket == bucket;

  @override
  int get hashCode => hash2(app.name, bucket);

  @override
  String toString() => '$FirebaseStorage(app: ${app.name}, bucket: $bucket)';
}
