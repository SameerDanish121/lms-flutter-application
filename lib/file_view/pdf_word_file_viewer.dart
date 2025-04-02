import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';

class PdfViewerScreen extends StatefulWidget {
  final String? filePath;
  final String? fileUrl;
  final String? filename;
  const PdfViewerScreen({
    this.filePath,
    this.fileUrl,
    Key? key,
    this.filename,
  }) : super(key: key);

  @override
  _PdfViewerScreenState createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late PdfController _pdfController;
  bool _isLoading = true;
  int? _totalPages;
  int _currentPage = 1;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      if (widget.filePath != null) {
        _pdfController = PdfController(
          document: PdfDocument.openFile(widget.filePath!),
        );
      } else if (widget.fileUrl != null) {
        final response = await Dio().get(
          widget.fileUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        _pdfController = PdfController(
          document: PdfDocument.openData(response.data),
        );
      }

      _totalPages = await _pdfController.pagesCount;
      setState(() {});
    } catch (e) {
      debugPrint('PDF Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load PDF: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= (_totalPages ?? 1)) {
      _pdfController.animateToPage(
        page,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  Future<void> _openWithExternalApp() async {
    try {
      if (widget.filePath != null) {
        await OpenFilex.open(widget.filePath!);
      } else if (widget.fileUrl != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/${widget.filename ?? 'document.pdf'}');
        await Dio().download(widget.fileUrl!, file.path);
        await OpenFilex.open(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open file: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          width: MediaQuery.of(context).size.width * 0.6,
          child: Text(
            widget.filename ?? 'PDF Viewer',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        actions: [
          if (_totalPages != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '$_currentPage/$_totalPages',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openWithExternalApp,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          PdfView(
            controller: _pdfController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
          ),
          if (_showControls)
            Positioned(
              bottom: 16,
              right: 16,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'page_prev',
                    child: const Icon(Icons.arrow_upward),
                    onPressed: () => _goToPage(_currentPage - 1),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'page_next',
                    child: const Icon(Icons.arrow_downward),
                    onPressed: () => _goToPage(_currentPage + 1),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(_showControls ? Icons.visibility_off : Icons.visibility),
        onPressed: _toggleControls,
      ),
    );
  }
}