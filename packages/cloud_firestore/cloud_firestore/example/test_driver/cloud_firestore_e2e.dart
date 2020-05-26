// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:e2e/e2e.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';

import 'document_reference_e2e.dart';

void main() {
  E2EWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FirebaseCore.instance.initializeApp();
  });

  runDocumentReferenceTests();
}
