class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String? image;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'price': price,
      if (image != null) 'image': image,
    };
  }
}
