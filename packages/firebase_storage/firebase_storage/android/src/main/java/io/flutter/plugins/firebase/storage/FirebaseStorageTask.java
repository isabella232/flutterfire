package io.flutter.plugins.firebase.storage;

import androidx.annotation.Nullable;

import com.google.firebase.storage.StorageMetadata;
import com.google.firebase.storage.StorageReference;
import com.google.firebase.storage.UploadTask;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;

import io.flutter.plugin.common.MethodChannel;

import static io.flutter.plugins.firebase.storage.FirebaseStoragePlugin.parseUploadTaskSnapshot;

class FirebaseStorageTask {
  private final int handle;
  private final StorageReference reference;
  private final byte[] data;
  private final StorageMetadata metadata;

  FirebaseStorageTask(
      int handle, StorageReference reference, byte[] data, @Nullable StorageMetadata metadata) {
    this.handle = handle;
    this.reference = reference;
    this.data = data;
    this.metadata = metadata;
  }

  UploadTask start(MethodChannel channel, ExecutorService executor) {
    UploadTask task;

    if (metadata == null) {
      task = reference.putBytes(data);
    } else {
      task = reference.putBytes(data, metadata);
    }

    Map<String, Object> arguments = new HashMap<>();
    arguments.put("handle", handle);
    arguments.put("appName", reference.getStorage().getApp().getName());
    arguments.put("storageBucket", reference.getBucket());

    task.addOnProgressListener(executor, taskSnapshot -> {
      arguments.put("type", "progress");
      arguments.put("snapshot", parseUploadTaskSnapshot(taskSnapshot));
      channel.invokeMethod("Task#onProgress", arguments);
    });

    task.addOnCanceledListener(executor, () -> {
      arguments.put("type", "canceled");
      channel.invokeMethod("Task#onCancel", arguments);
    });

    task.addOnPausedListener(executor, taskSnapshot -> {
      arguments.put("type", "paused");
      arguments.put("snapshot", parseUploadTaskSnapshot(taskSnapshot));
      channel.invokeMethod("Task#onPaused", arguments);
    });

    task.addOnSuccessListener(executor, taskSnapshot -> {
      arguments.put("type", "complete");
      arguments.put("snapshot", parseUploadTaskSnapshot(taskSnapshot));
      channel.invokeMethod("Task#onComplete", arguments);
    });

    task.addOnFailureListener(executor, e -> {
      arguments.put("type", "error");
      // TODO handle error details
      arguments.put("error", null);
      channel.invokeMethod("Task#onError", arguments);
    });

    return task;
  }
}
