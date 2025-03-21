import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class PDFViewerPage extends StatefulWidget {
  final String pdfName;
  final String pdfUrl; // Can be network URL or file path

  const PDFViewerPage({
    Key? key,
    required this.pdfName,
    required this.pdfUrl
  }) : super(key: key);

  @override
  _PDFViewerPageState createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  late PdfViewerController _pdfViewerController;
  bool _isLoading = true;
  String? _localPath;
  Map<int, List<PdfTextLine>> _highlightedTextLines = {};
  bool _hasHighlights = false;

  @override
  void initState() {
    super.initState();
    _pdfViewerController = PdfViewerController();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create app directory if it doesn't exist
      final appDir = await _getAppDirectory();

      // Check if PDF already exists in local storage
      final localPdfPath = path.join(appDir.path, widget.pdfName);
      final localPdfFile = File(localPdfPath);
      final localHighlightsPath = path.join(appDir.path, '${widget.pdfName}_highlights.json');
      final localHighlightsFile = File(localHighlightsPath);

      // If the PDF exists locally, use it
      if (await localPdfFile.exists()) {
        print('Loading PDF from local storage: $localPdfPath');
        _localPath = localPdfPath;

        // Load highlights if they exist
        if (await localHighlightsFile.exists()) {
          final highlightsData = await localHighlightsFile.readAsString();
          // Here you would parse the highlights from JSON
          // This is a simplified example
          _hasHighlights = highlightsData.isNotEmpty;
        }
      } else {
        // If URL is a network URL, download the PDF
        if (widget.pdfUrl.startsWith('http')) {
          print('Downloading PDF from network: ${widget.pdfUrl}');
          final response = await http.get(Uri.parse(widget.pdfUrl));
          if (response.statusCode == 200) {
            await localPdfFile.writeAsBytes(response.bodyBytes);
            _localPath = localPdfPath;
          } else {
            throw Exception('Failed to download PDF');
          }
        } else {
          // If URL is a file path on device, copy it to app directory
          print('Copying PDF from device path: ${widget.pdfUrl}');
          final File originalFile = File(widget.pdfUrl);
          if (await originalFile.exists()) {
            await originalFile.copy(localPdfPath);
            _localPath = localPdfPath;
          } else {
            throw Exception('File not found at specified path');
          }
        }
      }
    } catch (e) {
      print('Error loading PDF: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading PDF: $e')),
      );
      // Fallback to original URL if there's an error
      _localPath = null;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Directory> _getAppDirectory() async {
    // Get app documents directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory pdfDir = Directory('${appDocDir.path}/pdf_viewer_app');

    // Create directory if it doesn't exist
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    return pdfDir;
  }

  Future<void> _saveHighlights() async {
    try {
      if (_localPath != null) {
        // Get highlights from PDF viewer
        // This is simplified - you'll need to extract actual highlights
        final appDir = await _getAppDirectory();
        final localHighlightsPath = path.join(appDir.path, '${widget.pdfName}_highlights.json');
        final localHighlightsFile = File(localHighlightsPath);

        // Convert highlights to JSON and save
        // This is a simplified example
        final highlightsData = '{}'; // Replace with actual serialized highlights
        await localHighlightsFile.writeAsString(highlightsData);

        setState(() {
          _hasHighlights = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Highlights saved successfully')),
        );
      }
    } catch (e) {
      print('Error saving highlights: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving highlights: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfName),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveHighlights,
            tooltip: 'Save highlights',
          ),
          IconButton(
            icon: const Icon(Icons.highlight),
            onPressed: () {
              // Toggle highlight mode
              // This will depend on the specific library implementation
            },
            tooltip: 'Toggle highlight mode',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          _localPath != null
              ? SfPdfViewer.file(
            File(_localPath!),
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            enableTextSelection: true,
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              if (details.selectedText != null && details.selectedText!.isNotEmpty) {
                // Handle text selection for highlighting
                print('Selected text: ${details.selectedText}');
              }
            },
          )
              : SfPdfViewer.network(
            widget.pdfUrl,
            key: _pdfViewerKey,
            controller: _pdfViewerController,
            enableTextSelection: true,
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              if (details.selectedText != null && details.selectedText!.isNotEmpty) {
                // Handle text selection for highlighting
                print('Selected text: ${details.selectedText}');
              }
            },
          ),
          if (_hasHighlights)
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Saved highlights loaded',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Example usage:
class PdfViewerApp extends StatelessWidget {
  const PdfViewerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PdfInputPage(),
    );
  }
}

class PdfInputPage extends StatefulWidget {
  @override
  _PdfInputPageState createState() => _PdfInputPageState();
}

class _PdfInputPageState extends State<PdfInputPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'PDF Name (must be unique)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'PDF URL or File Path',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _urlController.text.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PDFViewerPage(
                        pdfName: '${_nameController.text}.pdf',
                        pdfUrl: _urlController.text,
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both name and URL/path')),
                  );
                }
              },
              child: const Text('Open PDF'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                // Here you would typically implement file picking
                // This is a simplified example
                final status = await Permission.storage.request();
                if (status.isGranted) {
                  // Launch file picker and get path
                  // For this example, we'll just show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File picker would launch here')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Storage permission denied')),
                  );
                }
              },
              child: const Text('Pick PDF from Device'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }
}