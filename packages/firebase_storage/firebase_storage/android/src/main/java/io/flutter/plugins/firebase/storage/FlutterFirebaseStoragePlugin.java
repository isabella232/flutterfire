// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.storage;

import android.app.Activity;
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
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugins.firebase.core.FlutterFirebasePlugin;
import io.flutter.plugins.firebase.core.FlutterFirebasePluginRegistry;
import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

public class FlutterFirebaseStoragePlugin
    implements FlutterFirebasePlugin, MethodCallHandler, FlutterPlugin, ActivityAware {
  private static final SparseArray<StorageTask<?>> storageTasks = new SparseArray<>();
  private MethodChannel channel;
  private Activity activity;

  public static void registerWith(PluginRegistry.Registrar registrar) {
    FlutterFirebaseStoragePlugin instance = new FlutterFirebaseStoragePlugin();
    instance.activity = registrar.activity();
    instance.initInstance(registrar.messenger());
  }

  public static Map<String, Object> parseUploadTaskSnapshot(UploadTask.TaskSnapshot snapshot) {
    Map<String, Object> out = new HashMap<>();
    out.put("path", snapshot.getStorage().getPath());
    out.put("bytesTransferred", snapshot.getBytesTransferred());
    out.put("totalBytes", snapshot.getTotalByteCount());
    if (snapshot.getMetadata() != null) {
      out.put("metadata", parseMetadata(snapshot.getMetadata()));
    }

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
    if (storageMetadata == null) {
      return null;
    }

    Map<String, Object> out = new HashMap<>();
    if (storageMetadata.getName() != null) out.put("name", storageMetadata.getName());
    if (storageMetadata.getBucket() != null) out.put("bucket", storageMetadata.getBucket());
    if (storageMetadata.getGeneration() != null)
      out.put("generation", storageMetadata.getGeneration());
    if (storageMetadata.getGeneration() != null)
      out.put("generation", storageMetadata.getGeneration());
    out.put("fullPath", storageMetadata.getPath());
    out.put("size", storageMetadata.getSizeBytes());
    out.put("creationTimeMillis", storageMetadata.getCreationTimeMillis());
    out.put("updatedTimeMillis", storageMetadata.getUpdatedTimeMillis());
    if (storageMetadata.getMd5Hash() != null) out.put("md5Hash", storageMetadata.getMd5Hash());
    if (storageMetadata.getCacheControl() != null)
      out.put("cacheControl", storageMetadata.getCacheControl());
    if (storageMetadata.getContentDisposition() != null)
      out.put("contentDisposition", storageMetadata.getContentDisposition());
    if (storageMetadata.getContentEncoding() != null)
      out.put("contentEncoding", storageMetadata.getContentEncoding());
    if (storageMetadata.getContentLanguage() != null)
      out.put("contentLanguage", storageMetadata.getContentLanguage());
    if (storageMetadata.getContentType() != null)
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

  void cancelTasks() {
    for (int i = 0; i < storageTasks.size(); i++) {
      int key = storageTasks.keyAt(i);
      StorageTask<?> task = storageTasks.get(key);
      task.cancel();
    }

    storageTasks.clear();
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    initInstance(binding.getBinaryMessenger());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    cancelTasks();
    channel.setMethodCallHandler(null);
    channel = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding activityPluginBinding) {
    attachToActivity(activityPluginBinding);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    detachToActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(
      @NonNull ActivityPluginBinding activityPluginBinding) {
    attachToActivity(activityPluginBinding);
  }

  @Override
  public void onDetachedFromActivity() {
    detachToActivity();
  }

  private void attachToActivity(ActivityPluginBinding activityPluginBinding) {
    activity = activityPluginBinding.getActivity();
  }

  private void detachToActivity() {
    activity = null;
  }

  private void initInstance(BinaryMessenger messenger) {
    String channelName = "plugins.flutter.io/firebase_storage";
    channel = new MethodChannel(messenger, channelName);
    channel.setMethodCallHandler(this);
    FlutterFirebasePluginRegistry.registerPlugin(channelName, this);
  }

  private FirebaseStorage getStorage(Map<String, Object> arguments) {
    String appName = (String) Objects.requireNonNull(arguments.get("appName"));
    FirebaseApp app = FirebaseApp.getInstance(appName);
    String bucket = (String) arguments.get("bucket");

    if (bucket == null) {
      return FirebaseStorage.getInstance(app);
    }

    return FirebaseStorage.getInstance(app, bucket);
  }

  private StorageReference getReference(Map<String, Object> arguments) {
    String path = (String) Objects.requireNonNull(arguments.get("path"));
    return getStorage(arguments).getReference(path);
  }

  private Map<String, Object> parseListResult(ListResult listResult) {
    Map<String, Object> out = new HashMap<>();

    if (listResult.getPageToken() != null) {
      out.put("nextPageToken", listResult.getPageToken());
    }

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

          if (listOptions.get("pageToken") != null) {
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

  private Task<Map<String, Object>> referenceUpdateMetadata(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          StorageReference reference = getReference(arguments);

          @SuppressWarnings("unchecked")
          Map<String, Object> metadata =
              (Map<String, Object>) Objects.requireNonNull(arguments.get("metadata"));

          StorageMetadata updatedMetadata =
              Tasks.await(reference.updateMetadata(parseMetadata(metadata)));

          return parseMetadata(updatedMetadata);
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

          StorageTask<?> uploadTask = task.start(channel, activity, cachedThreadPool);
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

          StorageTask<?> uploadTask = task.start(channel, activity, cachedThreadPool);
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

          StorageTask<?> uploadTask = task.start(channel, activity, cachedThreadPool);
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

          StorageTask<?> downloadTask = task.start(channel, activity, cachedThreadPool);
          storageTasks.put(handle, downloadTask);

          return null;
        });
  }

  private Map<String, Boolean> setTaskState(StorageTask<?> task, String state) {
    boolean status = false;

    switch (state) {
      case "pause":
        status = task.pause();
        break;
      case "resume":
        status = task.resume();
        break;
      case "cancel":
        status = task.cancel();
        break;
    }

    Map<String, Boolean> statusMap = new HashMap<>();
    statusMap.put("status", status);
    return statusMap;
  }

  private Task<Map<String, Boolean>> taskPause(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          StorageTask<?> task = storageTasks.get(handle);

          if (task == null) {
            throw new Exception("Pause operation was called on a task which does not exist.");
          }

          return setTaskState(task, "pause");
        });
  }

  private Task<Map<String, Boolean>> taskResume(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          StorageTask<?> task = storageTasks.get(handle);

          if (task == null) {
            throw new Exception("Resume operation was called on a task which does not exist.");
          }

          return setTaskState(task, "resume");
        });
  }

  private Task<Map<String, Boolean>> taskCancel(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          final int handle = (int) Objects.requireNonNull(arguments.get("handle"));
          StorageTask<?> task = storageTasks.get(handle);

          if (task == null) {
            throw new Exception("Cancel operation was called on a task which does not exist.");
          }

          return setTaskState(task, "cancel");
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
      case "Reference#updateMetadata":
        methodCallTask = referenceUpdateMetadata(call.arguments());
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
      @SuppressWarnings("unchecked")
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
      case "PutStringFormat.base64":
        return Base64.decode(data, Base64.DEFAULT);
      case "PutStringFormat.base64Url":
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
    return Tasks.call(
        cachedThreadPool,
        () -> {
          cancelTasks();
          return null;
        });
  }
}
