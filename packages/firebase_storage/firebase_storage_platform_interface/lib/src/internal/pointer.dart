// Copyright 2020 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class Pointer {
  Pointer(String path) {
    if (path == null || path.isEmpty) {
      _path = '/';
    } else {
      String _parsedPath = path;

      // Remove trailing slashes
      if (path.length > 1 && path.endsWith('/')) {
        _parsedPath = _parsedPath.substring(0, _parsedPath.length - 1);
      }

      // Remove starting slashes
      if (path.startsWith('/') && path.length > 1) {
        _parsedPath = _parsedPath.substring(1, _parsedPath.length);
      }

      _path = _parsedPath;
    }
  }

  String _path;

  bool get isRoot {
    return path == '/';
  }

  String get path {
    return _path;
  }

  String get name {
    return path.split('/').last;
  }

  String get parent {
    if (isRoot) {
      return null;
    }

    List<String> chunks = path.split('/');
    chunks.removeLast();
    return chunks.join('/');
  }

  String child(String childPath) {
    assert(childPath != null);
    Pointer childPointer = Pointer(childPath);

    // If already at
    if (isRoot) {
      return childPointer.path;
    }

    return '$path/${childPointer.path}';
  }
}
