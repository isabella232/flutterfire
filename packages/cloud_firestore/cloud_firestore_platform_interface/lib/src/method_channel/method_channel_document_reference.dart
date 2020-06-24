// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';
import 'package:flutter/services.dart';

import 'method_channel_firestore.dart';
import 'utils/source.dart';
import 'utils/exception.dart';

/// An implementation of [DocumentReferencePlatform] that uses [MethodChannel] to
/// communicate with Firebase plugins.
class MethodChannelDocumentReference extends DocumentReferencePlatform {
  Pointer _pointer;

  /// Creates a [DocumentReferencePlatform] that is implemented using [MethodChannel].
  MethodChannelDocumentReference(FirestorePlatform firestore, String path)
      : assert(firestore != null),
        super(firestore, path) {
    _pointer = Pointer(path);
  }

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions options]) {
    return MethodChannelFirestore.channel.invokeMethod<void>(
      'DocumentReference#setData',
      <String, dynamic>{
        'appName': firestore.app.name,
        'path': path,
        'data': data,
        'options': <String, dynamic>{
          'merge': options?.merge,
          'mergeFields': options?.mergeFields,
        },
      },
    ).catchError(catchPlatformException);
  }

  @override
  Future<void> update(Map<String, dynamic> data) {
    return MethodChannelFirestore.channel.invokeMethod<void>(
      'DocumentReference#updateData',
      <String, dynamic>{
        'appName': firestore.app.name,
        'path': path,
        'data': data,
      },
    ).catchError(catchPlatformException);
  }

  @override
  Future<DocumentSnapshotPlatform> get(
      [GetOptions options = const GetOptions()]) async {
    final Map<String, dynamic> data =
        await MethodChannelFirestore.channel.invokeMapMethod<String, dynamic>(
      'DocumentReference#get',
      <String, dynamic>{
        'appName': firestore.app.name,
        'path': path,
        'source': getSourceString(options.source),
      },
    ).catchError(catchPlatformException);

    return DocumentSnapshotPlatform(firestore, _pointer.path, data);
  }

  @override
  Future<void> delete() {
    return MethodChannelFirestore.channel.invokeMethod<void>(
      'DocumentReference#delete',
      <String, dynamic>{'appName': firestore.app.name, 'path': path},
    ).catchError(catchPlatformException);
  }

  @override
  Stream<DocumentSnapshotPlatform> snapshots(
      {bool includeMetadataChanges = false}) {
    assert(includeMetadataChanges != null);
    int handle = MethodChannelFirestore.nextMethodChannelHandleId;

    // It's fine to let the StreamController be garbage collected once all the
    // subscribers have cancelled; this analyzer warning is safe to ignore.
    StreamController<DocumentSnapshotPlatform>
        controller; // ignore: close_sinks
    controller = StreamController<DocumentSnapshotPlatform>.broadcast(
      onListen: () {
        MethodChannelFirestore.documentObservers[handle] = controller;
        MethodChannelFirestore.channel.invokeMethod<void>(
          'DocumentReference#addSnapshotListener',
          <String, dynamic>{
            'handle': handle,
            'appName': firestore.app.name,
            'path': path,
            'includeMetadataChanges': includeMetadataChanges,
          },
        );
      },
      onCancel: () {
        MethodChannelFirestore.documentObservers.remove(handle);
        MethodChannelFirestore.channel.invokeMethod<void>(
          'Firestore#removeListener',
          <String, dynamic>{'handle': handle},
        );
      },
    );
    return controller.stream;
  }
}
