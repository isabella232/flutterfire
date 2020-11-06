// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:firebase_core_web/firebase_core_web_interop.dart';

import 'window_interop.dart' as window_interop;
import 'notification_interop.dart' as notification_interop;

Notification getWindowNotification() {
  return Notification.getInstance(window_interop.notification);
}

class Notification
    extends JsObjectWrapper<notification_interop.NotificationJsImpl> {
  static final _expando = Expando<Notification>();

  static Notification getInstance(
      notification_interop.NotificationJsImpl jsObject) {
    if (jsObject == null) {
      return null;
    }
    return _expando[jsObject] ??= Notification._fromJsObject(jsObject);
  }

  Notification._fromJsObject(notification_interop.NotificationJsImpl jsObject)
      : super.fromJsObject(jsObject);

  String get permission {
    return jsObject.permission;
  }

  Future<String> requestPermission() {
    return handleThenable(jsObject.requestPermission());
  }

  Future<void> close() {
    return handleThenable(jsObject.close());
  }
}
