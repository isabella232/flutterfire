// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import '../../firebase_storage_platform_interface.dart';
import './method_channel_firebase_storage.dart';
import './method_channel_list_result.dart';
import './method_channel_task.dart';
import './utils/exception.dart';

class MethodChannelReference extends ReferencePlatform {
  MethodChannelReference(FirebaseStoragePlatform storage, String path)
      : super(storage, path);

  @override
  Future<void> delete() async {
    await MethodChannelFirebaseStorage.channel
        .invokeMethod('Reference#delete', <String, dynamic>{
      'appName': storage.app.name,
      'bucket': storage.bucket,
      'path': fullPath,
    }).catchError(catchPlatformException);
  }

  @override
  Future<String> getDownloadURL() async {
    Map<String, dynamic> data = await MethodChannelFirebaseStorage.channel
        .invokeMapMethod<String, dynamic>(
            'Reference#getDownloadURL', <String, dynamic>{
      'appName': storage.app.name,
      'bucket': storage.bucket,
      'path': fullPath,
    }).catchError(catchPlatformException);

    return data['downloadURL'];
  }

  @override
  Future<FullMetadata> getMetadata() async {
    Map<String, dynamic> data = await MethodChannelFirebaseStorage.channel
        .invokeMapMethod<String, dynamic>(
            'Reference#getMetadata', <String, dynamic>{
      'appName': storage.app.name,
      'bucket': storage.bucket,
      'path': fullPath,
    }).catchError(catchPlatformException);

    return FullMetadata(data);
  }

  @override
  Future<ListResultPlatform> list(ListOptions options) async {
    Map<String, dynamic> data = await MethodChannelFirebaseStorage.channel
        .invokeMapMethod<String, dynamic>('Reference#list', <String, dynamic>{
      'appName': storage.app.name,
      'bucket': storage.bucket,
      'path': fullPath,
      'options': <String, dynamic>{
        'maxResults': options?.maxResults ?? 1000,
        'pageToken': options?.pageToken,
      },
    }).catchError(catchPlatformException);

    return MethodChannelListResult(
      storage,
      nextPageToken: data['nextPageToken'],
      items: List.from(data['items']),
      prefixes: List.from(data['prefixes']),
    );
  }

  @override
  Future<ListResultPlatform> listAll() async {
    Map<String, dynamic> data = await MethodChannelFirebaseStorage.channel
        .invokeMapMethod<String, dynamic>(
            'Reference#listAll', <String, dynamic>{
      'appName': storage.app.name,
      'bucket': storage.bucket,
      'path': fullPath,
    }).catchError(catchPlatformException);

    return MethodChannelListResult(
      storage,
      nextPageToken: data['nextPageToken'],
      items: List.from(data['items']),
      prefixes: List.from(data['prefixes']),
    );
  }

  @override
  TaskPlatform put(ByteBuffer buffer, [SettableMetadata metadata]) {
    int handle = MethodChannelFirebaseStorage.nextMethodChannelHandleId;
    MethodChannelFirebaseStorage.taskObservers[handle] =
        StreamController<TaskSnapshotPlatform>.broadcast();
    return MethodChannelPutTask(handle, storage, fullPath, buffer, metadata);
  }

  @override
  TaskPlatform putBlob(dynamic data, [SettableMetadata metadata]) {
    throw UnimplementedError(
        'putBlob() is not suport on native platforms. Use [put], [putFile] or [putString] instead.');
  }

  @override
  TaskPlatform putFile(File file, [SettableMetadata metadata]) {
    int handle = MethodChannelFirebaseStorage.nextMethodChannelHandleId;
    MethodChannelFirebaseStorage.taskObservers[handle] =
        StreamController<TaskSnapshotPlatform>.broadcast();
    return MethodChannelPutFileTask(handle, storage, fullPath, file, metadata);
  }

  TaskPlatform putString(String data, PutStringFormat format,
      [SettableMetadata metadata]) {
    int handle = MethodChannelFirebaseStorage.nextMethodChannelHandleId;
    MethodChannelFirebaseStorage.taskObservers[handle] =
        StreamController<TaskSnapshotPlatform>.broadcast();
    return MethodChannelPutStringTask(
        handle, storage, fullPath, data, format, metadata);
  }

  Future<FullMetadata> updateMetadata(SettableMetadata metadata) async {
    Map<String, dynamic> data = await MethodChannelFirebaseStorage.channel
        .invokeMapMethod<String, dynamic>(
            'Reference#updateMetadata', <String, dynamic>{
      'appName': storage.app.name,
      'bucket': storage.bucket,
      'path': fullPath,
      'metadata': metadata.asMap(),
    }).catchError(catchPlatformException);

    return FullMetadata(data);
  }

  TaskPlatform writeToFile(File file) {
    int handle = MethodChannelFirebaseStorage.nextMethodChannelHandleId;
    MethodChannelFirebaseStorage.taskObservers[handle] =
        StreamController<TaskSnapshotPlatform>.broadcast();
    return MethodChannelDownloadTask(handle, storage, fullPath, file);
  }
}