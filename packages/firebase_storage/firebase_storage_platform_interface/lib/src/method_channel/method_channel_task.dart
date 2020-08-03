// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'method_channel_firebase_storage.dart';
import 'utils/exception.dart';

abstract class MethodChannelTask extends TaskPlatform {
  MethodChannelTask(
    this._handle,
    this.storage,
    this._task,
  ) : super() {
    // Create a completer instance.
    _completer = Completer();

    // Catch any errors associated with the initial task call.
    _task.catchError((Object e) {
      _completer.completeError(catchPlatformException(e));
    });

    // Get the task stream.
    _stream = MethodChannelFirebaseStorage.taskObservers[_handle].stream;

    // Listen for stream events
    _stream.listen((TaskSnapshotPlatform snapshot) {
      _lastSnapshot = snapshot;

      // If the stream event is complete, trigger the
      // completer to resolve with the snapshot.
      if (snapshot.state == TaskState.complete) {
        _completer.complete(snapshot);
      }
    });

    // If the stream errors, throw a completer error.
    _stream.handleError(_completer.completeError);
  }

  Completer<TaskSnapshotPlatform> _completer;

  Stream<TaskSnapshotPlatform> _stream;

  Future<void> _task;

  final int _handle;

  final FirebaseStoragePlatform storage;

  TaskSnapshotPlatform _lastSnapshot;

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents {
    return MethodChannelFirebaseStorage.taskObservers[_handle].stream;
  }

  @override
  TaskSnapshotPlatform get snapshot => _lastSnapshot;

  @override
  Future<TaskSnapshotPlatform> get onComplete => _completer.future;

  @override
  Future<void> pause() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod<void>('Task#pause', <String, dynamic>{
      'handle': _handle,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> resume() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod<void>('Task#resume', <String, dynamic>{
      'handle': _handle,
    }).catchError(catchPlatformException);
  }

  @override
  Future<void> cancel() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod<void>('Task#cancel', <String, dynamic>{
      'handle': _handle,
    }).catchError(catchPlatformException);
  }
}

class MethodChannelPutFileTask extends MethodChannelTask {
  MethodChannelPutFileTask(int handle, FirebaseStoragePlatform storage,
      String path, File file, SettableMetadata metadata)
      : super(handle, storage, _getTask(handle, storage, path, file, metadata));

  static Future<void> _getTask(int handle, FirebaseStoragePlatform storage,
      String path, File file, SettableMetadata metadata) {
    return MethodChannelFirebaseStorage.channel
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
      SettableMetadata metadata) {
    return MethodChannelFirebaseStorage.channel
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
      String path, ByteBuffer buffer, SettableMetadata metadata) {
    return MethodChannelFirebaseStorage.channel
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

class MethodChannelDownloadTask extends MethodChannelTask {
  MethodChannelDownloadTask(
      int handle, FirebaseStoragePlatform storage, String path, File file)
      : super(handle, storage, _getTask(handle, storage, path, file));

  static Future<void> _getTask(
      int handle, FirebaseStoragePlatform storage, String path, File file) {
    return MethodChannelFirebaseStorage.channel
        .invokeMethod('Task#writeToFile', <String, dynamic>{
      'appName': storage.app.name,
      'storageBucket': storage.storageBucket,
      'handle': handle,
      'path': path,
      'filePath': file.path,
    });
  }
}
