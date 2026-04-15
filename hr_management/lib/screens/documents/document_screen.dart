import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../models/document.dart';
import '../../services/document_service.dart';
import '../../services/auth_service.dart';
import '../../app_colors.dart';
import '../../config/api_config.dart';
import '../../l10n/app_localizations.dart';

class DocumentScreen extends StatefulWidget {
  final String userRole;
  const DocumentScreen({super.key, required this.userRole});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final _documentService = DocumentService();
  final _authService     = AuthService();

  List<DocumentModel> _documents = [];
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String? _selectedType;
  int? _selectedEmployeeId;

  bool get _isAdmin   => widget.userRole == 'admin';
  bool get _isManager => widget.userRole == 'manager';

  final List<String> _types = [
    'All', 'citizenship', 'certificate', 'contract', 'photo', 'other',
  ];

  @override
  void initState() {
    super.initState();
    if (_isAdmin || _isManager) _loadEmployees();
    _load();
  }

  Future<void> _loadEmployees() async {
    final emps = await _authService.getAllEmployees();
    if (mounted) setState(() => _employees = emps);
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final type = (_selectedType == null || _selectedType == 'All')
          ? null
          : _selectedType;
      List<DocumentModel> docs;
      if (_isAdmin || _isManager) {
        // ── FIX 1: admin/manager fetch ALL documents ──────────────────────
        docs = await _documentService.getAllDocuments(
          employeeId: _selectedEmployeeId,
          documentType: type,
        );
      } else {
        docs = await _documentService.getMyDocuments(documentType: type);
      }
      if (mounted) setState(() { _documents = docs; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── FIX 2: Open file by building full URL, downloading to temp ─────────────
  Future<void> _openFile(DocumentModel doc) async {
    final l = AppLocalizations.of(context);
    final snack = ScaffoldMessenger.of(context);
    snack.showSnackBar(SnackBar(
      content: Text(l.downloadingFile),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 10),
    ));

    try {
      // file_url stored as /uploads/documents/filename.pdf
      // baseUrl = http://192.168.137.1/api
      // fullUrl = http://192.168.137.1/uploads/documents/filename.pdf
      final serverBase = ApiConfig.baseUrl.replaceAll('/api', '');
      final fullUrl    = doc.fileUrl.startsWith('http')
          ? doc.fileUrl
          : '$serverBase${doc.fileUrl}';

      final token    = await _authService.getToken();
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: {'Authorization': 'Bearer $token'},
      );

      snack.clearSnackBars();

      if (response.statusCode == 200) {
        final dir      = await getTemporaryDirectory();
        final fileName = doc.fileUrl.split('/').last;
        final file     = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);
        final result = await OpenFile.open(file.path);
        if (result.type != ResultType.done && mounted) {
          _showSnack('Cannot open: ${result.message}', error: true);
        }
      } else {
        if (mounted) _showSnack('File not found (${response.statusCode})', error: true);
      }
    } catch (e) {
      snack.clearSnackBars();
      if (mounted) _showSnack('Error: $e', error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.upload_file_rounded, color: Colors.white),
        label: Text(l.upload,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(l)),
            if ((_isAdmin || _isManager) && _employees.isNotEmpty)
              SliverToBoxAdapter(child: _buildEmployeeFilter(l)),
            SliverToBoxAdapter(child: _buildTypeFilter(l)),
            if (_isLoading)
              const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(
                      color: AppColors.primary)))
            else if (_documents.isEmpty)
              SliverFillRemaining(child: _buildEmpty(l))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => _buildDocCard(_documents[i], l),
                  childCount: _documents.length,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.headerGradient),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 20),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_rounded,
                color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text((_isAdmin || _isManager) ? l.allDocuments : l.myDocuments,
                style: const TextStyle(
                    color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w700)),
            Text('${_documents.length} documents',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildEmployeeFilter(AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: DropdownButtonFormField<int?>(
        value: _selectedEmployeeId,
        isDense: true,
        decoration: InputDecoration(
          labelText: 'Filter by employee',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: AppColors.surface,
        ),
        items: [
          const DropdownMenuItem<int?>(
              value: null, child: Text('All employees')),
          ..._employees.map((e) => DropdownMenuItem<int?>(
                value: e['id'] as int,
                child: Text(e['full_name'] ?? '',
                    overflow: TextOverflow.ellipsis),
              )),
        ],
        onChanged: (v) {
          setState(() => _selectedEmployeeId = v);
          _load();
        },
      ),
    );
  }

  Widget _buildTypeFilter(AppLocalizations l) {
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        itemCount: _types.length,
        itemBuilder: (_, i) {
          final type   = _types[i];
          final active = (_selectedType ?? 'All') == type;
          String label;
          switch (type) {
            case 'citizenship': label = l.citizenship; break;
            case 'certificate': label = l.certificate; break;
            case 'contract':    label = l.contract;    break;
            case 'photo':       label = l.photo;       break;
            case 'other':       label = l.other;       break;
            default:            label = l.all;
          }
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () { setState(() => _selectedType = type); _load(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: active ? AppColors.primary : AppColors.border)),
                child: Text(label,
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : AppColors.textSecondary)),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(AppLocalizations l) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.folder_open_rounded,
          size: 48, color: AppColors.primary.withOpacity(0.3)),
      const SizedBox(height: 14),
      Text(l.noDocuments,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w600,
              color: AppColors.textPrimary)),
    ]),
  );

  // ── FIX 3: card is tappable, shows employee name for admin ─────────────────
  Widget _buildDocCard(DocumentModel doc, AppLocalizations l) {
    return GestureDetector(
      onTap: () => _openFile(doc),  // ← FIX: tap opens the file
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(color: Color(0x081B4FD8),
                blurRadius: 8, offset: Offset(0, 2)),
          ],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(doc.typeIcon,
                  style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(doc.documentName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14,
                      color: AppColors.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              // FIX 3: show employee name when admin sees all docs
              if ((_isAdmin || _isManager) && doc.employeeName != null)
                Text(doc.employeeName!,
                    style: const TextStyle(
                        color: AppColors.primary, fontSize: 11,
                        fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              Text(
                '${doc.documentType[0].toUpperCase()}'
                '${doc.documentType.substring(1)}',
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11, fontWeight: FontWeight.w500)),
              Text(
                '${doc.fileSizeFormatted} · '
                '${DateFormat('dd MMM yyyy').format(doc.uploadedAt)}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.open_in_new_rounded,
                  size: 16, color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => _confirmDelete(doc, l),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.delete_outline_rounded,
                    size: 16, color: AppColors.error),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showUploadDialog() {
    String selectedType = 'other';
    int? targetEmpId;
    final nameCtrl = TextEditingController();
    File? selectedFile;
    String? fileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(
              24, 24, 24,
              MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2)),
            )),
            const Text('Upload Document',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            if ((_isAdmin || _isManager) && _employees.isNotEmpty) ...[
              DropdownButtonFormField<int?>(
                value: targetEmpId,
                decoration: InputDecoration(
                  labelText: 'Upload for employee',
                  prefixIcon: const Icon(Icons.person_rounded, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12))),
                items: [
                  const DropdownMenuItem<int?>(
                      value: null, child: Text('Myself')),
                  ..._employees.map((e) => DropdownMenuItem<int?>(
                        value: e['id'] as int,
                        child: Text(e['full_name'] ?? ''),
                      )),
                ],
                onChanged: (v) => setS(() => targetEmpId = v),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Document Name',
                prefixIcon: const Icon(Icons.edit_rounded, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 2))),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedType,
              decoration: InputDecoration(
                labelText: 'Document Type',
                prefixIcon: const Icon(Icons.label_rounded, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12))),
              items: ['citizenship', 'certificate', 'contract', 'photo', 'other']
                  .map((t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                            '${t[0].toUpperCase()}${t.substring(1)}'),
                      ))
                  .toList(),
              onChanged: (v) => setS(() => selectedType = v!),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final r = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: [
                    'pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'
                  ],
                );
                if (r != null && r.files.single.path != null) {
                  setS(() {
                    selectedFile = File(r.files.single.path!);
                    fileName = r.files.single.name;
                  });
                }
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selectedFile != null
                      ? AppColors.success.withOpacity(0.06)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selectedFile != null
                          ? AppColors.success
                          : AppColors.border)),
                child: Row(children: [
                  Icon(
                    selectedFile != null
                        ? Icons.check_circle_rounded
                        : Icons.attach_file_rounded,
                    color: selectedFile != null
                        ? AppColors.success
                        : AppColors.textSecondary,
                    size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      fileName ?? 'Choose file (PDF, JPG, PNG, Word)',
                      style: TextStyle(
                          color: selectedFile != null
                              ? AppColors.success
                              : AppColors.textSecondary,
                          fontSize: 13, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.4)),
                onPressed: selectedFile == null ||
                        nameCtrl.text.isEmpty
                    ? null
                    : () {
                        Navigator.pop(ctx);
                        _uploadFile(selectedFile!, selectedType,
                            nameCtrl.text.trim(), targetEmpId);
                      },
                child: const Text('Upload',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _uploadFile(
      File file, String type, String name, int? empId) async {
    final snack = ScaffoldMessenger.of(context);
    snack.showSnackBar(const SnackBar(
      content: Text('Uploading...'),
      behavior: SnackBarBehavior.floating));
    final result = await _documentService.uploadDocument(
      file: file, documentType: type, documentName: name, employeeId: empId);
    if (mounted) {
      snack.clearSnackBars();
      _showSnack(
        result['success'] ? 'Document uploaded!' : (result['error'] ?? 'Failed'),
        error: !result['success'],
      );
      if (result['success']) _load();
    }
  }

  Future<void> _confirmDelete(DocumentModel doc, AppLocalizations l) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(l.deleteDocument,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        content: Text(
          'Delete "${doc.documentName}"? This cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.cancel,
                style: const TextStyle(
                    color: AppColors.textSecondary))),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.delete)),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _documentService.deleteDocument(doc.id);
      if (mounted) {
        _showSnack(
          result['message'] ?? result['error'] ?? '',
          error: !result['success'],
        );
        if (result['success']) _load();
      }
    }
  }
}
