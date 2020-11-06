// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

/// Web implementation for [FirebaseMessagingPlatform]
/// delegates calls to messaging web plugin.
class FirebaseMessagingWeb extends FirebaseMessagingPlatform {
  /// Called by PluginRegistry to register this plugin for Flutter Web
  static void registerWith(Registrar registrar) {
    FirebaseMessagingPlatform.instance = FirebaseMessagingWeb();
  }

  /// Builds an instance of [FirebaseFirestoreWeb] with an optional [FirebaseApp] instance
  /// If [app] is null then the created instance will use the default [FirebaseApp]
  FirebaseMessagingWeb({FirebaseApp app}) : super(appInstance: app);

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
    // Not required on web, but prevents UnimplementedError being thrown
    return this;
  }

  @override
  bool get isAutoInitEnabled {
    // TODO(ehesp): should this be true or false?
    return true;
  }

  @override
  Future<RemoteMessage> getInitialMessage() {
    return null;
  }

  @override
  Future<void> deleteToken({String senderId}) {
    return null;
  }

  @override
  Future<String> getAPNSToken() {
    return null;
  }

  @override
  Future<String> getToken({String senderId, String vapidKey}) async {
    return 'todo';
  }

  @override
  Stream<String> get onTokenRefresh {
    return null;
  }

  @override
  Future<NotificationSettings> getNotificationSettings() {
    return null;
  }

  @override
  Future<NotificationSettings> requestPermission(
      {bool alert = true,
      bool announcement = false,
      bool badge = true,
      bool carPlay = false,
      bool criticalAlert = false,
      bool provisional = false,
      bool sound = true}) {
    return null;
  }

  @override
  Future<void> setAutoInitEnabled(bool enabled) {
    return null;
  }

  @override
  Future<void> setForegroundNotificationPresentationOptions(
      {bool alert, bool badge, bool sound}) {
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
