// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: public_member_api_docs

@JS('firebase.messaging')
library firebase_interop.messaging;

import 'package:js/js.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart';

@JS('isSupported')
external bool isSupported();

@JS('Messaging')
abstract class MessagingJsImpl {
  external void usePublicVapidKey(String key);
  external PromiseJsImpl<void> requestPermission();
  external PromiseJsImpl<String> getToken();
  external void Function() onMessage(
    optionsOrObserverOrOnNext,
    observerOrOnNextOrOnError,
  );
  external void Function() onTokenRefresh(
    optionsOrObserverOrOnNext,
    observerOrOnNextOrOnError,
  );
  external void setBackgroundMessageHandler(Func1 f);
  external void useServiceWorker(registration);
  external void deleteToken(String token);
}

@JS()
@anonymous
abstract class NotificationJsImpl {
  external String get title;
  external String get body;
  // ignore: non_constant_identifier_names
  external String get click_action;
  external String get icon;
}

@JS()
@anonymous
abstract class PayloadJsImpl {
  // ignore: non_constant_identifier_names
  external String get collapse_key;
  external String get from;
  external NotificationJsImpl get notification;
  external dynamic /*Map<String, String>*/ get data;
}
