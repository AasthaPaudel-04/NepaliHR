import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../models/document.dart';
import '../../services/document_service.dart';

class DocumentScreen extends StatefulWidget {
  final String userRole;
  const DocumentScreen({super.key, required this.userRole});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final DocumentService _documentService = DocumentService();
  List<DocumentModel> _documents = [];
  bool _isLoading = true;
  String? _selectedType;

  final List<String> _types = ['All', 'citizenship', 'certificate', 'contract', 'photo', 'other'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final docs = await _documentService.getMyDocuments(
        documentType: _selectedType == 'All' || _selectedType == null ? null : _selectedType);
    setState(() { _documents = docs; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          _buildTypeFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _documents.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.folder_open, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No documents found', style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _documents.length,
                          itemBuilder: (_, index) => _buildDocCard(_documents[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilter() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _types.length,
        itemBuilder: (_, index) {
          final type = _types[index];
          final isSelected = (_selectedType ?? 'All') == type;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(type[0].toUpperCase() + type.substring(1)),
              selected: isSelected,
              selectedColor: Colors.deepPurple.shade100,
              checkmarkColor: Colors.deepPurple,
              onSelected: (_) {
                setState(() => _selectedType = type);
                _load();
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocCard(DocumentModel doc) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.deepPurple.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(doc.typeIcon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(doc.documentName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              doc.documentType[0].toUpperCase() + doc.documentType.substring(1),
              style: TextStyle(color: Colors.deepPurple.shade400, fontSize: 12),
            ),
            Text(
              '${doc.fileSizeFormatted} • ${DateFormat('dd MMM yyyy').format(doc.uploadedAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            if (doc.uploadedByName != null)
              Text('By: ${doc.uploadedByName}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') _confirmDelete(doc);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog() {
    String selectedType = 'other';
    final nameController = TextEditingController();
    File? selectedFile;
    String? fileName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Upload Document', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Document Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.edit),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Document Type', border: OutlineInputBorder()),
                items: ['citizenship', 'certificate', 'contract', 'photo', 'other']
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t[0].toUpperCase() + t.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) => setS(() => selectedType = v!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
                  );
                  if (result != null && result.files.single.path != null) {
                    setS(() {
                      selectedFile = File(result.files.single.path!);
                      fileName = result.files.single.name;
                    });
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: Text(fileName ?? 'Choose File (PDF, JPG, PNG, Word)'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: selectedFile == null || nameController.text.isEmpty
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          _uploadFile(selectedFile!, selectedType, nameController.text.trim());
                        },
                  child: const Text('Upload', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _uploadFile(File file, String type, String name) async {
    final snackBar = ScaffoldMessenger.of(context);
    snackBar.showSnackBar(const SnackBar(content: Text('Uploading...')));

    final result = await _documentService.uploadDocument(
      file: file,
      documentType: type,
      documentName: name,
    );

    if (mounted) {
      snackBar.clearSnackBars();
      snackBar.showSnackBar(SnackBar(
        content: Text(result['success'] ? 'Document uploaded!' : (result['error'] ?? 'Upload failed')),
        backgroundColor: result['success'] ? Colors.green : Colors.red,
      ));
      if (result['success']) _load();
    }
  }

  Future<void> _confirmDelete(DocumentModel doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Document'),
        content: Text('Delete "${doc.documentName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final result = await _documentService.deleteDocument(doc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? result['error'] ?? '')));
        if (result['success']) _load();
      }
    }
  }
}