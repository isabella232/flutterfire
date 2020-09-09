import 'dart:io';

import 'package:firebase_core/firebase_core.dart';

final String kTestString = 'Hello world';
final String kTestStorageBucket = 'react-native-firebase-testing.appspot.com';

// create file
Future<File> createFile(name) async {
  final Directory systemTempDir = Directory.systemTemp;
  final File file = await File('${systemTempDir.path}/$name').create();
  await file.writeAsString(kTestString);
  return file;
}

Future<FirebaseApp> testInitializeSecondaryApp(
    {bool withDefaultBucket = true}) async {
  final String testAppName =
      withDefaultBucket ? 'testapp' : 'testapp-no-bucket';
  print('withDefaultBucket $withDefaultBucket');

  FirebaseOptions testAppOptions;
  if (Platform.isIOS || Platform.isMacOS) {
    testAppOptions = FirebaseOptions(
      appId: '1:448618578101:ios:0b650370bb29e29cac3efc',
      apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
      projectId: 'react-native-firebase-testing',
      messagingSenderId: '448618578101',
      iosBundleId: 'io.flutter.plugins.firebasecoreexample',
      storageBucket: withDefaultBucket ? kTestStorageBucket : null,
    );
  } else {
    testAppOptions = FirebaseOptions(
      appId: '1:448618578101:web:0b650370bb29e29cac3efc',
      apiKey: 'AIzaSyAgUhHU8wSJgO5MVNy95tMT07NEjzMOfz0',
      projectId: 'react-native-firebase-testing',
      messagingSenderId: '448618578101',
      storageBucket: withDefaultBucket ? kTestStorageBucket : null,
    );
  }

  return Firebase.initializeApp(name: testAppName, options: testAppOptions);
}
