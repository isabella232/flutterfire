// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_functions;

/// A reference to a particular Callable HTTPS trigger in Cloud Functions.
///
/// You can get an instance by calling [CloudFunctions.instance.getHTTPSCallable].
class HttpsCallable {
  HttpsCallable._(this._delegate);

  final HttpsCallablePlatform _delegate;

  /// Executes this Callable HTTPS trigger asynchronously.
  ///
  /// The data passed into the trigger can be any of the following types:
  ///
  /// `null`
  /// `String`
  /// `num`
  /// [List], where the contained objects are also one of these types.
  /// [Map], where the values are also one of these types.
  ///
  /// The request to the Cloud Functions backend made by this method
  /// automatically includes a Firebase Instance ID token to identify the app
  /// instance. If a user is logged in with Firebase Auth, an auth ID token for
  /// the user is also automatically included.
  Future<HttpsCallableResult> call([dynamic parameters]) async {
    _assertValidParameterType(parameters);
    return HttpsCallableResult._(await _delegate.call(parameters));
  }

  @Deprecated(
      "Setting the timeout is deprecated in favor of using [HttpsCallableOptions]")
  set timeout(Duration duration) {
    _delegate.timeout = duration;
  }
}

void _assertValidParameterType(dynamic parameter, [bool isRoot = true]) {
  if (isRoot && parameter is List) {
    return parameter
        .forEach((element) => _assertValidParameterType(element, false));
  }

  if (isRoot && parameter is Map) {
    return parameter
        .forEach((_, value) => _assertValidParameterType(value, false));
  }

  assert(parameter == null ||
      parameter is String ||
      parameter is num ||
      parameter is bool);
}
