import '../../api/models/product_model.dart';
import '../../api/repositories/product_repository.dart';

class CreateProductUsecase {
  final ProductRepository _repo = ProductRepository();

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
      if (image != null) 'picture': image,
    });
  }
}
