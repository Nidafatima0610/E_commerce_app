class ProductQuestion {
  final String id;
  final String productId;
  final String question;
  final String? answer;
  final String askedBy;
  final String answeredBy;
  final DateTime createdAt;
  final DateTime? answeredAt;

  const ProductQuestion({
    required this.id,
    required this.productId,
    required this.question,
    this.answer,
    required this.askedBy,
    this.answeredBy = 'Verified Merchant',
    required this.createdAt,
    this.answeredAt,
  });

  bool get isAnswered => answer != null && answer!.trim().isNotEmpty;

  ProductQuestion copyWith({
    String? id,
    String? productId,
    String? question,
    String? answer,
    String? askedBy,
    String? answeredBy,
    DateTime? createdAt,
    DateTime? answeredAt,
  }) {
    return ProductQuestion(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      askedBy: askedBy ?? this.askedBy,
      answeredBy: answeredBy ?? this.answeredBy,
      createdAt: createdAt ?? this.createdAt,
      answeredAt: answeredAt ?? this.answeredAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'productId': productId,
    'question': question,
    'answer': answer,
    'askedBy': askedBy,
    'answeredBy': answeredBy,
    'createdAt': createdAt.toIso8601String(),
    'answeredAt': answeredAt?.toIso8601String(),
  };

  factory ProductQuestion.fromMap(Map<String, dynamic> map) {
    return ProductQuestion(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      question: map['question'] ?? '',
      answer: map['answer'],
      askedBy: map['askedBy'] ?? 'Shopper',
      answeredBy: map['answeredBy'] ?? 'Verified Merchant',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      answeredAt: map['answeredAt'] != null
          ? DateTime.tryParse(map['answeredAt'])
          : null,
    );
  }
}

final List<ProductQuestion> initialProductQuestions = [
  ProductQuestion(
    id: 'q_001',
    productId: 'p1',
    question: 'Does this headphone come with the 3.5mm audio jack cable and flight adapter?',
    answer: 'Yes, the retail box includes the original Sony 3.5mm AUX cable, USB-C fast charging cable, and a hard travel case.',
    askedBy: 'Kamran Ali (Lahore)',
    answeredBy: 'Sony Official Store PK',
    createdAt: DateTime.now().subtract(const Duration(days: 5)),
    answeredAt: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
  ),
  ProductQuestion(
    id: 'q_002',
    productId: 'p1',
    question: 'Is Cash on Delivery available for Bahawalpur and Rahim Yar Khan?',
    answer: 'Yes! Cash on Delivery via TCS Express is fully available across all cities and towns in Punjab and nationwide.',
    askedBy: 'Zahid Iqbal',
    answeredBy: 'Customer Support',
    createdAt: DateTime.now().subtract(const Duration(days: 9)),
    answeredAt: DateTime.now().subtract(const Duration(days: 9, hours: 1)),
  ),
  ProductQuestion(
    id: 'q_003',
    productId: 'p2',
    question: 'Is this product covered under official 1-year Apple international warranty in Pakistan?',
    answer: 'Yes, this MacBook comes with a full 1-year Apple International Limited Warranty claimable at authorized Apple service providers in Lahore, Karachi, and Islamabad.',
    askedBy: 'Dr. Shahzad',
    answeredBy: 'Authorized Apple Reseller',
    createdAt: DateTime.now().subtract(const Duration(days: 6)),
    answeredAt: DateTime.now().subtract(const Duration(days: 6, hours: 4)),
  ),
  ProductQuestion(
    id: 'q_004',
    productId: 'p3',
    question: 'Is this Samsung Galaxy S24 Ultra official PTA approved or Non-PTA?',
    answer: 'This is 100% official PTA approved with formal customs duty paid receipt included inside the box.',
    askedBy: 'Moiz Ur Rehman',
    answeredBy: 'Samsung Flagship Store',
    createdAt: DateTime.now().subtract(const Duration(days: 8)),
    answeredAt: DateTime.now().subtract(const Duration(days: 8, hours: 3)),
  ),
  ProductQuestion(
    id: 'q_005',
    productId: 'p4',
    question: 'Can I exchange the size if it does not fit properly after delivery?',
    answer: 'Absolutely. We offer a 7-day hassle-free doorstep size exchange. Simply request an exchange from your Order Details screen.',
    askedBy: 'Taimoor Shah',
    answeredBy: 'J. Flagship Store',
    createdAt: DateTime.now().subtract(const Duration(days: 4)),
    answeredAt: DateTime.now().subtract(const Duration(days: 4, hours: 1)),
  ),
];
