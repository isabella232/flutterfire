// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_functions;

class CloudFunctionsException implements Exception {
  CloudFunctionsException._(this.code, this.message, this.details);

  final String code;
  final String message;
  final dynamic details;
}

/// The entry point for accessing a CloudFunctions.
///
/// You can get an instance by calling [CloudFunctions.instance].
class CloudFunctions extends FirebasePluginPlatform {
  // Cached and lazily loaded instance of [FirestorePlatform] to avoid
  // creating a [MethodChannelFirestore] when not needed or creating an
  // instance with the default app before a user specifies an app.
  CloudFunctionsPlatform _delegatePackingProperty;

  CloudFunctionsPlatform get _delegate {
    if (_delegatePackingProperty == null) {
      _delegatePackingProperty =
          CloudFunctionsPlatform.instanceFor(app: app, region: _region);
    }
    return _delegatePackingProperty;
  }

  /// The [FirebaseApp] for this current [CloudFunctions] instance.
  FirebaseApp app;

  String _region;

  String _origin;

  CloudFunctions._({this.app, String region})
      : _region = region,
        super(app.name, 'plugins.flutter.io/cloud_functions');

  @Deprecated(
      "Constructing Storage is deprecated, use 'CloudFunctions.instance' or 'CloudFunctions.instanceFor' instead")
  factory CloudFunctions({FirebaseApp app, String region}) {
    return CloudFunctions.instanceFor(app: app, region: region);
  }

  static CloudFunctions get instance {
    return CloudFunctions.instanceFor(
      app: Firebase.app(),
    );
  }

  static CloudFunctions instanceFor({
    FirebaseApp app,
    String region,
  }) {
    app ??= Firebase.app();
    return CloudFunctions._(app: app, region: region);
  }

  /// Gets an instance of a Callable HTTPS trigger in Cloud Functions.
  ///
  /// Can then be executed by calling `call()` on it.
  ///
  /// @param functionName The name of the callable function.
  HttpsCallable getHttpsCallable({@required String functionName}) {
    return HttpsCallable._(this, functionName);
  }

  /// Changes this instance to point to a Cloud Functions emulator running locally.
  ///
  /// @param origin The origin of the local emulator, such as "//10.0.2.2:5005".
  CloudFunctions useFunctionsEmulator({@required String origin}) {
    _origin = origin;
    return this;
  }
}
