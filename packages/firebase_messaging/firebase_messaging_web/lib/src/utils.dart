// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web_interop.dart'
    as core_interop;
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';

import 'interop/messaging.dart';

/// Returns a [FirebaseException] from a thrown web error.
FirebaseException getFirebaseException(Object object) {
  if (object is! core_interop.FirebaseError) {
    return FirebaseException(
        plugin: 'firebase_messaging',
        code: 'unknown',
        message: object.toString());
  }

  core_interop.FirebaseError firebaseError =
      object as core_interop.FirebaseError;

  String code = firebaseError.code.replaceFirst('messaging/', '');
  String message =
      firebaseError.message.replaceFirst('(${firebaseError.code})', '');
  return FirebaseException(
      plugin: 'firebase_messaging', code: code, message: message);
}

/// Converts an [String] into it's [AuthorizationStatus] representation.
///
/// See https://developer.mozilla.org/en-US/docs/Web/API/Notification/requestPermission
/// for more information.
AuthorizationStatus convertToAuthorizationStatus(String status) {
  switch (status) {
    case 'granted':
      return AuthorizationStatus.authorized;
    case 'denied':
      return AuthorizationStatus.denied;
    case 'default':
      return AuthorizationStatus.notDetermined;
    default:
      return AuthorizationStatus.notDetermined;
  }
}

/// Returns a [NotificationSettings] instance for all Web platforms devices.
NotificationSettings getNotificationSettings(String status) {
  return NotificationSettings(
    authorizationStatus: convertToAuthorizationStatus(status),
    alert: AppleNotificationSetting.notSupported,
    announcement: AppleNotificationSetting.notSupported,
    badge: AppleNotificationSetting.notSupported,
    carPlay: AppleNotificationSetting.notSupported,
    lockScreen: AppleNotificationSetting.notSupported,
    notificationCenter: AppleNotificationSetting.notSupported,
    showPreviews: AppleShowPreviewSetting.notSupported,
    sound: AppleNotificationSetting.notSupported,
  );
}

/// Converts a messaging [MessagePayload] into a Map.
Map<String, dynamic> messagePayloadToMap(MessagePayload messagePayload) {
  
  // TODO(ehesp): Data from FCM comes through like so:
  // gcm.n.e: "1"
  // google.c.a.c_id: "7839537754298966003"
  // google.c.a.e: "1"
  // google.c.a.ts: "1604755155"
  // google.c.a.udt: "0"
  // Since senderId & messageId are null, can we reliably assume these are
  // the values? Should we remove them from the data payload?

  return <String, dynamic>{
    'senderId': null,
    'category': null,
    'collapseKey': messagePayload.collapseKey,
    'contentAvailable': null,
    'data': messagePayload.data,
    'from': messagePayload.from,
    'messageId': null,
    'mutableContent': null,
    'notification': messagePayload.notification == null
        ? null
        : notificationPayloadToMap(
            messagePayload.notification, messagePayload.fcmOptions),
    'sentTime': null,
    'threadId': null,
    'ttl': null,
  };
}

/// Converts a messaging [NotificationPayload] into a Map.
///
/// Since [FcmOptions] are web specific, we pass these down to the upper layer
/// as web properties.
Map<String, dynamic> notificationPayloadToMap(
    NotificationPayload notificationPayload, FcmOptions fcmOptions) {
  return <String, dynamic>{
    'title': notificationPayload.title,
    'body': notificationPayload.body,
    'web': <String, dynamic>{
      'image': notificationPayload.image,
      'analyticsLabel': fcmOptions?.analyticsLabel,
      'link': fcmOptions?.link,
    },
  };
}
