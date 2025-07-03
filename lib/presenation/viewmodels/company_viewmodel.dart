import 'package:flutter/material.dart';
import '../../data/models/company_info.dart';
import '../../data/repo/company_repository.dart';

class CompanyViewModel extends ChangeNotifier {
  final CompanyRepository _repository;
  CompanyInfo? _companyInfo;
  bool _isLoading = false;
  String? _error;

  CompanyInfo? get companyInfo => _companyInfo;
  bool get isLoading => _isLoading;
  String? get error => _error;

  CompanyViewModel(this._repository);

  Future<void> fetchCompanyInfo(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _companyInfo = await _repository.getCompanyInfo(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCompanyInfo(CompanyInfo company) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.updateCompanyInfo(company);
      _companyInfo = company;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createCompanyInfo(CompanyInfo company) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _repository.createCompanyInfo(company);
      _companyInfo = company;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 