// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart'
    as core_interop;

import 'src/interop/messaging.dart' as messaging_interop;
import 'src/interop/notification.dart' as notification_interop;
import 'src/utils.dart' as utils;

/// Web implementation for [FirebaseMessagingPlatform]
/// delegates calls to messaging web plugin.
class FirebaseMessagingWeb extends FirebaseMessagingPlatform {
  /// Instance of Messaging from the web plugin
  final messaging_interop.Messaging _webMessaging;

  // Instance of window.Notification
  final notification_interop.Notification _webNotification;

  /// Called by PluginRegistry to register this plugin for Flutter Web
  static void registerWith(Registrar registrar) {
    FirebaseMessagingPlatform.instance = FirebaseMessagingWeb();
  }

  Stream<String> _noopOnTokenRefreshStream;

  /// Builds an instance of [FirebaseFirestoreWeb] with an optional [FirebaseApp] instance
  /// If [app] is null then the created instance will use the default [FirebaseApp]
  FirebaseMessagingWeb({FirebaseApp app})
      : _webMessaging =
            messaging_interop.getMessagingInstance(core_interop.app(app?.name)),
        _webNotification = notification_interop.getWindowNotification(),
        super(appInstance: app);

  @override
  void registerBackgroundMessageHandler(handler) {
    // TODO(ehesp): check if needs setting
  }

  @override
  FirebaseMessagingPlatform delegateFor({FirebaseApp app}) {
    return FirebaseMessagingWeb(app: app);
  }

  @override
  FirebaseMessagingPlatform setInitialValues({bool isAutoInitEnabled}) {
    // Not required on web, but prevents UnimplementedError being thrown.
    return this;
  }

  @override
  bool get isAutoInitEnabled {
    // Not supported on web, since it automatically initializes when imported
    // via the script. So return `true`.
    return true;
  }

  @override
  Future<RemoteMessage> getInitialMessage() {
    return null;
  }

  @override
  Future<void> deleteToken({String senderId}) async {
    try {
      await _webMessaging.deleteToken();
    } catch (e) {
      throw utils.getFirebaseException(e);
    }
  }

  @override
  Future<String> getAPNSToken() async {
    return null;
  }

  @override
  Future<String> getToken({String senderId, String vapidKey}) async {
    try {
      return await _webMessaging.getToken(vapidKey: vapidKey);
    } catch (e) {
      throw utils.getFirebaseException(e);
    }
  }

  @override
  Stream<String> get onTokenRefresh {
    // onTokenRefresh is deprecated on web, however since this is a non-critical
    // api we just return a noop stream to keep functionality the same across
    // platforms.
    return _noopOnTokenRefreshStream ??=
        StreamController<String>.broadcast().stream;
  }

  @override
  Future<NotificationSettings> getNotificationSettings() async {
    return utils.getNotificationSettings(_webNotification.permission);
  }

  @override
  Future<NotificationSettings> requestPermission(
      {bool alert = true,
      bool announcement = false,
      bool badge = true,
      bool carPlay = false,
      bool criticalAlert = false,
      bool provisional = false,
      bool sound = true}) async {
    try {
      String status = await _webNotification.requestPermission();
      return utils.getNotificationSettings(status);
    } catch (e) {
      throw utils.getFirebaseException(e);
    }
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) async {
    // Noop out on web - not supported but no need to crash
    return;
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions(
      {bool alert, bool badge, bool sound}) async {
    return null;
  }

  @override
  Future<void> subscribeToTopic(String topic) {
    throw UnimplementedError('''
      subscribeToTopic() is not supported on the web clients.

      To learn how to manage subscriptions for web users, visit the 
      official Firebase documentation:

      https://firebase.google.com/docs/cloud-messaging/js/topic-messaging
    ''');
  }

  @override
  Future<void> unsubscribeFromTopic(String topic) {
    throw UnimplementedError('''
      unsubscribeFromTopic() is not supported on the web clients.

      To learn how to manage subscriptions for web users, visit the 
      official Firebase documentation:

      https://firebase.google.com/docs/cloud-messaging/js/topic-messaging
    ''');
  }
}
