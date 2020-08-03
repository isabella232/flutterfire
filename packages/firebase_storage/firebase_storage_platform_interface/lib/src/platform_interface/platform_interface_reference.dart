// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart';

import '../../firebase_storage_platform_interface.dart';
import '../../firebase_storage_platform_interface.dart';
import '../internal/pointer.dart';

abstract class ReferencePlatform extends PlatformInterface {
  ReferencePlatform(this.storage, String path)
      : _pointer = Pointer(path),
        super(token: _token);

  Pointer _pointer;

  static final Object _token = Object();

  /// Throws an [AssertionError] if [instance] does not extend
  /// [ReferencePlatform].
  ///
  /// This is used by the app-facing [Reference] to ensure that
  /// the object in which it's going to delegate calls has been
  /// constructed properly.
  static verifyExtends(ReferencePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
  }

  final FirebaseStoragePlatform storage;

  String get bucket {
    return '';
  }

  String get fullPath => _pointer.path;

  String get name => _pointer.name;

  ReferencePlatform get parent {
    String parentPath = _pointer.parent;

    if (parentPath == null) {
      return null;
    }

    return storage.ref(parentPath);
  }

  ReferencePlatform get root {
    return storage.ref('/');
  }

  ReferencePlatform child(String path) {
    return storage.ref(_pointer.child(path));
  }

  Future<void> delete() {
    throw UnimplementedError('delete() is not implemented');
  }

  Future<String> getDownloadURL() {
    throw UnimplementedError('getDownloadURL() is not implemented');
  }

  Future<FullMetadata> getMetadata() {
    throw UnimplementedError('getMetadata() is not implemented');
  }

  Future<ListResultPlatform> list(ListOptions options) {
    throw UnimplementedError('list() is not implemented');
  }

  Future<ListResultPlatform> listAll() {
    throw UnimplementedError('listAll() is not implemented');
  }

  TaskPlatform put(ByteBuffer buffer, [SettableMetadata metadata]) {
    throw UnimplementedError('put() is not implemented');
  }

  TaskPlatform putBlob(dynamic data, [SettableMetadata metadata]) {
    throw UnimplementedError('putBlob() is not implemented');
  }

  TaskPlatform putFile(File file, [SettableMetadata metadata]) {
    throw UnimplementedError('putFile() is not implemented');
  }

  TaskPlatform putString(String data, PutStringFormat format, [SettableMetadata metadata]) {
    throw UnimplementedError('putString() is not implemented');
  }

  Future<FullMetadata> updateMetadata(SettableMetadata metadata) {
    throw UnimplementedError('updateMetadata() is not implemented');
  }


  TaskPlatform writeToFile(File file) {
    throw UnimplementedError('writeToFile() is not implemented');
  }
}
