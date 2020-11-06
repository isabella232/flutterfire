// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs

@JS('window')
library firebase_interop.messaging;

import 'package:firebase_core_web/firebase_core_web_interop.dart';
import 'package:js/js.dart';

@JS('Notification')
abstract class NotificationJsImpl {
  external String get permission;
  external PromiseJsImpl<String> requestPermission();
  external PromiseJsImpl<Null> close();
}
