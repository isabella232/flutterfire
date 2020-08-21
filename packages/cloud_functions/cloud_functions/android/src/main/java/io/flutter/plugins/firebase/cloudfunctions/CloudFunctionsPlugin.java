// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.firebase.cloudfunctions;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.tasks.Task;
import com.google.android.gms.tasks.Tasks;
import com.google.firebase.FirebaseApp;
import com.google.firebase.functions.FirebaseFunctions;
import com.google.firebase.functions.FirebaseFunctionsException;
import com.google.firebase.functions.HttpsCallableReference;
import com.google.firebase.functions.HttpsCallableResult;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;
import java.util.concurrent.TimeUnit;

import io.flutter.Log;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.plugins.firebase.core.FlutterFirebasePlugin;

public class CloudFunctionsPlugin implements FlutterFirebasePlugin, MethodCallHandler {

  public static void registerWith(Registrar registrar) {
    final MethodChannel channel =
        new MethodChannel(registrar.messenger(), "plugins.flutter.io/cloud_functions");
    channel.setMethodCallHandler(new CloudFunctionsPlugin());
  }

  private FirebaseFunctions getFunctions(Map<String, Object> arguments) {
    String appName = (String) Objects.requireNonNull(arguments.get("appName"));
    String region = (String) arguments.get("region");

    FirebaseApp app = FirebaseApp.getInstance(appName);

    if (region == null) {
      return FirebaseFunctions.getInstance(app);
    } else {
      return FirebaseFunctions.getInstance(app, region);
    }
  }

  private Task<Object> callHttpsFunction(Map<String, Object> arguments) {
    return Tasks.call(
        cachedThreadPool,
        () -> {
          FirebaseFunctions firebaseFunctions = getFunctions(arguments);

          String functionName = (String) Objects.requireNonNull(arguments.get("functionName"));
          String origin = (String) arguments.get("origin");
          Integer timeout = (Integer) arguments.get("timeout");
          Object parameters = arguments.get("parameters");

          if (origin != null) {
            firebaseFunctions.useFunctionsEmulator(origin);
          }

          HttpsCallableReference httpsCallableReference =
              firebaseFunctions.getHttpsCallable(functionName);

          if (timeout != null) {
            httpsCallableReference.setTimeout(timeout.longValue(), TimeUnit.MILLISECONDS);
          }

          HttpsCallableResult result = Tasks.await(httpsCallableReference.call(parameters));
          return result.getData();
        });
  }

  @Override
  public void onMethodCall(MethodCall call, @NonNull final Result result) {
    Task<?> methodCallTask;

    //noinspection SwitchStatementWithTooFewBranches
    switch (call.method) {
      case "CloudFunctions#call":
        methodCallTask = callHttpsFunction(call.arguments());
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
            result.error(
                "cloud_functions",
                exception != null ? exception.getMessage() : null,
                getExceptionDetails(exception));
          }
        });
  }

  private Map<String, Object> getExceptionDetails(@Nullable Exception exception) {
    Map<String, Object> details = new HashMap<>();

    if (exception == null) {
      return details;
    }

    String code = "UNKNOWN";
    String message = exception.getMessage();
    Object additionalData = null;

    if (exception.getCause() instanceof FirebaseFunctionsException) {
      FirebaseFunctionsException functionsException =
          (FirebaseFunctionsException) exception.getCause();
      code = functionsException.getCode().name();
      message = functionsException.getMessage();
      additionalData = functionsException.getDetails();

      if (functionsException.getCause() instanceof IOException
          && functionsException.getCause().getMessage().equals("Canceled")) {
        code = FirebaseFunctionsException.Code.DEADLINE_EXCEEDED.name();
        message = FirebaseFunctionsException.Code.DEADLINE_EXCEEDED.name();
      } else if (functionsException.getCause() instanceof IOException) {
        // return UNAVAILABLE for network io errors, to match iOS
        code = FirebaseFunctionsException.Code.UNAVAILABLE.name();
        message = FirebaseFunctionsException.Code.UNAVAILABLE.name();
      }
    }

    details.put("code", code.replace("_", "-").toLowerCase());
    details.put("message", message);

    if (additionalData != null) {
      details.put("additionalData", additionalData);
    }

    return details;
  }

  @Override
  public Task<Map<String, Object>> getPluginConstantsForFirebaseApp(FirebaseApp firebaseApp) {
    return Tasks.call(() -> null);
  }

  @Override
  public Task<Void> didReinitializeFirebaseCore() {
    return Tasks.call(() -> null);
  }
}
