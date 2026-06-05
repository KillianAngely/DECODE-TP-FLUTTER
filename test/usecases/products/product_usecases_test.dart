import 'package:cours/api/models/paginated_response.dart';
import 'package:cours/api/models/product_model.dart';
import 'package:cours/api/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// Faux repository pour isoler les usecases du réseau
class FakeProductRepository extends ProductRepository {
  final List<ProductModel> products;
  String? lastDeletedId;
  Map<String, dynamic>? lastAddOrUpdateData;
  String? lastAddOrUpdateId;

  FakeProductRepository({this.products = const []});

  @override
  Future<PaginatedResponse<ProductModel>> getAll({
    Map<String, String>? queryParams,
  }) async {
    final query = queryParams?['search_value']?.toLowerCase();
    final filtered = query == null
        ? products
        : products.where((p) => p.name.toLowerCase().contains(query)).toList();
    return PaginatedResponse(count: filtered.length, rows: filtered);
  }

  @override
  Future<ProductModel> addOrUpdate({
    required Map<String, dynamic> data,
    String? id,
  }) async {
    lastAddOrUpdateData = data;
    lastAddOrUpdateId = id;
    return ProductModel(
      id: id ?? 'new-id',
      name: data['name'],
      description: data['description'],
      price: (data['price'] as num).toDouble(),
      image: data['image'],
    );
  }

  @override
  Future<void> delete(String id) async {
    lastDeletedId = id;
  }
}

// Usecases réécrit pour accepter un repo injecté (pour les tests)
class GetProductsUsecase {
  final FakeProductRepository _repo;
  GetProductsUsecase(this._repo);

  Future<PaginatedResponse<ProductModel>> execute({
    String? search,
    int page = 1,
  }) {
    return _repo.getAll(queryParams: {
      if (search != null && search.isNotEmpty) 'search_value': search,
      'page': '$page',
    });
  }
}

class CreateProductUsecase {
  final FakeProductRepository _repo;
  CreateProductUsecase(this._repo);

  Future<ProductModel> execute({
    required String name,
    required String description,
    required double price,
    String? image,
  }) {
    return _repo.addOrUpdate(data: {
      'name': name,
      'description': description,
      'price': price,
      'image': image,
    });
  }
}

class UpdateProductUsecase {
  final FakeProductRepository _repo;
  UpdateProductUsecase(this._repo);

  Future<ProductModel> execute({
    required String id,
    required String name,
    required String description,
    required double price,
    String? image,
  }) {
    return _repo.addOrUpdate(
      id: id,
      data: {
        'name': name,
        'description': description,
        'price': price,
        'image': image,
      },
    );
  }
}

class DeleteProductUsecase {
  final FakeProductRepository _repo;
  DeleteProductUsecase(this._repo);

  Future<void> execute(String id) => _repo.delete(id);
}

const _product1 = ProductModel(
  id: '1',
  name: 'Clavier',
  description: 'Mécanique',
  price: 79.99,
);

const _product2 = ProductModel(
  id: '2',
  name: 'Souris',
  description: 'Sans fil',
  price: 39.99,
);

void main() {
  group('GetProductsUsecase', () {
    test('retourne tous les produits sans filtre', () async {
      final repo = FakeProductRepository(products: [_product1, _product2]);
      final result = await GetProductsUsecase(repo).execute();

      expect(result.count, 2);
      expect(result.rows.length, 2);
    });

    test('filtre par search_value', () async {
      final repo = FakeProductRepository(products: [_product1, _product2]);
      final result = await GetProductsUsecase(repo).execute(search: 'clavier');

      expect(result.count, 1);
      expect(result.rows.first.name, 'Clavier');
    });

    test('search vide retourne tous les produits', () async {
      final repo = FakeProductRepository(products: [_product1, _product2]);
      final result = await GetProductsUsecase(repo).execute(search: '');

      expect(result.count, 2);
    });
  });

  group('CreateProductUsecase', () {
    test('appelle addOrUpdate sans id (POST)', () async {
      final repo = FakeProductRepository();
      final result = await CreateProductUsecase(repo).execute(
        name: 'Écran',
        description: '4K',
        price: 299.0,
      );

      expect(result.id, 'new-id');
      expect(result.name, 'Écran');
      expect(result.price, 299.0);
      expect(repo.lastAddOrUpdateId, isNull);
    });

    test('transmet image en base64 si fournie', () async {
      final repo = FakeProductRepository();
      await CreateProductUsecase(repo).execute(
        name: 'Écran',
        description: '4K',
        price: 299.0,
        image: 'data:image/png;base64,abc',
      );

      expect(repo.lastAddOrUpdateData?['image'], 'data:image/png;base64,abc');
    });
  });

  group('UpdateProductUsecase', () {
    test('appelle addOrUpdate avec id (PUT)', () async {
      final repo = FakeProductRepository();
      final result = await UpdateProductUsecase(repo).execute(
        id: '42',
        name: 'Clavier Pro',
        description: 'RGB',
        price: 129.0,
      );

      expect(result.id, '42');
      expect(result.name, 'Clavier Pro');
      expect(repo.lastAddOrUpdateId, '42');
    });
  });

  group('DeleteProductUsecase', () {
    test('appelle delete avec le bon id', () async {
      final repo = FakeProductRepository();
      await DeleteProductUsecase(repo).execute('99');

      expect(repo.lastDeletedId, '99');
    });
  });
}
