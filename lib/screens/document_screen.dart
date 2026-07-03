import 'package:flutter/material.dart';
import 'package:save_your_car/models/vehicles.dart';
import 'package:save_your_car/models/document.dart';
import 'package:save_your_car/services/document_service.dart';
import 'package:save_your_car/theme/figma_color.dart';
import 'package:save_your_car/theme/figma_text_style.dart';
import 'package:save_your_car/routes/app_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:save_your_car/config/api_config.dart';
import 'package:save_your_car/services/auth_service.dart';

class DocumentScreen extends StatefulWidget {
  final VehicleData vehicle;
  const DocumentScreen({super.key, required this.vehicle});

  @override
  State<DocumentScreen> createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final textStyle = FigmaTextStyles();
  List<DocumentData> _documents = [];
  List<DocumentData> _filtered = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final docs = await DocumentService.getVehicleDocuments(widget.vehicle.id!);
    if (mounted) {
      setState(() {
        _documents = docs;
        _applyFilter();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filtered = List.from(_documents);
    } else {
      final q = _searchQuery.toLowerCase();
      _filtered = _documents.where((d) {
        return d.name.toLowerCase().contains(q) ||
            d.typeDisplayName.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> _delete(DocumentData doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer le document'),
        content: Text('Supprimer "${doc.name}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final ok = await DocumentService.deleteDocument(doc.id);
    if (ok && mounted) {
      setState(() {
        _documents.removeWhere((d) => d.id == doc.id);
        _applyFilter();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document supprimé'), backgroundColor: FigmaColors.primaryMain),
      );
    }
  }

  Future<void> _download(DocumentData doc) async {
    final token = await AuthService.getToken();
    if (token == null) return;
    final url = '${ApiConfig.baseUrl}/documents/${doc.id}/download?token=$token';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openScanner() async {
    await Navigator.pushNamed(
      context,
      AppRouter.scanner,
      arguments: widget.vehicle,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: FigmaColors.primaryMain,
        onPressed: _openScanner,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: const BoxDecoration(color: FigmaColors.neutral100),
      child: Stack(
        children: [
          Positioned(
            top: 52,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_left, color: Colors.white),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Documents',
                  style: textStyle.textXXLBold.copyWith(color: Colors.white),
                ),
                Text(
                  widget.vehicle.brand.isNotEmpty
                      ? '${widget.vehicle.brand} ${widget.vehicle.model}'
                      : widget.vehicle.plate,
                  style: textStyle.textMRegular.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: -22,
            left: 16,
            right: 16,
            child: _buildSearchBar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Chercher un document…',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (v) {
                setState(() {
                  _searchQuery = v;
                  _applyFilter();
                });
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() {
                  _searchQuery = '';
                  _applyFilter();
                });
              },
              child: const Icon(Icons.close, color: Colors.grey, size: 18),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: FigmaColors.primaryMain));
    }
    if (_filtered.isEmpty) {
      return _buildEmpty();
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: FigmaColors.primaryMain,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: _filtered.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _DocumentCard(
            doc: _filtered[i],
            onDelete: () => _delete(_filtered[i]),
            onDownload: () => _download(_filtered[i]),
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'Aucun document' : 'Aucun résultat',
            style: textStyle.textXLBold.copyWith(color: FigmaColors.neutral70),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Ajoutez votre premier document\nen appuyant sur le bouton +'
                : 'Essayez un autre terme de recherche',
            textAlign: TextAlign.center,
            style: textStyle.textMRegular.copyWith(color: FigmaColors.neutral70),
          ),
        ],
      ),
    );
  }
}

class _DocumentCard extends StatelessWidget {
  final DocumentData doc;
  final VoidCallback onDelete;
  final VoidCallback onDownload;

  const _DocumentCard({required this.doc, required this.onDelete, required this.onDownload});

  Color get _typeColor {
    switch (doc.type) {
      case 'carte_grise': return const Color(0xFF3B82F6);
      case 'assurance': return const Color(0xFF10B981);
      case 'controle_technique': return const Color(0xFFF59E0B);
      case 'facture': return const Color(0xFF8B5CF6);
      default: return FigmaColors.primaryMain;
    }
  }

  IconData get _typeIcon {
    switch (doc.type) {
      case 'carte_grise': return Icons.credit_card;
      case 'assurance': return Icons.shield_outlined;
      case 'controle_technique': return Icons.check_circle_outline;
      case 'facture': return Icons.receipt_long_outlined;
      default: return Icons.description_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = FigmaTextStyles();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FigmaColors.neutral10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _typeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon, color: _typeColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(doc.name, style: ts.textLBold.copyWith(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(doc.typeDisplayName, style: ts.captionSMedium.copyWith(color: _typeColor, fontSize: 10)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('dd/MM/yyyy').format(doc.createdAt),
                      style: ts.captionSMedium.copyWith(color: FigmaColors.neutral70, fontSize: 10),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      doc.fileSizeFormatted,
                      style: ts.captionSMedium.copyWith(color: FigmaColors.neutral70, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined, color: FigmaColors.primaryMain, size: 20),
            onPressed: onDownload,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
