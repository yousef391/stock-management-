import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/stock_performa.dart';
import '../../presenation/screens/stock_screen.dart'; // For StockItem
import '../services/pdf_service.dart';

class StockRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> fetchProducts(String userId) async {
    final response = await _client
        .from('products')
        .select()
        .eq('user_id', userId)
        .order('name');
    return (response as List)
        .map((product) => Product.fromMap(product))
        .toList();
  }

  Future<List<StockPerforma>> fetchPerformas(String userId) async {
    final response = await _client
        .from('stock_performas')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((performa) => StockPerforma.fromJson(performa))
        .toList();
  }

  Future<void> updateProductStock({
    required String productId,
    required int newStock,
  }) async {
    await _client
        .from('products')
        .update({'stock': newStock})
        .eq('id', productId)
        .select();
  }

  Future<StockPerforma> createPerformaRecord(
    Map<String, dynamic> performaData,
  ) async {
    final performaResponse =
        await _client
            .from('stock_performas')
            .insert(performaData)
            .select()
            .single();
    return StockPerforma.fromJson(performaResponse);
  }

  Future<void> updatePerformaPdfUrl({
    required String performaId,
    required String pdfUrl,
  }) async {
    await _client
        .from('stock_performas')
        .update({'pdf_url': pdfUrl})
        .eq('id', performaId);
  }

  // PDF generation and upload
  Future<Uint8List> generateStockPerformaPdf({
    required StockPerforma performa,
    required List<dynamic> items,
    required String performaNumber,
    required String operationType,
    required companyInfo,
    double deliveryCharge = 0,
  }) async {
    return await PdfService.generateStockPerforma(
      performa: performa,
      items: items,
      performaNumber: performaNumber,
      operationType: operationType,
      companyInfo: companyInfo,
      deliveryCharge: deliveryCharge,
    );
  }

  Future<String?> uploadFacturePdf(Uint8List pdfBytes, String fileName) async {
    return await PdfService.uploadPdfToStorage(
      pdfBytes: pdfBytes,
      performaNumber: fileName,
    );
  }

  Future<void> deletePerformaAndResetProducts(StockPerforma performa, String userId) async {
    // For each item in the performa, reset the product stock
    for (final item in performa.items) {
      // Fetch the product
      final response = await _client
          .from('products')
          .select()
          .eq('id', item.productId)
          .eq('user_id', userId)
          .single();
      if (response == null) continue;
      final product = Product.fromMap(response);
      // Reset stock: if performa.type == 'in', subtract; if 'out', add
      int resetStock = performa.type == 'in'
          ? product.stock - item.quantity
          : product.stock + item.quantity;
      if (resetStock < 0) resetStock = 0;
      await updateProductStock(productId: product.id, newStock: resetStock);
    }
    // Delete the performa
    print('Deleting performa: id=${performa.id}, userId=$userId');
    final deleteResponse = await _client
        .from('stock_performas')
        .delete()
        .eq('id', performa.id)
        .eq('user_id', userId)
        .select();
    print('Delete response: $deleteResponse');
  }

  // Add more methods as needed for stock in/out, multi-product performa, etc.
}
