import '../models/product_model.dart';
import 'model_repository.dart';

class ProductRepository extends ModelRepository<ProductModel> {
  ProductRepository()
      : super(
          uri: 'products',
          fromJson: ProductModel.fromJson,
        );
}
