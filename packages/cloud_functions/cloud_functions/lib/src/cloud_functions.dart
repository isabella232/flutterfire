// Copyright 2019, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of cloud_functions;

/// The entry point for accessing a CloudFunctions.
///
/// You can get an instance by calling [CloudFunctions.instance].
class CloudFunctions extends FirebasePluginPlatform {
  // Cached and lazily loaded instance of [CloudFunctionsPlatform] to avoid
  // creating a [MethodChannelCloudFunctions] when not needed or creating an
  // instance with the default app before a user specifies an app.
  CloudFunctionsPlatform _delegatePackingProperty;

  CloudFunctionsPlatform get _delegate {
    if (_delegatePackingProperty == null) {
      _delegatePackingProperty =
          CloudFunctionsPlatform.instanceFor(app: app, region: _region);
    }
    return _delegatePackingProperty;
  }

  /// The [FirebaseApp] for this current [FirebaseFirestore] instance.
  final FirebaseApp app;

  CloudFunctions._({this.app, String region})
      : _region = region,
        super(app.name, 'plugins.flutter.io/cloud_functions');

  /// Returns an instance using the default [FirebaseApp].
  static CloudFunctions get instance {
    return CloudFunctions.instanceFor(
      app: Firebase.app(),
    );
  }

  /// Returns an instance using a specified [FirebaseApp] & region.
  static CloudFunctions instanceFor({FirebaseApp app, String region}) {
    app ??= Firebase.app();
    return CloudFunctions._(app: app, region: region);
  }

  // ignore: public_member_api_docs
  @Deprecated(
      "Constructing CloudFunctions is deprecated, use 'CloudFunctions.instance' or 'CloudFunctions.instanceFor' instead")
  factory CloudFunctions({FirebaseApp app, String region}) {
    return CloudFunctions.instanceFor(app: app, region: region);
  }

  final String _region;

  String _origin;

  HttpsCallable httpsCallable(String name, [HttpsCallableOptions options]) {
    assert(name != null);
    assert(name.isNotEmpty);

    options ??= HttpsCallableOptions();

    return HttpsCallable._(_delegate.httpsCallable(name, _origin, options));
  }

  @Deprecated("Deprecated in favor of httpsCallable()")
  // ignore: public_member_api_docs
  HttpsCallable getHttpsCallable({@required String functionName}) {
    return httpsCallable(functionName);
  }

  /// Changes this instance to point to a Cloud Functions emulator running locally.
  ///
  /// Set the [origin] of the local emulator, such as "//10.0.2.2:5005", or `null`
  /// to remove.
  CloudFunctions useFunctionsEmulator({@required String origin}) {
    if (origin != null) {
      assert(origin.isNotEmpty);
    }

    _origin = origin;
    return this;
  }
}
