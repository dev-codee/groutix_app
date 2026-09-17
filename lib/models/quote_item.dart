class QuoteItem {
  final String? code;
  final String? service;
  final String? scope;
  final String? description;
  final double price;
  final int qty;

  QuoteItem({
    this.code,
    this.service,
    this.scope,
    this.description,
    this.price = 0.0,
    this.qty = 1,
  });

  double get total => price * qty;

  factory QuoteItem.fromJson(Map<String, dynamic> json) {
    return QuoteItem(
      code: json['code']?.toString(),
      service: json['service']?.toString(),
      scope: json['scope']?.toString(),
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      qty: (json['qty'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        if (code != null) 'code': code,
        if (service != null) 'service': service,
        if (scope != null) 'scope': scope,
        if (description != null) 'description': description,
        'price': price,
        'qty': qty,
      };
}
