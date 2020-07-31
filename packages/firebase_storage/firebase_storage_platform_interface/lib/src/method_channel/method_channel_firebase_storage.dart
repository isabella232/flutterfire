// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';

import './method_channel_reference.dart';
import './method_channel_task_snapshot.dart';
import './utils/exception.dart';

/// Method Channel delegate for [FirebaseStoragePlatform].
class MethodChannelFirebaseStorage extends FirebaseStoragePlatform {
  /// Keep an internal reference to whether the [MethodChannelFirebaseStorage]
  /// class has already been initialized.
  static bool _initialized = false;

  /// Returns a unique key to identify the instance by [FirebaseApp] name and
  /// any custom storage buckets.
  static String _getInstanceKey(String appName, String storageBucket) {
    return '${appName}|${storageBucket ?? ''}';
  }

  /// The [MethodChannelFirebaseAuth] method channel.
  static const MethodChannel channel = MethodChannel(
    'plugins.flutter.io/firebase_storage',
  );

  static Map<String, MethodChannelFirebaseStorage>
      _methodChannelFirebaseStorageInstances =
      <String, MethodChannelFirebaseStorage>{};

  /// Returns a stub instance to allow the platform interface to access
  /// the class instance statically.
  static MethodChannelFirebaseStorage get instance {
    return MethodChannelFirebaseStorage._();
  }

  static int _methodChannelHandleId = 0;

  /// Increments and returns the next channel ID handler for Firestore.
  static int get nextMethodChannelHandleId => _methodChannelHandleId++;

  /// A map containing all Task stream observers, keyed by their handle.
  static final Map<int, StreamController<dynamic>> taskObservers =
      <int, StreamController<TaskSnapshotPlatform>>{};

  /// Internal stub class initializer.
  ///
  /// When the user code calls an storage method, the real instance is
  /// then initialized via the [delegateFor] method.
  MethodChannelFirebaseStorage._() : super(appInstance: null);

  MethodChannelFirebaseStorage({FirebaseApp app, String storageBucket})
      : super(appInstance: app, storageBucket: storageBucket) {
    // The channel setMethodCallHandler callback is not app specific, so there
    // is no need to register the caller more than once.
    if (_initialized) return;

    channel.setMethodCallHandler((MethodCall call) async {
      Map<dynamic, dynamic> arguments = call.arguments;

      switch (call.method) {
        case 'Task#stateChange':
          return _handleTaskStateChange(arguments);
      }
    });

    _initialized = true;
  }

  Future<void> _handleTaskStateChange(Map<dynamic, dynamic> arguments) async {
    // Get & cast native snapshot data to a Map
    Map<String, dynamic> snapshotData =
        Map<String, dynamic>.from(arguments['snapshot']);

    // Get the cached Storage instance.
    FirebaseStoragePlatform storage = _methodChannelFirebaseStorageInstances[
        _getInstanceKey(arguments['appName'], arguments['storageBucket'])];

    // Create a snapshot.
    TaskSnapshotPlatform snapshot =
        MethodChannelTaskSnapshot(storage, arguments['path'], snapshotData);

    // Fire a snapshot event.
    taskObservers[arguments['handle']].add(snapshot);
  }

  @override
  FirebaseStoragePlatform delegateFor({FirebaseApp app, String storageBucket}) {
    String key = _getInstanceKey(app.name, storageBucket);

    if (!_methodChannelFirebaseStorageInstances.containsKey(key)) {
      _methodChannelFirebaseStorageInstances[key] =
          MethodChannelFirebaseStorage(app: app, storageBucket: storageBucket);
    }

    return _methodChannelFirebaseStorageInstances[key];
  }

  @override
  ReferencePlatform ref(String path) {
    return MethodChannelReference(this, path);
  }

  @override
  Future<void> setMaxOperationRetryTime(int time) async {
    await channel
        .invokeMethod('Storage#setMaxOperationRetryTime', <String, dynamic>{
      'appName': app.name,
      'storageBucket': storageBucket,
      'time': time,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> setMaxUploadRetryTime(int time) async {
    await channel
        .invokeMethod('Storage#setMaxUploadRetryTime', <String, dynamic>{
      'appName': app.name,
      'storageBucket': storageBucket,
      'time': time,
    }).catchError(catchPlatformException);
  }
}
