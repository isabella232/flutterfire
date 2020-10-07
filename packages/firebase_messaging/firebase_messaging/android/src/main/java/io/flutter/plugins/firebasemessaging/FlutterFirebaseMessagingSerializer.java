package io.flutter.plugins.firebasemessaging;

import com.google.firebase.messaging.RemoteMessage;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;

class FlutterFirebaseMessagingSerializer {
  private static final String KEY_COLLAPSE_KEY = "collapseKey";
  private static final String KEY_DATA = "data";
  private static final String KEY_FROM = "from";
  private static final String KEY_MESSAGE_ID = "messageId";
  private static final String KEY_MESSAGE_TYPE = "messageType";
  private static final String KEY_SENT_TIME = "sentTime";
  private static final String KEY_ERROR = "error";
  private static final String KEY_TO = "to";
  private static final String KEY_TTL = "ttl";

  static Map<String, Object> remoteMessageToMap(RemoteMessage remoteMessage) {
    Map<String, Object> messageMap = new HashMap<>();
    Map<String, Object> dataMap = new HashMap<>();

    if (remoteMessage.getCollapseKey() != null) {
      messageMap.put(KEY_COLLAPSE_KEY, remoteMessage.getCollapseKey());
    }

    if (remoteMessage.getFrom() != null) {
      messageMap.put(KEY_FROM, remoteMessage.getFrom());
    }

    if (remoteMessage.getTo() != null) {
      messageMap.put(KEY_TO, remoteMessage.getTo());
    }

    if (remoteMessage.getMessageId() != null) {
      messageMap.put(KEY_MESSAGE_ID, remoteMessage.getMessageId());
    }

    if (remoteMessage.getMessageType() != null) {
      messageMap.put(KEY_MESSAGE_TYPE, remoteMessage.getMessageType());
    }

    if (remoteMessage.getData().size() > 0) {
      Set<Map.Entry<String, String>> entries = remoteMessage.getData().entrySet();
      for (Map.Entry<String, String> entry : entries) {
        dataMap.put(entry.getKey(), entry.getValue());
      }
    }

    messageMap.put(KEY_DATA, dataMap);
    messageMap.put(KEY_TTL, remoteMessage.getTtl());
    messageMap.put(KEY_SENT_TIME, remoteMessage.getSentTime());

    if (remoteMessage.getNotification() != null) {
      messageMap.put(
          "notification", remoteMessageNotificationToMap(remoteMessage.getNotification()));
    }

    return messageMap;
  }

  private static Map<String, Object> remoteMessageNotificationToMap(
      RemoteMessage.Notification notification) {
    Map notificationMap = new HashMap<>();
    Map androidNotificationMap = new HashMap<>();

    if (notification.getTitle() != null) {
      notificationMap.put("title", notification.getTitle());
    }

    if (notification.getTitleLocalizationKey() != null) {
      notificationMap.put("titleLocKey", notification.getTitleLocalizationKey());
    }

    //    if (notification.getTitleLocalizationArgs() != null) {
    //      notificationMap.put(
    //          "titleLocArgs", Arguments.fromJavaArgs(notification.getTitleLocalizationArgs()));
    //    }

    if (notification.getBody() != null) {
      notificationMap.put("body", notification.getBody());
    }

    if (notification.getBodyLocalizationKey() != null) {
      notificationMap.put("bodyLocKey", notification.getBodyLocalizationKey());
    }

    //    if (notification.getBodyLocalizationArgs() != null) {
    //      notificationMap.put(
    //          "bodyLocArgs", Arguments.fromJavaArgs(notification.getBodyLocalizationArgs()));
    //    }

    if (notification.getChannelId() != null) {
      androidNotificationMap.put("channelId", notification.getChannelId());
    }

    if (notification.getClickAction() != null) {
      androidNotificationMap.put("clickAction", notification.getClickAction());
    }

    if (notification.getColor() != null) {
      androidNotificationMap.put("color", notification.getColor());
    }

    if (notification.getIcon() != null) {
      androidNotificationMap.put("smallIcon", notification.getIcon());
    }

    if (notification.getImageUrl() != null) {
      androidNotificationMap.put("imageUrl", notification.getImageUrl().toString());
    }

    if (notification.getLink() != null) {
      androidNotificationMap.put("link", notification.getLink().toString());
    }

    if (notification.getNotificationCount() != null) {
      androidNotificationMap.put("count", notification.getNotificationCount());
    }

    if (notification.getNotificationPriority() != null) {
      androidNotificationMap.put("priority", notification.getNotificationPriority());
    }

    if (notification.getSound() != null) {
      androidNotificationMap.put("sound", notification.getSound());
    }

    if (notification.getTicker() != null) {
      androidNotificationMap.put("ticker", notification.getTicker());
    }

    if (notification.getVisibility() != null) {
      androidNotificationMap.put("visibility", notification.getVisibility());
    }

    notificationMap.put("android", androidNotificationMap);
    return notificationMap;
  }
}