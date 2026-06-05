import 'package:cours/api/models/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const json = {
    'id': 'abc-123',
    'name': 'Clavier',
    'description': 'Un super clavier',
    'price': 49.99,
    'image': 'https://example.com/image.png',
  };

  test('fromJson mappe correctement tous les champs', () {
    final product = ProductModel.fromJson(json);

    expect(product.id, 'abc-123');
    expect(product.name, 'Clavier');
    expect(product.description, 'Un super clavier');
    expect(product.price, 49.99);
    expect(product.image, 'https://example.com/image.png');
  });

  test('fromJson accepte un price entier et le convertit en double', () {
    final product = ProductModel.fromJson({...json, 'price': 50});

    expect(product.price, 50.0);
    expect(product.price, isA<double>());
  });

  test('fromJson accepte image null', () {
    final product = ProductModel.fromJson({...json, 'image': null});

    expect(product.image, isNull);
  });

  test('toJson exclut image quand null', () {
    const product = ProductModel(
      id: 'abc-123',
      name: 'Clavier',
      description: 'Un super clavier',
      price: 49.99,
    );

    final map = product.toJson();

    expect(map.containsKey('image'), isFalse);
    expect(map['name'], 'Clavier');
    expect(map['description'], 'Un super clavier');
    expect(map['price'], 49.99);
  });

  test('toJson inclut image quand présente', () {
    const product = ProductModel(
      id: 'abc-123',
      name: 'Clavier',
      description: 'Un super clavier',
      price: 49.99,
      image: 'data:image/png;base64,abc',
    );

    final map = product.toJson();

    expect(map['image'], 'data:image/png;base64,abc');
  });
}
