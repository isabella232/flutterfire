// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase/firebase.dart' as firebase;

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

  firebase.FirebaseError firebaseError = exception as firebase.FirebaseError;

  String code = firebaseError.code.replaceFirst('functions/', '');
  String message =
      firebaseError.message.replaceFirst('(${firebaseError.code})', '');

  // TODO(ehesp): firebase-dart does not provide `details` from HTTP errors.
  return FirebaseFunctionsException(
      code: code, message: message, stackTrace: stackTrace, details: firebaseError.serverResponse);
}
