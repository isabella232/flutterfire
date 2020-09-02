import 'dart:io';

final String kTestString = 'Hello world';

// create file
Future<File> createFile(name) async {
  final Directory systemTempDir = Directory.systemTemp;
  final File file = await File('${systemTempDir.path}/$name').create();
  await file.writeAsString(kTestString);
  return file;
}
