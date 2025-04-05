import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../Theme/theme.dart';

class PdfViewerScreen extends StatefulWidget {
  final String fileUrl;
  final String? filename;

  const PdfViewerScreen({
    required this.fileUrl,
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
  double _currentScale = 1.0;
  String? _errorMessage;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  File? _localFile;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      setState(() => _isDownloading = true);

      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${widget.filename ?? 'document.pdf'}';
      _localFile = File(filePath);

      // Always download fresh copy from URL
      await Dio().download(
        widget.fileUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      _pdfController = PdfController(
        document: PdfDocument.openFile(filePath),
      );
      _pdfController.loadingState.addListener(() {
        if (_pdfController.loadingState.value == PdfLoadingState.success) {
            _totalPages = _pdfController.pagesCount;
        }
      });
      _totalPages = _pdfController.pagesCount;

      setState(() {
        _isLoading = false;
        _isDownloading = false;
      });
    } catch (e) {
      debugPrint('PDF Error: $e');
      setState(() {
        _isLoading = false;
        _isDownloading = false;
        _errorMessage = 'Failed to load PDF: ${e.toString()}';
      });
    }
  }

  void _zoomIn() {
    setState(() {
      _currentScale = (_currentScale + 0.1).clamp(0.5, 3.0);
    });
  }

  void _zoomOut() {
    setState(() {
      _currentScale = (_currentScale - 0.1).clamp(0.5, 3.0);
    });
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
      setState(() => _isDownloading = true);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${widget.filename ?? 'document.pdf'}');

      await Dio().download(
        widget.fileUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() => _isDownloading = false);
      await OpenFilex.open(file.path);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open file: ${e.toString()}',
                style: AppTheme.bodyStyle.copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sharePdf() async {
    try {
      setState(() => _isDownloading = true);

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/${widget.filename ?? 'document.pdf'}');

      await Dio().download(
        widget.fileUrl,
        file.path,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() => _isDownloading = false);
      await Share.shareXFiles([XFile(file.path)], text: 'Sharing PDF: ${widget.filename ?? 'Document'}');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share file: ${e.toString()}',
                style: AppTheme.bodyStyle.copyWith(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToTop() {
    _goToPage(1);
  }

  void _scrollDown() {
    if (_currentPage < (_totalPages ?? 1)) {
      _goToPage(_currentPage + 1);
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
        title: Text(
          widget.filename ?? 'PDF Viewer',
          overflow: TextOverflow.ellipsis,
          style: AppTheme.headingStyle.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_totalPages != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_currentPage/${_totalPages ?? "?"}',
                    style: AppTheme.captionStyle.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'open':
                  _openWithExternalApp();
                  break;
                case 'share':
                  _sharePdf();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'open',
                child: Row(
                  children: [
                    Icon(Icons.open_in_new, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text('Open with...'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: AppTheme.primaryColor),
                    SizedBox(width: 8),
                    Text('Share'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading || _isDownloading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppTheme.primaryColor,
              value: _isDownloading ? _downloadProgress : null,
            ),
            SizedBox(height: 16),
            Text(
              _isDownloading
                  ? 'Downloading PDF... ${(_downloadProgress * 100).toStringAsFixed(0)}%'
                  : 'Loading PDF...',
              style: AppTheme.bodyStyle,
            ),
          ],
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                'Error Loading Document',
                style: AppTheme.headingStyle,
              ),
              SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: AppTheme.bodyStyle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: _loadPdf,
              ),
            ],
          ),
        ),
      )
          : Stack(
        children: [
          Transform.scale(
            scale: _currentScale,
            alignment: Alignment.topCenter,
            child: Center(
              child: Container(
                margin: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: PdfView(
                    controller: _pdfController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    scrollDirection: Axis.vertical,
                    pageSnapping: true,
                    physics: BouncingScrollPhysics(),
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_currentPage / ${_totalPages ?? "?"}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (_showControls)
            Positioned(
              bottom: 80,
              right: 20,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'page_prev',
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.arrow_upward, color: Colors.white),
                    onPressed: _scrollToTop,
                    tooltip: 'Go to start',
                  ),
                  SizedBox(height: 12),
                  FloatingActionButton(
                    mini: true,
                    heroTag: 'page_next',
                    backgroundColor: AppTheme.primaryColor,
                    child: Icon(Icons.arrow_downward, color: Colors.white),
                    onPressed: _scrollDown,
                    tooltip: 'Next page',
                  ),
                ],
              ),
            ),

          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.black.withOpacity(0.7),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.zoom_out, color: Colors.white),
                      onPressed: _zoomOut,
                      tooltip: 'Zoom out',
                    ),
                    IconButton(
                      icon: Icon(Icons.zoom_in, color: Colors.white),
                      onPressed: _zoomIn,
                      tooltip: 'Zoom in',
                    ),
                    IconButton(
                      icon: Icon(Icons.share, color: Colors.white),
                      onPressed: _sharePdf,
                      tooltip: 'Share',
                    ),
                    IconButton(
                      icon: Icon(Icons.open_in_new, color: Colors.white),
                      onPressed: _openWithExternalApp,
                      tooltip: 'Open with external app',
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isLoading || _errorMessage != null
          ? null
          : FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        child: Icon(
          _showControls ? Icons.visibility_off : Icons.visibility,
          color: Colors.white,
        ),
        onPressed: _toggleControls,
      ),
    );
  }
}