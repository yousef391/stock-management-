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

  Future<StockPerforma> createPerformaRecord(Map<String, dynamic> performaData) async {
    final performaResponse = await _client
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

  // Add more methods as needed for stock in/out, multi-product performa, etc.
}
