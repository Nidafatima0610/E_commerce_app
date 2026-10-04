class ReturnRequest {
  final String returnRequestId;
  final String orderId;
  final String itemId;
  final String productName;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? comments;

  const ReturnRequest({
    required this.returnRequestId,
    required this.orderId,
    required this.itemId,
    required this.productName,
    required this.reason,
    this.status = 'Submitted',
    required this.createdAt,
    this.comments,
  });

  Map<String, dynamic> toMap() => {
    'returnRequestId': returnRequestId,
    'orderId': orderId,
    'itemId': itemId,
    'productName': productName,
    'reason': reason,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'comments': comments,
  };

  factory ReturnRequest.fromMap(Map<String, dynamic> map) {
    return ReturnRequest(
      returnRequestId: map['returnRequestId'] ?? '',
      orderId: map['orderId'] ?? '',
      itemId: map['itemId'] ?? '',
      productName: map['productName'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'Submitted',
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      comments: map['comments'],
    );
  }
}
