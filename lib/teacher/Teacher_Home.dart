import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import '../PDF/pdf.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:convert';
class TeacherHome extends StatelessWidget {
  final Map<String, dynamic> teacherData;
  final String pdfName = "sameer.pdf";
  final String pdfUrl = "https://www.cisco.com/c/dam/global/fi_fi/assets/docs/SMB_University_120307_Networking_Fundamentals.pdf";
  const TeacherHome({Key? key, required this.teacherData}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cisco Networking PDF'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Cisco Networking Fundamentals PDF',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PDFViewerPage(
                      pdfName: pdfName,
                      pdfUrl: pdfUrl,
                    ),
                  ),
                );
              },
              child: const Text('Open PDF'),
            ),
          ],
        ),
      ),
    );
  }
}
// In pubspec.yaml, use this specific version:
// syncfusion_flutter_pdfviewer: ^22.2.12





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
  bool _isLoading = true;
  String? _localPath;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _hasHighlights = false;
  Map<int, List<Map<String, dynamic>>> _highlights = {};

  @override
  void initState() {
    super.initState();
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
          try {
            // Parse the highlights JSON
            final Map<String, dynamic> highlightsJson = json.decode(highlightsData);
            _hasHighlights = true;

            // Convert string keys (page numbers) back to integers
            highlightsJson.forEach((key, value) {
              final int pageNum = int.parse(key);
              _highlights[pageNum] = List<Map<String, dynamic>>.from(value);
            });

            print('Loaded ${_highlights.length} pages with highlights');
          } catch (e) {
            print('Error parsing highlights: $e');
          }
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
            throw Exception('Failed to download PDF: ${response.statusCode}');
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
        final appDir = await _getAppDirectory();
        final localHighlightsPath = path.join(appDir.path, '${widget.pdfName}_highlights.json');
        final localHighlightsFile = File(localHighlightsPath);

        // Convert _highlights Map to a serializable format
        // We need to convert int keys to strings for JSON
        final Map<String, dynamic> serializedHighlights = {};
        _highlights.forEach((pageNum, pageHighlights) {
          serializedHighlights[pageNum.toString()] = pageHighlights;
        });

        final String highlightsJson = json.encode(serializedHighlights);
        await localHighlightsFile.writeAsString(highlightsJson);

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

  void _addHighlight() {
    // Since flutter_pdfview doesn't have built-in text selection,
    // we'll simulate adding highlights by storing page and position
    if (_currentPage > 0) {
      // In a real app, you'd have UI for selecting rectangle coordinates
      // Here we're just saving the current page with a mock rectangle

      // Create highlight data (this would normally come from user selection)
      final Map<String, dynamic> highlight = {
        'rect': {'x': 100, 'y': 100, 'width': 200, 'height': 50},
        'color': 'yellow',
        'note': 'Added on page $_currentPage'
      };

      // Add to our highlights data structure
      if (!_highlights.containsKey(_currentPage)) {
        _highlights[_currentPage] = [];
      }
      _highlights[_currentPage]!.add(highlight);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Highlight added to page $_currentPage')),
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
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _addHighlight,
            tooltip: 'Add highlight to current page',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveHighlights,
            tooltip: 'Save highlights',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          _localPath != null
              ? PDFView(
            filePath: _localPath!,
            enableSwipe: true,
            swipeHorizontal: true,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: 0,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              setState(() {
                _totalPages = pages!;
              });
            },
            onError: (error) {
              print('Error rendering PDF: $error');
            },
            onPageChanged: (page, total) {
              setState(() {
                _currentPage = page!;
              });
            },
            onViewCreated: (PDFViewController controller) {
              // You can store the controller for later use
            },
          )
              : Center(
            child: Text('Unable to load PDF. Please try again.'),
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
                child: Text(
                  'Saved highlights loaded for ${_highlights.length} pages',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _totalPages > 0
                ? Center(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            )
                : Container(),
          ),
        ],
      ),
      floatingActionButton: _localPath != null ? FloatingActionButton(
        onPressed: () {
          // Show number of highlights in current page
          int highlightCount = _highlights[_currentPage]?.length ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Page ${_currentPage + 1} has $highlightCount highlights'),
            ),
          );
        },
        child: const Icon(Icons.format_paint),
        tooltip: 'Show highlights in current page',
      ) : null,
    );
  }
}


