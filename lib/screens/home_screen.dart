import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../api/models/product_model.dart';
import '../config/routes.dart';
import '../helpers/exceptions.dart';
import '../services/toast_service.dart';
import '../usecases/products/delete_product_usecase.dart';
import '../usecases/products/get_products_usecase.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GetProductsUsecase _getProducts = GetProductsUsecase();
  final DeleteProductUsecase _deleteProduct = DeleteProductUsecase();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ProductModel> _products = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _totalCount = 0;
  String? _currentSearch;
  Timer? _debounce;

  bool get _hasMore => _products.length < _totalCount;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final search = query.trim().isEmpty ? null : query.trim();
      _currentSearch = search;
      _fetchProducts(search: search);
    });
  }

  Future<void> _fetchProducts({String? search}) async {
    setState(() {
      _isLoading = true;
      _currentPage = 1;
      _currentSearch = search;
    });
    try {
      final response = await _getProducts.execute(search: search, page: 1);
      if (!mounted) {
        return;
      }
      setState(() {
        _products = response.rows;
        _totalCount = response.count;
        _currentPage = 1;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoading = false);
      ToastService.showToast(e.message);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final response = await _getProducts.execute(
        search: _currentSearch,
        page: nextPage,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _products.addAll(response.rows);
        _currentPage = nextPage;
        _isLoadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isLoadingMore = false);
      ToastService.showToast(e.message);
    }
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le produit'),
        content: Text('Voulez-vous supprimer "${product.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _deleteProduct.execute(product.id);
      if (!mounted) {
        return;
      }
      ToastService.showToast(
        '${product.name} supprimé',
        type: ToastificationType.success,
      );
      _fetchProducts();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      ToastService.showToast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      key: const ValueKey('home_screen'),
      appBar: AppBar(
        title: const Text('Liste des produits'),
      ),
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add_product_fab'),
        onPressed: () => context.push(rtProductCreate),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un produit'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _fetchProducts();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text('Aucun produit'))
                    : RefreshIndicator(
                        onRefresh: () => _fetchProducts(search: _currentSearch),
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == _products.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            final product = _products[index];
                            return ProductCard(
                              product: product,
                              onTap: () =>
                                  context.push(rtProductEdit, extra: product),
                              onDelete: () => _confirmDelete(product),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
