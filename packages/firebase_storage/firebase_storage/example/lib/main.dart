import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Firebase Storage Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();
  List<UploadTask> _tasks = <UploadTask>[];

  @override
  void initState() {
    super.initState();
  }

  Future<void> downloadFile(Reference ref) async {
    final Directory systemTempDir = Directory.systemTemp;
    final File tempFile = File('${systemTempDir.path}/temp-${ref.name}');
    if (tempFile.existsSync()) await tempFile.delete();

    DownloadTask task = ref.writeToFile(tempFile);

//    _scaffoldKey.currentState.showSnackBar(SnackBar(
//      content: Text(
//        'Success!\n Downloaded ${ref.name} \n from bucket: ${ref.bucket}\n '
//            'at path: ${ref.fullPath} \n'
//            'Wrote "${ref.fullPath}" to tmp-${ref.name}.txt',
//        style: const TextStyle(color: Color.fromARGB(255, 0, 155, 0)),
//      ),
//    ));
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    _tasks.forEach((UploadTask task) {
      final Widget tile = UploadTaskListTile(
        task: task,
        onDismissed: () => setState(() => _tasks.remove(task)),
        onDownload: () => downloadFile(task.snapshot.ref),
      );
      children.add(tile);
    });


    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.title),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.clear_all),
            onPressed: () {},
          )
        ]
      ),
      body: Container(
        alignment: Alignment.center,
        child: ListView(
          children: [
            RaisedButton(
                child: Text('Upload from a String'),
                onPressed:() async {
                  const String putStringText = 'his upload has been generated using the putString method! Check the metadata too!';

                  // Create a Reference to the file
                  Reference ref = FirebaseStorage.instance.ref().child('playground').child('/put-string-example.txt');

                  // Start upload of putString
                  UploadTask task = ref.putString(putStringText, metadata: SettableMetadata(
                      contentLanguage: 'en',
                      customMetadata: <String, String>{'example': 'putString'}
                  ));

                  setState(() {
                    _tasks.add(task);
                  });
                }
            ),
            RaisedButton(
                child: Text('Upload from a File'),
                onPressed:() async {
                  final Directory systemTempDir = Directory.systemTemp;
                  final File file = await File('${systemTempDir.path}/temp-file.txt').create();
                  await file.writeAsString('This is a file upload test');

                  Reference ref = FirebaseStorage.instance.ref('/file-upload-test.txt');

                  UploadTask task = ref.putFile(file);

                  task.snapshotEvents.listen((TaskSnapshot snapshot) {
                    print('Snapshot state: ${snapshot.state}');
                    print('Progress: ${(snapshot.totalBytes/snapshot.bytesTransferred) * 100} %');
                  }, onError: (Object e){
                    print(e);
                  });

                  task.onComplete.then((TaskSnapshot snapshot){
                    print('Upload Complete');
                  });
                }
            ),
            ...children
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: 'Upload',
        child: Icon(Icons.file_upload)
      ),
    );
  }
}

class UploadTaskListTile extends StatelessWidget {
  const UploadTaskListTile({Key key, this.task, this.onDismissed, this.onDownload}) : super(key: key);

   final UploadTask task;
   final VoidCallback onDismissed;
   final VoidCallback onDownload;

   String _bytesTransferred(TaskSnapshot snapshot) {
     return '${snapshot.bytesTransferred}/${snapshot.totalBytes}';
   }

   @override
  Widget build(BuildContext context) {
    return StreamBuilder<TaskSnapshot>(
      stream: task.snapshotEvents,
      builder: (BuildContext context, AsyncSnapshot<TaskSnapshot> asyncSnapshot) {
        Widget subtitle;
        if(asyncSnapshot.hasData) {
          subtitle = Text('${asyncSnapshot.data.state}: ${_bytesTransferred(asyncSnapshot.data)} bytes sent');
        }
        else {
          subtitle = Text('Starting...');
        }

        return Dismissible(
          key: Key(task.hashCode.toString()),
          onDismissed: ($) => onDismissed(),
          child: ListTile(
            title: Text('Upload Task #${task.hashCode}'),
            subtitle: subtitle,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Offstage(
                  offstage: false,
                  child: IconButton(
                    icon: Icon(Icons.pause),
                    onPressed: () => task.pause(),
                  ),
                ),
                Offstage(
                  offstage: false,
                  child: IconButton(
                    icon: Icon(Icons.file_upload),
                    onPressed: () => task.resume(),
                  ),
                ),
                Offstage(
                  offstage: false,
                  child: IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () => task.cancel(),
                  ),
                ),
                Offstage(
                  offstage: false,
                  child: IconButton(
                    icon: Icon(Icons.file_download),
                    onPressed: () => onDownload(),
                  ),
                ),
              ],
            ),
          ),
        );

      });
  }
}

