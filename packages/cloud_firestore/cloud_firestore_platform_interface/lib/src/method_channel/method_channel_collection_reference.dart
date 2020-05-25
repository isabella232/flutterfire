// Copyright 2017, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';

import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:cloud_firestore_platform_interface/src/internal/pointer.dart';

import 'method_channel_document_reference.dart';
import 'method_channel_document_reference.dart';
import 'method_channel_query.dart';
import 'method_channel_query.dart';
import 'utils/auto_id_generator.dart';

/// A CollectionReference object can be used for adding documents, getting
/// document references, and querying for documents (using the methods
/// inherited from [QueryPlatform]).
///
/// Note that this class *should* extend [CollectionReferencePlatform], but
/// it doesn't because of the extensive changes required to [MethodChannelQuery]
/// (which *does* extend its Platform class). If you changed
/// [CollectionReferencePlatform] and this class started throwing compilation
/// errors, now you know why.
class MethodChannelCollectionReference extends MethodChannelQuery
    implements CollectionReferencePlatform {
  Pointer _pointer;

  /// Create a [MethodChannelCollectionReference] from [pathComponents]
  MethodChannelCollectionReference(FirestorePlatform firestore, String path)
      : super(firestore, path) {
    _pointer = Pointer(path);
  }

  @override
  String get id => _pointer.id;

  @override
  DocumentReferencePlatform get parent {
    String parentPath = _pointer.parentPath();
    return parentPath == null
        ? null
        : MethodChannelDocumentReference(firestore, parentPath);
  }

  @override
  String get path => _pointer.path;

  @override
  DocumentReferencePlatform document([String path]) {
    String documentPath;

    if (path != null) {
      documentPath = _pointer.documentPath(path);
    } else {
      final String autoId = AutoIdGenerator.autoId();
      documentPath = _pointer.documentPath(autoId);
    }

    return MethodChannelDocumentReference(firestore, documentPath);
  }
}
