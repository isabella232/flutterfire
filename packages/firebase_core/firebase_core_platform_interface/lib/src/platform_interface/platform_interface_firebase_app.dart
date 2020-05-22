// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of firebase_core_platform_interface;

/// A class storing the name and options of a Firebase app.
///
/// This is created as a result of calling [FirebaseCorePlatform.initializeApp].
class FirebaseAppPlatform extends PlatformInterface {
  FirebaseAppPlatform(this.name, this.options) : super(token: _token);

  static final Object _token = Object();

  static verifyExtends(FirebaseAppPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  /// The name of this Firebase app.
  final String name;

  /// Returns the [FirebaseOptions] that this app was configured with.
  final FirebaseOptions options;

  /// Returns whether this instance is the default Firebase app.
  bool get _isDefault => name == defaultFirebaseAppName;

  /// Returns true if automatic data collection is enabled for this app.
  bool get isAutomaticDataCollectionEnabled {
    throw UnimplementedError(
        'isAutomaticDataCollectionEnabled has not been implemented.');
  }

  /// Deletes the current FirebaseApp.
  Future<void> delete() async {
    throw UnimplementedError('delete() has not been implemented.');
  }

  /// Sets whether automatic data collection is enabled or disabled for this app.
  ///
  /// It is possible to check whether data collection is currently enabled via
  /// the [FirebaseAppPlatform.isAutomaticDataCollectionEnabled] property.
  Future<void> setAutomaticDataCollectionEnabled(bool enabled) async {
    throw UnimplementedError(
        'setAutomaticDataCollectionEnabled() has not been implemented.');
  }

  /// Sets whether automatic resource management is enabled or disabled for this app.
  Future<void> setAutomaticResourceManagementEnabled(bool enabled) async {
    throw UnimplementedError(
        'setAutomaticResourceManagementEnabled() has not been implemented.');
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other)) return true;
    if (other is! FirebaseAppPlatform) return false;
    return other.name == name && other.options == options;
  }

  @override
  int get hashCode => hash2(name, options);

  @override
  String toString() => '$FirebaseAppPlatform($name)';
}