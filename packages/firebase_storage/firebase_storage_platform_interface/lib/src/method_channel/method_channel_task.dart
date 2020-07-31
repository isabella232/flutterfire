// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import '../../firebase_storage_platform_interface.dart';
import '../../firebase_storage_platform_interface.dart';
import '../../firebase_storage_platform_interface.dart';
import '../../firebase_storage_platform_interface.dart';
import '../../firebase_storage_platform_interface.dart';
import '../../firebase_storage_platform_interface.dart';
import 'method_channel_firebase_storage.dart';

class MethodChannelTask extends TaskPlatform {
  MethodChannelTask(
    this.handle,
    this.storage,
    this.task,
  ) : super();

  final int handle;

  final FirebaseStoragePlatform storage;

  Future<dynamic> task;

  bool _isCanceled = false;
  bool _isComplete = false;
  bool _isInProgress = true;
  bool _isPaused = false;
  bool _isSuccessful = false;
  dynamic _lastSnapshot;

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents {
    return MethodChannelFirebaseStorage.taskObservers[handle].stream;
  }

  @override
  bool get isCanceled => _isCanceled;

  @override
  bool get isComplete => _isComplete;

  @override
  bool get isInProgress => _isInProgress;

  @override
  bool get isPaused => _isPaused;

  @override
  bool get isSuccessful => _isSuccessful;

  @override
  dynamic get lastSnapshot => _lastSnapshot;

  @override
  Future get onComplete {
    return task;
  }

  @override
  Future<void> pause() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod<void>('Task#pause', <String, dynamic>{
      'handle': handle,
    });

    _isPaused = true;
    _isInProgress = false;
  }

  @override
  Future<void> resume() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod<void>('Task#resume', <String, dynamic>{
      'handle': handle,
    });

    _isPaused = false;
    _isInProgress = true;
  }

  @override
  Future<void> cancel() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod<void>('Task#cancel', <String, dynamic>{
      'handle': handle,
    });

    _isCanceled = true;
  }
}

class MethodChannelPutFileTask extends MethodChannelTask {
  MethodChannelPutFileTask(int handle, FirebaseStoragePlatform storage,
      String path, File file, SettableMetadata metadata)
      : super(handle, storage, _getTask(handle, storage, path, file, metadata));

  static Future<dynamic> _getTask(int handle, FirebaseStoragePlatform storage,
      String path, File file, SettableMetadata metadata) async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod('Task#startPutFile', <String, dynamic>{
      'appName': storage.app.name,
      'storageBucket': storage.storageBucket,
      'handle': handle,
      'path': path,
      'filePath': file.path,
      'metadata': metadata?.asMap(),
    });

    return null;
  }
}

class MethodChannelPutStringTask extends MethodChannelTask {
  MethodChannelPutStringTask(
      int handle,
      FirebaseStoragePlatform storage,
      String path,
      String data,
      PutStringFormat format,
      SettableMetadata metadata)
      : super(handle, storage,
            _getTask(handle, storage, path, data, format, metadata));

  static Future<dynamic> _getTask(
      int handle,
      FirebaseStoragePlatform storage,
      String path,
      String data,
      PutStringFormat format,
      SettableMetadata metadata) async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod('Task#startPutString', <String, dynamic>{
      'appName': storage.app.name,
      'storageBucket': storage.storageBucket,
      'handle': handle,
      'path': path,
      'data': data,
      'format': format.toString(),
      'metadata': metadata?.asMap(),
    });

    return null;
  }
}

class MethodChannelPutTask extends MethodChannelTask {
  MethodChannelPutTask(int handle, FirebaseStoragePlatform storage, String path,
      ByteBuffer buffer, SettableMetadata metadata)
      : super(
            handle, storage, _getTask(handle, storage, path, buffer, metadata));

  static Future<dynamic> _getTask(int handle, FirebaseStoragePlatform storage,
      String path, ByteBuffer buffer, SettableMetadata metadata) async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod('Task#startPut', <String, dynamic>{
      'appName': storage.app.name,
      'storageBucket': storage.storageBucket,
      'handle': handle,
      'path': path,
      'data': buffer.asUint8List(),
      'metadata': metadata?.asMap(),
    });

    return null;
  }
}
