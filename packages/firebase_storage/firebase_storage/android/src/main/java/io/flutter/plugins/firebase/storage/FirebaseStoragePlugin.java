// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.storage;

import android.content.Context;
import android.net.Uri;
import android.util.Base64;
import android.util.SparseArray;
import android.webkit.MimeTypeMap;

import androidx.annotation.NonNull;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.ListResult;
import com.google.firebase.storage.StorageMetadata;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.UploadTask;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.firebase.core.FlutterFirebasePlugin;

// TODO(kroikie): Better handle empty paths.
//                https://github.com/FirebaseExtended/flutterfire/issues/1505
/** FirebaseStoragePlugin */
// TODO(Salakar): Should also implement io.flutter.plugins.firebase.core.FlutterFirebasePlugin when
// reworked.
public class FirebaseStoragePlugin
    implements FlutterFirebasePlugin, MethodCallHandler, FlutterPlugin {
  private static final SparseArray<UploadTask> uploadTasks = new SparseArray<>();
  private FirebaseStorage firebaseStorage;
  private MethodChannel channel;

  public static void registerWith(PluginRegistry.Registrar registrar) {
    FirebaseStoragePlugin instance = new FirebaseStoragePlugin();
    instance.onAttachedToEngine(registrar.context(), registrar.messenger());
  }

  private static String getMimeType(Uri file) {
    String type = null;
    String extension = MimeTypeMap.getFileExtensionFromUrl(file.toString());
    if (extension != null) {
      type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
    }
    return type;
  }

  public static Map<String, Object> parseUploadTaskSnapshot(UploadTask.TaskSnapshot snapshot) {
    Map<String, Object> out = new HashMap<>();
    out.put("path", snapshot.getStorage().getPath());
    out.put("bytesTransferred", snapshot.getBytesTransferred());
    out.put("totalBytes", snapshot.getTotalByteCount());
    out.put("metadata", parseMetadata(snapshot.getMetadata()));

    return out;
  }

  private static Map<String, Object> parseMetadata(StorageMetadata storageMetadata) {
    Map<String, Object> out = new HashMap<>();
    out.put("name", storageMetadata.getName());
    out.put("bucket", storageMetadata.getBucket());
    out.put("generation", storageMetadata.getGeneration());
    out.put("metageneration", storageMetadata.getMetadataGeneration());
    out.put("fullPath", storageMetadata.getPath());
    out.put("size", storageMetadata.getSizeBytes());
    out.put("creationTimeMillis", storageMetadata.getCreationTimeMillis());
    out.put("updatedTimeMillis", storageMetadata.getUpdatedTimeMillis());
    out.put("md5Hash", storageMetadata.getMd5Hash());
    out.put("cacheControl", storageMetadata.getCacheControl());
    out.put("contentDisposition", storageMetadata.getContentDisposition());
    out.put("contentEncoding", storageMetadata.getContentEncoding());
    out.put("contentLanguage", storageMetadata.getContentLanguage());
    out.put("contentType", storageMetadata.getContentType());

    Map<String, String> customMetadata = new HashMap<>();
    for (String key : storageMetadata.getCustomMetadataKeys()) {
      customMetadata.put(key, Objects.requireNonNull(storageMetadata.getCustomMetadata(key)));
    }
    out.put("customMetadata", customMetadata);
    return out;
  }

  private void onAttachedToEngine(Context applicationContext, BinaryMessenger binaryMessenger) {
    channel = new MethodChannel(binaryMessenger, "plugins.flutter.io/firebase_storage");
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onAttachedToEngine(FlutterPluginBinding binding) {
    onAttachedToEngine(binding.getApplicationContext(), binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(FlutterPluginBinding binding) {
    firebaseStorage = null;
    channel = null;
  }

  private FirebaseStorage getStorage(Map<String, Object> arguments) {
    String appName = (String) Objects.requireNonNull(arguments.get("appName"));
    FirebaseApp app = FirebaseApp.getInstance(appName);
    String storageBucket = (String) arguments.get("storageBucket");

    if (storageBucket == null) {
      return FirebaseStorage.getInstance(app);
    }

    return FirebaseStorage.getInstance(app, storageBucket);
  }

  private StorageReference getReference(Map<String, Object> arguments) {
    String path = (String) Objects.requireNonNull(arguments.get("path"));
    return getStorage(arguments).getReference(path);
  }

  private Map<String, Object> parseListResult(ListResult listResult) {
    Map<String, Object> out = new HashMap<>();
    out.put("nextPageToken", listResult.getPageToken());

    List<String> items = new ArrayList<>();
    List<String> prefixes = new ArrayList<>();

    for (StorageReference reference : listResult.getItems()) {
      items.add(reference.getPath());
    }

    for (StorageReference reference : listResult.getPrefixes()) {
      prefixes.add(reference.getPath());
    }

    out.put("items", items);
    out.put("prefixes", prefixes);
    return out;
  }

  private Task<Void> setMaxOperationRetryTime(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseStorage storage = getStorage(arguments);
          Long time = (Long) Objects.requireNonNull(arguments.get("time"));
          storage.setMaxOperationRetryTimeMillis(time);
          return null;
        });
  }

  private Task<Void> setMaxUploadRetryTime(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseStorage storage = getStorage(arguments);
          Long time = (Long) Objects.requireNonNull(arguments.get("time"));
          storage.setMaxUploadRetryTimeMillis(time);
          return null;
        });
  }

  private Task<Void> referenceDelete(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);
          return Tasks.await(reference.delete());
        });
  }

  private Task<Map<String, Object>> referenceGetDownloadURL(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);
          Uri downloadURL = Tasks.await(reference.getDownloadUrl());

          Map<String, Object> out = new HashMap<>();
          out.put("downloadURL", downloadURL.toString());
          return out;
        });
  }

  private Task<Map<String, Object>> referenceGetMetadata(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);
          StorageMetadata metadata = Tasks.await(reference.getMetadata());
          return parseMetadata(metadata);
        });
  }

  private Task<Map<String, Object>> referenceList(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);
          Task<ListResult> task;

          @SuppressWarnings("unchecked")
          Map<String, Object> listOptions =
              (Map<String, Object>) Objects.requireNonNull(arguments.get("options"));

          int maxResults = (Integer) Objects.requireNonNull(listOptions.get("maxResults"));

          if (listOptions.containsKey("pageToken")) {
            task =
                reference.list(
                    maxResults, (String) Objects.requireNonNull(listOptions.get("pageToken")));
          } else {
            task = reference.list(maxResults);
          }

          ListResult listResult = Tasks.await(task);
          return parseListResult(listResult);
        });
  }

  private Task<Map<String, Object>> referenceListAll(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);
          ListResult listResult = Tasks.await(reference.listAll());
          return parseListResult(listResult);
        });
  }

  private Task<Void> taskPutString(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);
          String data = (String) Objects.requireNonNull(arguments.get("data"));
          String format = (String) Objects.requireNonNull(arguments.get("format"));

          @SuppressWarnings("unchecked")
          Map<String, Object> metadata = (Map<String, Object>) arguments.get("metadata");

          final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          FirebaseStorageTask task =
              new FirebaseStorageTask(
                  handle, reference, stringToByteData(data, format), parseMetadata(metadata));

          UploadTask uploadTask = task.start(channel, cachedThreadPool);
          uploadTasks.put(handle, uploadTask);

          return null;
        });
  }

  private Task<Void> taskPause(Map<String, Object> arguments) {
    return Tasks.call(
      cachedThreadPool,
      () -> {
        final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
        UploadTask task = uploadTasks.get(handle);

        if (task == null) {
          // TODO throw error;
          throw new Exception("TODO");
        }

        task.pause();
        return null;
      });
  }

  private Task<Void> taskResume(Map<String, Object> arguments) {
    return Tasks.call(
      cachedThreadPool,
      () -> {
        final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
        UploadTask task = uploadTasks.get(handle);

        if (task == null) {
          // TODO throw error;
          throw new Exception("TODO");
        }

        task.resume();
        return null;
      });
  }

  private Task<Void> taskCancel(Map<String, Object> arguments) {
    return Tasks.call(
      cachedThreadPool,
      () -> {
        final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
        UploadTask task = uploadTasks.get(handle);

        if (task == null) {
          // TODO throw error;
          throw new Exception("TODO");
        }

        task.cancel();
        return null;
      });
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull final Result result) {
    Task<?> methodCallTask;

    switch (call.method) {
      case "Storage#setMaxOperationRetryTime":
        methodCallTask = setMaxOperationRetryTime(call.arguments());
        break;
      case "Storage#setMaxUploadRetryTime":
        methodCallTask = setMaxUploadRetryTime(call.arguments());
        break;
      case "Reference#delete":
        methodCallTask = referenceDelete(call.arguments());
        break;
      case "Reference#getDownloadURL":
        methodCallTask = referenceGetDownloadURL(call.arguments());
        break;
      case "Reference#getMetadata":
        methodCallTask = referenceGetMetadata(call.arguments());
        break;
      case "Reference#list":
        methodCallTask = referenceList(call.arguments());
        break;
      case "Reference#listAll":
        methodCallTask = referenceListAll(call.arguments());
        break;
      case "Task#startPutString":
        methodCallTask = taskPutString(call.arguments());
        break;
      case "Task#pause":
        methodCallTask = taskPause(call.arguments());
        break;
      case "Task#resume":
        methodCallTask = taskResume(call.arguments());
        break;
      case "Task#cancel":
        methodCallTask = taskCancel(call.arguments());
        break;
      default:
        result.notImplemented();
        return;
    }

    methodCallTask.addOnCompleteListener(
        cachedThreadPool,
        task -> {
          if (task.isSuccessful()) {
            result.success(task.getResult());
          } else {
            Exception exception = task.getException();
            // todo handle details
            result.error(
                "firebase_storage", exception != null ? exception.getMessage() : null, null);
          }
        });
  }

  private StorageMetadata parseMetadata(Map<String, Object> metadata) {
    if (metadata == null) {
      return null;
    }

    StorageMetadata.Builder builder = new StorageMetadata.Builder();

    if (metadata.get("cacheControl") != null) {
      builder.setCacheControl((String) metadata.get("cacheControl"));
    }
    if (metadata.get("contentDisposition") != null) {
      builder.setContentDisposition((String) metadata.get("contentDisposition"));
    }
    if (metadata.get("contentEncoding") != null) {
      builder.setContentEncoding((String) metadata.get("contentEncoding"));
    }
    if (metadata.get("contentLanguage") != null) {
      builder.setContentLanguage((String) metadata.get("contentLanguage"));
    }
    if (metadata.get("contentType") != null) {
      builder.setContentType((String) metadata.get("contentType"));
    }
    if (metadata.get("customMetadata") != null) {
      Map<String, String> customMetadata =
          (Map<String, String>) Objects.requireNonNull(metadata.get("customMetadata"));
      for (String key : customMetadata.keySet()) {
        builder.setCustomMetadata(key, customMetadata.get(key));
      }
    }

    return builder.build();
  }

  private byte[] stringToByteData(@NonNull String data, @NonNull String format) {
    switch (format) {
      case "base64":
        return Base64.decode(data, Base64.DEFAULT);
      case "base64url":
        return Base64.decode(data, Base64.URL_SAFE);
      case "raw":
        return data.getBytes();
      case "dataUrl":
        {
          int contentStartIndex = data.indexOf("base64,") + "base64,".length();
          return Base64.decode(data.substring(contentStartIndex), Base64.DEFAULT);
        }
      default:
        return null;
    }
  }

  //
  //  private void putFile(MethodCall call, Result result) {
  //    String filename = call.argument("filename");
  //    String path = call.argument("path");
  //    File file = new File(filename);
  //    final Uri fileUri = Uri.fromFile(file);
  //    Map<String, Object> metadata = call.argument("metadata");
  //    metadata = ensureMimeType(metadata, fileUri);
  //
  //    StorageReference ref = firebaseStorage.getReference().child(path);
  //    final UploadTask uploadTask = ref.putFile(fileUri, buildMetadataFromMap(metadata));
  //    final int handle = addUploadListeners(uploadTask);
  //    result.success(handle);
  //  }
  //
  //  private void putData(MethodCall call, Result result) {
  //    byte[] bytes = call.argument("data");
  //    String path = call.argument("path");
  //    Map<String, Object> metadata = call.argument("metadata");
  //    StorageReference ref = firebaseStorage.getReference().child(path);
  //    UploadTask uploadTask;
  //    if (metadata == null) {
  //      uploadTask = ref.putBytes(bytes);
  //    } else {
  //      uploadTask = ref.putBytes(bytes, buildMetadataFromMap(metadata));
  //    }
  //    final int handle = addUploadListeners(uploadTask);
  //    result.success(handle);
  //  }
  //
  //  private void getData(MethodCall call, final Result result) {
  //    Integer maxSize = call.argument("maxSize");
  //    String path = call.argument("path");
  //    StorageReference ref = firebaseStorage.getReference().child(path);
  //    Task<byte[]> downloadTask = ref.getBytes(maxSize);
  //    downloadTask.addOnSuccessListener(
  //        new OnSuccessListener<byte[]>() {
  //          @Override
  //          public void onSuccess(byte[] bytes) {
  //            result.success(bytes);
  //          }
  //        });
  //    downloadTask.addOnFailureListener(
  //        new OnFailureListener() {
  //          @Override
  //          public void onFailure(@NonNull Exception e) {
  //            result.error("download_error", e.getMessage(), null);
  //          }
  //        });
  //  }

  //  private void writeToFile(MethodCall call, final Result result) {
  //    String path = call.argument("path");
  //    String filePath = call.argument("filePath");
  //    File file = new File(filePath);
  //    StorageReference ref = firebaseStorage.getReference().child(path);
  //    FileDownloadTask downloadTask = ref.getFile(file);
  //    downloadTask.addOnSuccessListener(
  //        new OnSuccessListener<FileDownloadTask.TaskSnapshot>() {
  //          @Override
  //          public void onSuccess(FileDownloadTask.TaskSnapshot taskSnapshot) {
  //            result.success(taskSnapshot.getTotalByteCount());
  //          }
  //        });
  //    downloadTask.addOnFailureListener(
  //        new OnFailureListener() {
  //          @Override
  //          public void onFailure(@NonNull Exception e) {
  //            result.error("download_error", e.getMessage(), null);
  //          }
  //        });
  //  }

  //  private int addUploadListeners(final UploadTask uploadTask) {
  //    final int handle = ++nextUploadHandle;
  //    uploadTask
  //        .addOnProgressListener(
  //            new OnProgressListener<UploadTask.TaskSnapshot>() {
  //              @Override
  //              public void onProgress(UploadTask.TaskSnapshot snapshot) {
  //                invokeStorageTaskEvent(handle, StorageTaskEventType.progress, snapshot, null);
  //              }
  //            })
  //        .addOnPausedListener(
  //            new OnPausedListener<UploadTask.TaskSnapshot>() {
  //              @Override
  //              public void onPaused(UploadTask.TaskSnapshot snapshot) {
  //                invokeStorageTaskEvent(handle, StorageTaskEventType.pause, snapshot, null);
  //              }
  //            })
  //        .addOnCompleteListener(
  //            new OnCompleteListener<UploadTask.TaskSnapshot>() {
  //              @Override
  //              public void onComplete(@NonNull Task<UploadTask.TaskSnapshot> task) {
  //                if (!task.isSuccessful()) {
  //                  invokeStorageTaskEvent(
  //                      handle,
  //                      StorageTaskEventType.failure,
  //                      uploadTask.getSnapshot(),
  //                      (StorageException) task.getException());
  //                } else {
  //                  invokeStorageTaskEvent(
  //                      handle, StorageTaskEventType.success, task.getResult(), null);
  //                }
  //                uploadTasks.remove(handle);
  //              }
  //            });
  //    uploadTasks.put(handle, uploadTask);
  //    return handle;
  //  }

  @Override
  public Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return null;
  }

  @Override
  public Task<Void> didReinitializeFirebaseCore() {
    return null;
  }
}
