import '../../api/models/product_model.dart';
import '../../api/repositories/product_repository.dart';

class UpdateProductUsecase {
  final ProductRepository _repo = ProductRepository();

  Future<ProductModel> execute({
    required String id,
    required String name,
    required String description,
    required double price,
    String? imageBase64,
    String imageExtension = 'jpg',
  }) {
    return _repo.addOrUpdate(
      id: id,
      data: {
        'name': name,
        'description': description,
        'price': price,
        if (imageBase64 != null)
          'picture': {
            'name': 'photo',
            'base64': imageBase64,
            'extension': imageExtension,
            'status': 'CREATED',
          },
      },
    );
  }
}
