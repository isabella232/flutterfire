package io.flutter.plugins.firebase.storage;

import android.app.Activity;
import android.net.Uri;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.firebase.storage.FileDownloadTask;
import com.google.firebase.storage.StorageMetadata;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.StorageTask;
import com.google.firebase.storage.UploadTask;

import java.io.File;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.Executor;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.MethodChannel;

import static io.flutter.plugins.firebase.storage.FlutterFirebaseStoragePlugin.getExceptionDetails;
import static io.flutter.plugins.firebase.storage.FlutterFirebaseStoragePlugin.parseDownloadTaskSnapshot;
import static io.flutter.plugins.firebase.storage.FlutterFirebaseStoragePlugin.parseUploadTaskSnapshot;

class FlutterFirebaseStorageTask {
  private static Executor _taskExecutor = Executors.newSingleThreadExecutor();
  private final FlutterFirebaseStorageTaskType type;
  private final int handle;
  private final StorageReference reference;
  private final byte[] bytes;
  private final Uri fileUri;
  private final StorageMetadata metadata;

  private FlutterFirebaseStorageTask(
      FlutterFirebaseStorageTaskType type,
      int handle,
      StorageReference reference,
      @Nullable byte[] bytes,
      @Nullable Uri fileUri,
      @Nullable StorageMetadata metadata) {
    this.type = type;
    this.handle = handle;
    this.reference = reference;
    this.bytes = bytes;
    this.fileUri = fileUri;
    this.metadata = metadata;
  }

  public static FlutterFirebaseStorageTask uploadBytes(
      int handle, StorageReference reference, byte[] data, @Nullable StorageMetadata metadata) {
    return new FlutterFirebaseStorageTask(
        FlutterFirebaseStorageTaskType.BYTES, handle, reference, data, null, metadata);
  }

  public static FlutterFirebaseStorageTask uploadFile(
      int handle,
      StorageReference reference,
      @NonNull Uri fileUri,
      @Nullable StorageMetadata metadata) {
    return new FlutterFirebaseStorageTask(
        FlutterFirebaseStorageTaskType.FILE, handle, reference, null, fileUri, metadata);
  }

  public static FlutterFirebaseStorageTask downloadFile(
      int handle, StorageReference reference, @NonNull File file) {
    return new FlutterFirebaseStorageTask(
        FlutterFirebaseStorageTaskType.DOWNLOAD, handle, reference, null, Uri.fromFile(file), null);
  }

  StorageTask<?> start(
      @NonNull MethodChannel channel,
      @NonNull Activity activity,
      @SuppressWarnings("SameParameterValue") ExecutorService executor)
      throws Exception {
    StorageTask<?> task;

    if (type == FlutterFirebaseStorageTaskType.BYTES && bytes != null) {
      if (metadata == null) {
        task = reference.putBytes(bytes);
      } else {
        task = reference.putBytes(bytes, metadata);
      }
    } else if (type == FlutterFirebaseStorageTaskType.FILE && fileUri != null) {
      if (metadata == null) {
        task = reference.putFile(fileUri);
      } else {
        task = reference.putFile(fileUri, metadata);
      }
    } else if (type == FlutterFirebaseStorageTaskType.DOWNLOAD && fileUri != null) {
      task = reference.getFile(fileUri);
    } else {
      throw new Exception("Unable to start task. Some arguments have no been initialized.");
    }

    Map<String, Object> arguments = new HashMap<>();
    arguments.put("handle", handle);
    arguments.put("appName", reference.getStorage().getApp().getName());
    arguments.put("bucket", reference.getBucket());

    task.addOnProgressListener(
        _taskExecutor,
        taskSnapshot -> {
          arguments.put("snapshot", parseTaskSnapshot(taskSnapshot));
          activity.runOnUiThread(() -> channel.invokeMethod("Task#onProgress", arguments));
        });

    task.addOnPausedListener(
        _taskExecutor,
        taskSnapshot -> {
          arguments.put("snapshot", parseTaskSnapshot(taskSnapshot));
          activity.runOnUiThread(() -> channel.invokeMethod("Task#onPaused", arguments));
        });

    task.addOnSuccessListener(
        _taskExecutor,
        taskSnapshot -> {
          arguments.put("snapshot", parseTaskSnapshot(taskSnapshot));
          activity.runOnUiThread(() -> channel.invokeMethod("Task#onComplete", arguments));
        });

    task.addOnCanceledListener(
        _taskExecutor,
        () -> activity.runOnUiThread(() -> channel.invokeMethod("Task#onCancel", arguments)));

    task.addOnFailureListener(
        _taskExecutor,
        exception -> {
          arguments.put("error", getExceptionDetails(exception));
          activity.runOnUiThread(() -> channel.invokeMethod("Task#onError", arguments));
        });

    return task;
  }

  private Map<String, Object> parseTaskSnapshot(Object snapshot) {
    if (type == FlutterFirebaseStorageTaskType.DOWNLOAD) {
      return parseDownloadTaskSnapshot((FileDownloadTask.TaskSnapshot) snapshot);
    } else {
      return parseUploadTaskSnapshot((UploadTask.TaskSnapshot) snapshot);
    }
  }

  private enum FlutterFirebaseStorageTaskType {
    FILE,
    BYTES,
    DOWNLOAD,
  }
}
