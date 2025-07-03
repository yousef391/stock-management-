import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/company_info.dart';

class CompanyRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<CompanyInfo?> getCompanyInfo(String userId) async {
    try {
      final response = await _client
          .from('companies')
          .select()
          .eq('user_id', userId)
          .single();
      if (response == null) return null;
      return CompanyInfo.fromMap(response);
    } catch (e) {
      // If no row exists, Supabase throws an error, so return null
      return null;
    }
  }

  Future<void> updateCompanyInfo(CompanyInfo company) async {
    if (company.id == null) {
      throw ArgumentError('Company id cannot be null when updating company info');
    }
    await _client
        .from('companies')
        .update(company.toMap())
        .eq('id', company.id!);
  }

  Future<void> createCompanyInfo(CompanyInfo company) async {
    await _client
        .from('companies')
        .insert(company.toMap());
  }
} 