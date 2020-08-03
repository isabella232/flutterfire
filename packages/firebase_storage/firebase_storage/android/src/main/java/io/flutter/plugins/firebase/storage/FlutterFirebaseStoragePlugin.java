// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.storage;

import android.content.Context;
import android.net.Uri;
import android.util.Base64;
import android.util.SparseArray;

import androidx.annotation.NonNull;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.storage.FileDownloadTask;
import com.google.firebase.storage.FirebaseStorage;
import com.google.firebase.storage.ListResult;
import com.google.firebase.storage.StorageException;
import com.google.firebase.storage.StorageMetadata;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.StorageTask;
import com.google.firebase.storage.UploadTask;

import java.io.File;
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
public class FlutterFirebaseStoragePlugin
    implements FlutterFirebasePlugin, MethodCallHandler, FlutterPlugin {
  private static final SparseArray<StorageTask<?>> storageTasks = new SparseArray<>();
  private MethodChannel channel;

  public static void registerWith(PluginRegistry.Registrar registrar) {
    FlutterFirebaseStoragePlugin instance = new FlutterFirebaseStoragePlugin();
    instance.onAttachedToEngine(registrar.context(), registrar.messenger());
  }

  public static Map<String, Object> parseUploadTaskSnapshot(UploadTask.TaskSnapshot snapshot) {
    Map<String, Object> out = new HashMap<>();
    out.put("path", snapshot.getStorage().getPath());
    out.put("bytesTransferred", snapshot.getBytesTransferred());
    out.put("totalBytes", snapshot.getTotalByteCount());
    out.put("metadata", parseMetadata(snapshot.getMetadata()));

    return out;
  }

  public static Map<String, Object> parseDownloadTaskSnapshot(
      FileDownloadTask.TaskSnapshot snapshot) {
    Map<String, Object> out = new HashMap<>();
    out.put("path", snapshot.getStorage().getPath());
    out.put("bytesTransferred", snapshot.getBytesTransferred());
    out.put("totalBytes", snapshot.getTotalByteCount());

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

  static Map<String, String> getExceptionDetails(Exception exception) {
    Map<String, String> details = new HashMap<>();
    FlutterFirebaseStorageException storageException = null;

    if (exception instanceof StorageException) {
      storageException = new FlutterFirebaseStorageException(exception, exception.getCause());
    } else if (exception.getCause() != null && exception.getCause() instanceof StorageException) {
      storageException =
          new FlutterFirebaseStorageException(
              (StorageException) exception.getCause(),
              exception.getCause().getCause() != null
                  ? exception.getCause().getCause()
                  : exception.getCause());
    }

    if (storageException != null) {
      details.put("code", storageException.getCode());
      details.put("message", storageException.getMessage());
    }

    return details;
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
          Object time = Objects.requireNonNull(arguments.get("time"));
          storage.setMaxOperationRetryTimeMillis(getLongValue(time));
          return null;
        });
  }

  private Task<Void> setMaxUploadRetryTime(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseStorage storage = getStorage(arguments);
          Object time = Objects.requireNonNull(arguments.get("time"));
          storage.setMaxUploadRetryTimeMillis(getLongValue(time));
          return null;
        });
  }

  private Task<Void> setMaxDownloadRetryTime(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseStorage storage = getStorage(arguments);
          Object time = Objects.requireNonNull(arguments.get("time"));
          storage.setMaxDownloadRetryTimeMillis(getLongValue(time));
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

  private Task<Void> taskPut(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);
          byte[] bytes = (byte[]) Objects.requireNonNull(arguments.get("data"));

          @SuppressWarnings("unchecked")
          Map<String, Object> metadata = (Map<String, Object>) arguments.get("metadata");

          final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          FlutterFirebaseStorageTask task =
              FlutterFirebaseStorageTask.uploadBytes(
                  handle, reference, bytes, parseMetadata(metadata));

          StorageTask uploadTask = task.start(channel, cachedThreadPool);
          storageTasks.put(handle, uploadTask);

          return null;
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
          FlutterFirebaseStorageTask task =
              FlutterFirebaseStorageTask.uploadBytes(
                  handle, reference, stringToByteData(data, format), parseMetadata(metadata));

          StorageTask uploadTask = task.start(channel, cachedThreadPool);
          storageTasks.put(handle, uploadTask);

          return null;
        });
  }

  private Task<Void> taskPutFile(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);
          String filePath = (String) Objects.requireNonNull(arguments.get("filePath"));

          @SuppressWarnings("unchecked")
          Map<String, Object> metadata = (Map<String, Object>) arguments.get("metadata");

          final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          FlutterFirebaseStorageTask task =
              FlutterFirebaseStorageTask.uploadFile(
                  handle, reference, Uri.fromFile(new File(filePath)), parseMetadata(metadata));

          StorageTask uploadTask = task.start(channel, cachedThreadPool);
          storageTasks.put(handle, uploadTask);

          return null;
        });
  }

  private Task<Void> taskWriteToFile(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);
          String filePath = (String) Objects.requireNonNull(arguments.get("filePath"));

          final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          FlutterFirebaseStorageTask task =
              FlutterFirebaseStorageTask.downloadFile(handle, reference, new File(filePath));

          StorageTask downloadTask = task.start(channel, cachedThreadPool);
          storageTasks.put(handle, downloadTask);

          return null;
        });
  }

  private Task<Void> taskPause(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          StorageTask task = storageTasks.get(handle);

          if (task == null) {
            throw new Exception("Pause operation was called on a task which does not exist.");
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
          StorageTask task = storageTasks.get(handle);

          if (task == null) {
            throw new Exception("Resume operation was called on a task which does not exist.");
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
          StorageTask task = storageTasks.get(handle);

          if (task == null) {
            throw new Exception("Cancel operation was called on a task which does not exist.");
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
      case "Storage#setMaxDownloadRetryTime":
        methodCallTask = setMaxDownloadRetryTime(call.arguments());
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
      case "Task#startPut":
        methodCallTask = taskPut(call.arguments());
        break;
      case "Task#startPutString":
        methodCallTask = taskPutString(call.arguments());
        break;
      case "Task#startPutFile":
        methodCallTask = taskPutFile(call.arguments());
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
      case "Task#writeToFile":
        methodCallTask = taskWriteToFile(call.arguments());
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
            Map<String, String> exceptionDetails = getExceptionDetails(exception);

            result.error(
                "firebase_storage",
                exception != null ? exception.getMessage() : null,
                exceptionDetails);
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
      default:
        return null;
    }
  }

  private Long getLongValue(Object value) throws Exception {
    if (value instanceof Long) {
      return (Long) value;
    } else if (value instanceof Integer) {
      return Long.valueOf((Integer) value);
    } else {
      throw new Exception("Could not convert provided value to a Long value.");
    }
  }

  @Override
  public Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          Map<String, Object> constants = new HashMap<>();
          FirebaseStorage firebaseStorage = FirebaseStorage.getInstance(firebaseApp);

          constants.put(
              "MAX_OPERATION_RETRY_TIME", firebaseStorage.getMaxOperationRetryTimeMillis());
          constants.put("MAX_UPLOAD_RETRY_TIME", firebaseStorage.getMaxUploadRetryTimeMillis());
          constants.put("MAX_DOWNLOAD_RETRY_TIME", firebaseStorage.getMaxDownloadRetryTimeMillis());

          return constants;
        });
  }

  @Override
  public Task<Void> didReinitializeFirebaseCore() {
    return null;
  }
}
