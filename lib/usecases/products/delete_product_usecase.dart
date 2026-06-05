import '../../api/repositories/product_repository.dart';

class DeleteProductUsecase {
  final ProductRepository _repo = ProductRepository();

  Future<void> execute(String id) {
    return _repo.delete(id);
  }
}
