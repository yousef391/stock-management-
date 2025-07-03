import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/company_viewmodel.dart';
import '../../data/models/company_info.dart';
import '../viewmodels/auth_viewmodel.dart';

class CompanyInfoScreen extends StatefulWidget {
  const CompanyInfoScreen({Key? key}) : super(key: key);

  @override
  State<CompanyInfoScreen> createState() => _CompanyInfoScreenState();
}

class _CompanyInfoScreenState extends State<CompanyInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final companyVM = context.read<CompanyViewModel>();
      final userId = context.read<AuthViewModel>().user?.id;
      if (userId != null) {
        companyVM.fetchCompanyInfo(userId).then((_) {
          final info = companyVM.companyInfo;
          if (info != null) {
            _nameController.text = info.name;
            _addressController.text = info.address;
            _phoneController.text = info.phone;
            _emailController.text = info.email ?? '';
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveCompanyInfo() async {
    if (!_formKey.currentState!.validate()) return;
    final companyVM = context.read<CompanyViewModel>();
    final userId = context.read<AuthViewModel>().user?.id;
    if (userId == null) return;
    final info = CompanyInfo(
      id: companyVM.companyInfo?.id,
      userId: userId,
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
    );
    if (companyVM.companyInfo == null) {
      await companyVM.createCompanyInfo(info);
    } else {
      await companyVM.updateCompanyInfo(info);
    }
    if (mounted && companyVM.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Company info saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanyViewModel>(
      builder: (context, companyVM, child) {
        final info = companyVM.companyInfo;
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: Text('Company Info'),
            backgroundColor: Colors.white,
            elevation: 1,
          ),
          body: companyVM.isLoading
              ? Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 600;
                    return Center(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(
                          vertical: isMobile ? 12 : 24,
                          horizontal: isMobile ? 12 : 24,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 800),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (info != null) ...[
                                Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 12 : 20)),
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  child: Padding(
                                    padding: EdgeInsets.all(isMobile ? 16 : 24.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.business, color: Colors.indigo, size: isMobile ? 24 : 32),
                                            SizedBox(width: isMobile ? 12 : 16),
                                            Expanded(
                                              child: Text(
                                                info.name,
                                                style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isMobile ? 8 : 12),
                                        Row(
                                          children: [
                                            Icon(Icons.location_on, color: Colors.grey[600], size: isMobile ? 16 : 18),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                info.address,
                                                style: TextStyle(fontSize: isMobile ? 13 : 15, color: Colors.grey[800]),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isMobile ? 4 : 6),
                                        Row(
                                          children: [
                                            Icon(Icons.phone, color: Colors.grey[600], size: isMobile ? 16 : 18),
                                            SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                info.phone,
                                                style: TextStyle(fontSize: isMobile ? 13 : 15, color: Colors.grey[800]),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (info.email != null && info.email!.isNotEmpty) ...[
                                          SizedBox(height: isMobile ? 4 : 6),
                                          Row(
                                            children: [
                                              Icon(Icons.email, color: Colors.grey[600], size: isMobile ? 16 : 18),
                                              SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  info.email!,
                                                  style: TextStyle(fontSize: isMobile ? 13 : 15, color: Colors.grey[800]),
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Divider(thickness: 1.2),
                                ),
                              ],
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isMobile ? 16 : 24)),
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: Padding(
                                  padding: EdgeInsets.all(isMobile ? 16 : 32.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Section Header
                                        Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.indigo, size: isMobile ? 18 : 20),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                info == null ? 'Enter Company Details' : 'Edit Company Details',
                                                style: TextStyle(fontSize: isMobile ? 16 : 18, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: isMobile ? 16 : 24),
                                        if (companyVM.error != null)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 16),
                                            child: Text(
                                              companyVM.error!,
                                              style: TextStyle(color: Colors.red, fontSize: isMobile ? 12 : 14),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 3,
                                            ),
                                          ),
                                        TextFormField(
                                          controller: _nameController,
                                          decoration: InputDecoration(
                                            labelText: 'Company Name',
                                            prefixIcon: Icon(Icons.apartment),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter company name' : null,
                                        ),
                                        SizedBox(height: isMobile ? 16 : 20),
                                        TextFormField(
                                          controller: _addressController,
                                          decoration: InputDecoration(
                                            labelText: 'Address',
                                            prefixIcon: Icon(Icons.location_on),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter address' : null,
                                        ),
                                        SizedBox(height: isMobile ? 16 : 20),
                                        TextFormField(
                                          controller: _phoneController,
                                          decoration: InputDecoration(
                                            labelText: 'Phone',
                                            prefixIcon: Icon(Icons.phone),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                          validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone' : null,
                                        ),
                                        SizedBox(height: isMobile ? 16 : 20),
                                        TextFormField(
                                          controller: _emailController,
                                          decoration: InputDecoration(
                                            labelText: 'Email (optional)',
                                            prefixIcon: Icon(Icons.email),
                                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                          ),
                                          keyboardType: TextInputType.emailAddress,
                                        ),
                                        SizedBox(height: isMobile ? 24 : 32),
                                        SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            icon: Icon(Icons.save),
                                            onPressed: companyVM.isLoading ? null : _saveCompanyInfo,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigo,
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16),
                                              textStyle: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                            ),
                                            label: Text('Save'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
} 