import '../../api/models/paginated_response.dart';
import '../../api/models/product_model.dart';
import '../../api/repositories/product_repository.dart';

class GetProductsUsecase {
  final ProductRepository _repo = ProductRepository();

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
