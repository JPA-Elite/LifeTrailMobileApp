class ItemModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final int price;
  final bool stackable;
  final Map<String, int> effects;

  const ItemModel({
    required this.id,
    required this.name,
    this.description = '',
    this.category = 'misc',
    this.price = 0,
    this.stackable = true,
    this.effects = const {},
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
    id: json['id'] as String,
    name: json['name'] as String? ?? json['id'] as String,
    description: json['description'] as String? ?? '',
    category: json['category'] as String? ?? 'misc',
    price: (json['price'] as num?)?.toInt() ?? 0,
    stackable: json['stackable'] as bool? ?? true,
    effects: ((json['effects'] as Map?) ?? {}).map(
      (k, v) => MapEntry(k.toString(), (v as num).toInt()),
    ),
  );
}

class InventoryStack {
  final String itemId;
  final int count;

  const InventoryStack(this.itemId, this.count);

  InventoryStack copyWith({int? count}) =>
      InventoryStack(itemId, count ?? this.count);

  Map<String, dynamic> toJson() => {'itemId': itemId, 'count': count};

  factory InventoryStack.fromJson(Map<String, dynamic> json) => InventoryStack(
    json['itemId'] as String? ?? json['item_id'] as String? ?? '',
    (json['count'] as num?)?.toInt() ?? 1,
  );
}
