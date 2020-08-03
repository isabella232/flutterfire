// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'method_channel_firebase_storage.dart';
import './utils/exception.dart';

class MethodChannelTask extends TaskPlatform {
  MethodChannelTask(
    this.handle,
    this.storage,
    this.task,
  ) : super() {
    _stream = MethodChannelFirebaseStorage.taskObservers[handle].stream;

    _stream.listen((TaskSnapshotPlatform snapshot) {
      _lastSnapshot = snapshot;
    });
  }

  Stream<TaskSnapshotPlatform> _stream;

  final int handle;

  final FirebaseStoragePlatform storage;

  Future<void> task;

  TaskSnapshotPlatform _lastSnapshot;

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents {
    return MethodChannelFirebaseStorage.taskObservers[handle].stream;
  }

  @override
  TaskSnapshotPlatform get snapshot => _lastSnapshot;

  @override
  Future<TaskSnapshotPlatform> get onComplete {
    return task.then(($) => snapshot).catchError(catchPlatformException);
  }

  @override
  Future<void> pause() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod<void>('Task#pause', <String, dynamic>{
      'handle': handle,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> resume() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod<void>('Task#resume', <String, dynamic>{
      'handle': handle,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> cancel() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod<void>('Task#cancel', <String, dynamic>{
      'handle': handle,
    }).catchError(catchPlatformException);
  }
}

class MethodChannelPutFileTask extends MethodChannelTask {
  MethodChannelPutFileTask(int handle, FirebaseStoragePlatform storage,
      String path, File file, SettableMetadata metadata)
      : super(handle, storage, _getTask(handle, storage, path, file, metadata));

  static Future<void> _getTask(int handle, FirebaseStoragePlatform storage,
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

  static Future<void> _getTask(
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
  }
}

class MethodChannelPutTask extends MethodChannelTask {
  MethodChannelPutTask(int handle, FirebaseStoragePlatform storage, String path,
      ByteBuffer buffer, SettableMetadata metadata)
      : super(
            handle, storage, _getTask(handle, storage, path, buffer, metadata));

  static Future<void> _getTask(int handle, FirebaseStoragePlatform storage,
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
  }
}
