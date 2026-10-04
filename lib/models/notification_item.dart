enum NotificationType {
  orderPlaced,
  orderConfirmed,
  orderShipped,
  orderDelivered,
  promotion,
  system,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime timestamp;
  final bool isRead;
  final String? orderId;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.orderId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? timestamp,
    bool? isRead,
    String? orderId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      orderId: orderId ?? this.orderId,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
    'orderId': orderId,
  };

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      orderId: map['orderId'],
    );
  }
}
