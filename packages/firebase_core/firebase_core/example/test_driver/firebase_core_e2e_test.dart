// Copyright 2020, the Chromium project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  final String resultString =
      await driver.requestData(null, timeout: const Duration(minutes: 1));
  await driver.close();
  final  Map result = json.decode(resultString);
  exit(result['result'] == 'true' ? 0 : 1);
}
