// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase/firebase.dart' as firebase;
import 'package:firebase/src/interop/functions_interop.dart'
    show HttpsErrorJsImpl;

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
  HttpsErrorJsImpl firebaseError = exception as HttpsErrorJsImpl;

  String code = firebaseError.code.replaceFirst('functions/', '');
  String message =
      firebaseError.message.replaceFirst('(${firebaseError.code})', '');

  return FirebaseFunctionsException(
      code: code,
      message: message,
      stackTrace: stackTrace,
      details: firebaseError.details);
}
