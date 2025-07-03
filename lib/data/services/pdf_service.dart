import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/stock_performa.dart';
import '../../presenation/viewmodels/stock_viewmodel.dart';
import '../models/company_info.dart';
import 'package:flutter/services.dart' show rootBundle;

class PdfService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<Uint8List> generateStockPerforma({
    required StockPerforma performa,
    required List<dynamic> items, // List of StockItem objects
    required String performaNumber,
    required String operationType,
    required CompanyInfo companyInfo,
    double deliveryCharge = 0,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);
    final pdf = pw.Document();

    double total = items.fold(0.0, (sum, item) => sum + item.quantity * item.product.sellPrice);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(30),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Center(
                child: pw.Text(
                  'FACTURE',
                  style: pw.TextStyle(
                    font: ttf,
                    fontSize: 32,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              // Header Card
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue50,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: pw.EdgeInsets.all(16),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildCompanyHeader(companyInfo, ttf),
                    pw.SizedBox(height: 8),
                    _buildPerformaHeader(performa, performaNumber, operationType, ttf),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Divider(thickness: 1.2, color: PdfColors.blueGrey400),
              _buildInvoiceTo(performa, operationType, ttf),
              pw.SizedBox(height: 16),
              _buildItemsTable(items, operationType, ttf),
              _buildChargesSummary(total, deliveryCharge, ttf),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  static pw.Widget _buildCompanyHeader(CompanyInfo company, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(company.name, style: pw.TextStyle(font: ttf, fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(company.address, style: pw.TextStyle(font: ttf, fontSize: 12)),
        pw.Text('Téléphone : ${company.phone}', style: pw.TextStyle(font: ttf, fontSize: 12)),
        if (company.email != null && company.email!.isNotEmpty)
          pw.Text('Email : ${company.email}', style: pw.TextStyle(font: ttf, fontSize: 12)),
      ],
    );
  }

  static pw.Widget _buildPerformaHeader(StockPerforma performa, String performaNumber, String operationType, pw.Font ttf) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: 8, bottom: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('ID de la facture : ${performa.id ?? '-'}', style: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text('Numéro de facture : $performaNumber', style: pw.TextStyle(font: ttf, fontSize: 12)),
              pw.Text("Type d'opération : ${operationType == 'in' ? 'Entrée de stock' : 'Sortie de stock'}", style: pw.TextStyle(font: ttf, fontSize: 12)),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Date : ${_formatDate(performa.createdAt)}', style: pw.TextStyle(font: ttf, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static pw.Widget _buildInvoiceTo(StockPerforma performa, String operationType, pw.Font ttf) {
    return pw.Container(
      margin: pw.EdgeInsets.only(top: 16, bottom: 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(operationType == 'in' ? 'De (Fournisseur)' : 'À (Client)', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.SizedBox(height: 4),
          if (performa.recipientName != null) pw.Text(performa.recipientName!, style: pw.TextStyle(font: ttf)),
          if (performa.recipientCompany != null) pw.Text(performa.recipientCompany!, style: pw.TextStyle(font: ttf)),
          if (performa.recipientAddress != null) pw.Text(performa.recipientAddress!, style: pw.TextStyle(font: ttf)),
          if (performa.recipientPhone != null) pw.Text('Téléphone : ${performa.recipientPhone!}', style: pw.TextStyle(font: ttf)),
        ],
      ),
    );
  }

  static pw.Widget _buildItemsTable(List<dynamic> items, String operationType, pw.Font ttf) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.blue900),
          children: [
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Qté', style: pw.TextStyle(font: ttf, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Description', style: pw.TextStyle(font: ttf, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Prix unitaire', style: pw.TextStyle(font: ttf, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
            pw.Padding(
              padding: pw.EdgeInsets.all(8),
              child: pw.Text('Montant', style: pw.TextStyle(font: ttf, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        ...items.map((item) {
          final total = item.quantity * item.product.sellPrice;
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: pw.Text('${item.quantity}', style: pw.TextStyle(font: ttf)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: pw.Text(item.product.name, style: pw.TextStyle(font: ttf)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: pw.Text('${item.product.sellPrice.toStringAsFixed(2)} DZD', style: pw.TextStyle(font: ttf)),
              ),
              pw.Padding(
                padding: pw.EdgeInsets.all(8),
                child: pw.Text('${total.toStringAsFixed(2)} DZD', style: pw.TextStyle(font: ttf)),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildChargesSummary(double total, double delivery, pw.Font ttf) {
    final grandTotal = total + delivery;
    return pw.Container(
      margin: pw.EdgeInsets.only(top: 16),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Livraison :', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(width: 16),
              pw.Text('${delivery.toStringAsFixed(2)} DZD', style: pw.TextStyle(font: ttf)),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text('Total :', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.SizedBox(width: 16),
              pw.Text('${grandTotal.toStringAsFixed(2)} DZD', style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  static Future<String> uploadPdfToStorage({
    required Uint8List pdfBytes,
    required String performaNumber,
  }) async {
    try {
      final fileName = '${performaNumber}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = 'performas/$fileName';
      
      await _supabase.storage
          .from('stock-performas')
          .uploadBinary(filePath, pdfBytes);
      
      final publicUrl = _supabase.storage
          .from('stock-performas')
          .getPublicUrl(filePath);
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload PDF: $e');
    }
  }

  static Future<StockPerforma> createPerformaRecord({
    required String stockLogId,
    required String pdfUrl,
  }) async {
    try {
      final response = await _supabase
          .from('stock_performas')
          .insert({
            'stock_log_id': stockLogId,
            'user_id': _supabase.auth.currentUser!.id,
            'pdf_url': pdfUrl,
          })
          .select()
          .single();
      
      return StockPerforma.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create performa record: $e');
    }
  }

  static Future<StockPerforma?> getPerformaByStockLogId(String stockLogId) async {
    try {
      final response = await _supabase
          .from('stock_performas')
          .select()
          .eq('stock_log_id', stockLogId)
          .single();
      
      return StockPerforma.fromJson(response);
    } catch (e) {
      return null; // No performa found
    }
  }

  static Future<List<StockPerforma>> getAllPerformas() async {
    try {
      final response = await _supabase
          .from('stock_performas')
          .select()
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => StockPerforma.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch performas: $e');
    }
  }
} 