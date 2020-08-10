// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';
import 'method_channel_firebase_storage.dart';
import 'utils/exception.dart';

/// Implementation for a [TaskPlatform].
///
/// Other implementations for specific tasks should extend this class.
abstract class MethodChannelTask extends TaskPlatform {
  /// Creates a new [MethodChannelTask] with a given task.
  MethodChannelTask(
    this._handle,
    this.storage,
    this._initialTask,
  ) : super() {
    // Keep reference to whether the initial "start" task has completed.
    _initialTaskCompleter = Completer<void>();

    // Once complete, set the completer.
    _initialTask.then((value) => _initialTaskCompleter.complete());

    // Catch any errors associated with the initial task call.
    _initialTask.catchError((Object e) {
      _initialTaskCompleter.completeError(e);
      _didComplete = true;
      _exception = e;
      catchPlatformException(e).catchError(_completer?.completeError);
    });

    // Get the task stream.
    _stream = MethodChannelFirebaseStorage.taskObservers[_handle].stream;
    StreamSubscription _subscription;

    // Listen for stream events.
    _subscription = _stream.listen((TaskSnapshotPlatform snapshot) async {
      _lastSnapshot = snapshot;

      // If the stream event is complete, trigger the
      // completer to resolve with the snapshot.
      if (snapshot.state == TaskState.complete) {
        _didComplete = true;
        _completer?.complete(snapshot);
        await _subscription.cancel();
      }
    }, onError: (Object e) {
      _didComplete = true;
      _exception = e;
      catchPlatformException(e).catchError(_completer?.completeError);
    }, cancelOnError: true);
  }

  Object _exception;

  bool _didComplete = false;

  Completer<TaskSnapshotPlatform> _completer;

  Stream<TaskSnapshotPlatform> _stream;

  Completer<void> _initialTaskCompleter;

  Future<void> _initialTask;

  final int _handle;

  /// The [FirebaseStoragePlatform] used to create the task.
  final FirebaseStoragePlatform storage;

  TaskSnapshotPlatform _lastSnapshot;

  @override
  Stream<TaskSnapshotPlatform> get snapshotEvents {
    return MethodChannelFirebaseStorage.taskObservers[_handle].stream;
  }

  @override
  TaskSnapshotPlatform get snapshot => _lastSnapshot;

  @override
  Future<TaskSnapshotPlatform> get onComplete async {
    if (_didComplete && _exception == null) {
      return Future.value(snapshot);
    } else if (_didComplete && _exception != null) {
      return catchPlatformException(_exception);
    } else {
      if (_completer == null) {
        _completer = Completer<TaskSnapshotPlatform>();
      }

      return _completer.future;
    }
  }

  @override
  Future<bool> pause() async {
    try {
      if (!_initialTaskCompleter.isCompleted) {
        await _initialTaskCompleter.future;
      }

      Map<String, dynamic> data = await MethodChannelFirebaseStorage.channel
          .invokeMapMethod<String, dynamic>('Task#pause', <String, dynamic>{
        'handle': _handle,
      }).catchError(catchPlatformException);

      return data['status'];
    } catch (e) {
      return catchPlatformException(e);
    }
  }

  @override
  Future<bool> resume() async {
    try {
      if (!_initialTaskCompleter.isCompleted) {
        await _initialTaskCompleter.future;
      }

      Map<String, dynamic> data = await MethodChannelFirebaseStorage.channel
          .invokeMapMethod<String, dynamic>('Task#resume', <String, dynamic>{
        'handle': _handle,
      });

      return data['status'];
    } catch (e) {
      return catchPlatformException(e);
    }
  }

  @override
  Future<bool> cancel() async {
    try {
      if (!_initialTaskCompleter.isCompleted) {
        await _initialTaskCompleter.future;
      }

      Map<String, dynamic> data = await MethodChannelFirebaseStorage.channel
          .invokeMapMethod<String, dynamic>('Task#cancel', <String, dynamic>{
        'handle': _handle,
      });

      return data['status'];
    } catch (e) {
      return catchPlatformException(e);
    }
  }
}

/// Implementation for [putFile] tasks.
class MethodChannelPutFileTask extends MethodChannelTask {
  // ignore: public_member_api_docs
  MethodChannelPutFileTask(int handle, FirebaseStoragePlatform storage,
      String path, File file, SettableMetadata metadata)
      : super(handle, storage, _getTask(handle, storage, path, file, metadata));

  static Future<void> _getTask(int handle, FirebaseStoragePlatform storage,
      String path, File file, SettableMetadata metadata) {
    return MethodChannelFirebaseStorage.channel
        .invokeMethod('Task#startPutFile', <String, dynamic>{
      'appName': storage.app.name,
      'bucket': storage.bucket,
      'handle': handle,
      'path': path,
      'filePath': file.absolute.path,
      'metadata': metadata?.asMap(),
    });
  }
}

/// Implementation for [putString] tasks.
class MethodChannelPutStringTask extends MethodChannelTask {
  // ignore: public_member_api_docs
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
      'bucket': storage.bucket,
      'handle': handle,
      'path': path,
      'data': data,
      'format': format.toString(),
      'metadata': metadata?.asMap(),
    });
  }
}

/// Implementation for [put] tasks.
class MethodChannelPutTask extends MethodChannelTask {
  // ignore: public_member_api_docs
  MethodChannelPutTask(int handle, FirebaseStoragePlatform storage, String path,
      ByteBuffer buffer, SettableMetadata metadata)
      : super(
            handle, storage, _getTask(handle, storage, path, buffer, metadata));

  static Future<void> _getTask(int handle, FirebaseStoragePlatform storage,
      String path, ByteBuffer buffer, SettableMetadata metadata) {
    return MethodChannelFirebaseStorage.channel
        .invokeMethod('Task#startPut', <String, dynamic>{
      'appName': storage.app.name,
      'bucket': storage.bucket,
      'handle': handle,
      'path': path,
      'data': buffer.asUint8List(),
      'metadata': metadata?.asMap(),
    });
  }
}

/// Implementation for [writeToFile] tasks.
class MethodChannelDownloadTask extends MethodChannelTask {
  // ignore: public_member_api_docs
  MethodChannelDownloadTask(
      int handle, FirebaseStoragePlatform storage, String path, File file)
      : super(handle, storage, _getTask(handle, storage, path, file));

  static Future<void> _getTask(
      int handle, FirebaseStoragePlatform storage, String path, File file) {
    return MethodChannelFirebaseStorage.channel
        .invokeMethod('Task#writeToFile', <String, dynamic>{
      'appName': storage.app.name,
      'bucket': storage.bucket,
      'handle': handle,
      'path': path,
      'filePath': file.path,
    });
  }
}
