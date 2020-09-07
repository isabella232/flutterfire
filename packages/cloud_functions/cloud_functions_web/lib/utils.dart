// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase/firebase.dart' as firebase;



abstract class HttpsError extends firebase.FirebaseError {
  external Object get details;
}

/// Given a web error, a [FirebaseFunctionsException] is returned.
///
/// The firebase-dart wrapper exposes a [firebase.FirebaseError], allowing us to
/// use the code and message and convert it into an expected [FirebaseFunctionsException].
///
FirebaseFunctionsException throwFirebaseAuthException(Object exception,
    [StackTrace stackTrace]) {
  if (exception is! firebase.FirebaseError) {
    return FirebaseFunctionsException(
        code: 'unknown', message: exception, stackTrace: stackTrace);
  }
  HttpsError firebaseError = exception as HttpsError;

  String code = firebaseError.code.replaceFirst('functions/', '');
  String message =
      firebaseError.message.replaceFirst('(${firebaseError.code})', '');

  // TODO(ehesp): firebase-dart does not provide `details` from HTTP errors.
  return FirebaseFunctionsException(
      code: code, message: message, stackTrace: stackTrace, details: firebaseError.details);
}
