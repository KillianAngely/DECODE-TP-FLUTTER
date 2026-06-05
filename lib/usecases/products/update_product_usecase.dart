import '../../api/models/product_model.dart';
import '../../api/repositories/product_repository.dart';

class UpdateProductUsecase {
  final ProductRepository _repo = ProductRepository();

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
