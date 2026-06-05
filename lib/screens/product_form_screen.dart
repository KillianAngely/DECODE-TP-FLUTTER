import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toastification/toastification.dart';

import '../api/models/product_model.dart';
import '../config/routes.dart';
import '../helpers/exceptions.dart';
import '../services/toast_service.dart';
import '../usecases/products/create_product_usecase.dart';
import '../usecases/products/update_product_usecase.dart';
import '../widgets/buttons/loading_button.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({this.product, super.key});

  final ProductModel? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  bool _isSubmitting = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.parse(_priceController.text.trim());

    try {
      if (_isEditing) {
        await UpdateProductUsecase().execute(
          id: widget.product!.id,
          name: name,
          description: description,
          price: price,
        );
      } else {
        await CreateProductUsecase().execute(
          name: name,
          description: description,
          price: price,
        );
      }

      if (!mounted) {
        return;
      }

      ToastService.showToast(
        _isEditing ? 'Produit modifié' : 'Produit créé',
        type: ToastificationType.success,
      );

      context.go(rtHome);
    } on ApiFieldsException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      final message = e.fields.entries.map((e) => e.value).join('\n');
      ToastService.showToast(message);
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
      });
      ToastService.showToast(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier le produit' : 'Ajouter un produit'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              spacing: 16,
              children: [
                TextFormField(
                  key: const ValueKey('product_name_field'),
                  controller: _nameController,
                  decoration: const InputDecoration(
                    label: Text('Nom'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: const ValueKey('product_description_field'),
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    label: Text('Description'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La description est obligatoire';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  key: const ValueKey('product_price_field'),
                  controller: _priceController,
                  decoration: const InputDecoration(
                    label: Text('Prix (€)'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(16)),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le prix est obligatoire';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Le prix doit être un nombre positif';
                    }
                    return null;
                  },
                ),
                LoadingButton(
                  key: const ValueKey('product_submit_button'),
                  onPressed: _onSubmit,
                  label: _isEditing ? 'Modifier' : 'Ajouter',
                  isLoading: _isSubmitting,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
