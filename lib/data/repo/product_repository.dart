import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';

class ProductRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> fetchProducts(String userId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((product) => Product.fromMap(product))
        .toList();
  }

  Future<void> createProduct({
    required String userId,
    required String name,
    required double buyPrice,
    required double sellPrice,
    required int stock,
  }) async {
    final productData = {
      'user_id': userId,
      'name': name,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'stock': stock,
    };
    await _client.from('products').insert(productData);
  }

  Future<void> updateProduct(Product product) async {
    await _client
        .from('products')
        .update(product.toMap())
        .eq('id', product.id);
  }

  Future<void> deleteProduct(String productId) async {
    await _client.from('products').delete().eq('id', productId);
  }
}
