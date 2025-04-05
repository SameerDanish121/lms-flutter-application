import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../Theme/theme.dart';
class DownloadsViewerScreen extends StatefulWidget {
  @override
  _DownloadsViewerScreenState createState() => _DownloadsViewerScreenState();
}
class _DownloadsViewerScreenState extends State<DownloadsViewerScreen> {
  Directory lmsDir = Directory('/storage/emulated/0/LMS');
  List<FileSystemEntity> files = [];
  bool isLoading = true;
  bool isGridView = true;
  bool isSortedByDate = true;
  TextEditingController searchController = TextEditingController();
  String searchQuery = '';
  String selectedFilter = 'All';
  final List<String> filters = ['All', 'Images', 'Videos', 'Documents'];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => isLoading = true);
    try {
      if (!await lmsDir.exists()) {
        await lmsDir.create(recursive: true);
      }

      final fileList = await lmsDir.list().toList();
      fileList.sort((a, b) {
        final aStat = a.statSync();
        final bStat = b.statSync();
        return isSortedByDate
            ? bStat.modified.compareTo(aStat.modified)
            : a.path.compareTo(b.path);
      });

      setState(() {
        files = fileList.where((file) => file is File).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading files: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<FileSystemEntity> get filteredFiles {
    List<FileSystemEntity> result = files;

    if (searchQuery.isNotEmpty) {
      result = result.where((file) =>
          file.path.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    }

    switch (selectedFilter) {
      case 'Images':
        result = result.where((file) => _isImageFile(file.path)).toList();
        break;
      case 'Videos':
        result = result.where((file) => _isVideoFile(file.path)).toList();
        break;
      case 'Documents':
        result = result.where((file) => _isDocumentFile(file.path)).toList();
        break;
    }

    return result;
  }

  bool _isImageFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.jpg') ||
        lowerPath.endsWith('.jpeg') ||
        lowerPath.endsWith('.png');
  }

  bool _isVideoFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.mp4') ||
        lowerPath.endsWith('.mov') ||
        lowerPath.endsWith('.avi');
  }

  bool _isDocumentFile(String path) {
    final lowerPath = path.toLowerCase();
    return lowerPath.endsWith('.pdf') ||
        lowerPath.endsWith('.ppt') ||
        lowerPath.endsWith('.pptx');
  }

  Future<void> _deleteFile(FileSystemEntity file) async {
    try {
      await file.delete();
      _loadFiles();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File deleted successfully'),
          backgroundColor: AppTheme.primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearAllFiles() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete All', style: AppTheme.headingStyle),
        content: Text('Are you sure you want to delete all files?', style: AppTheme.bodyStyle),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTheme.bodyStyle.copyWith(color: AppTheme.primaryColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              try {
                for (var file in files) {
                  await file.delete();
                }
                _loadFiles();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('All files deleted successfully'),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting files: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileIcon(FileSystemEntity file) {
    final path = file.path.toLowerCase();
    final iconSize = isGridView ? 40.0 : 24.0;

    if (path.endsWith('.pdf')) {
      return Icon(Icons.picture_as_pdf, size: iconSize, color: Colors.red);
    } else if (path.endsWith('.mp3') || path.endsWith('.wav') || path.endsWith('.m4a')) {
      return Icon(Icons.audiotrack, size: iconSize, color: Colors.blue);
    } else if (path.endsWith('.jpg') || path.endsWith('.jpeg') || path.endsWith('.png')) {
      return Icon(Icons.image, size: iconSize, color: Colors.green);
    } else if (path.endsWith('.ppt') || path.endsWith('.pptx')) {
      return Icon(Icons.slideshow, size: iconSize, color: Colors.orange);
    } else if (path.endsWith('.mp4') || path.endsWith('.mov') || path.endsWith('.avi')) {
      return Icon(Icons.videocam, size: iconSize, color: Colors.purple);
    } else {
      return Icon(Icons.insert_drive_file, size: iconSize, color: AppTheme.iconColor);
    }
  }

  Widget _buildFileItem(FileSystemEntity file, int index) {
    final stat = file.statSync();
    final modifiedDate = DateTime.fromMillisecondsSinceEpoch(stat.modified.millisecondsSinceEpoch);
    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(modifiedDate);
    final fileName = file.path.split('/').last;
    final isImage = _isImageFile(file.path);
    final isVideo = _isVideoFile(file.path);

    if (isGridView) {
      return Card(
        margin: EdgeInsets.all(8),
        elevation: 2,
        color: AppTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => OpenFilex.open(file.path),
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 180,
              maxHeight: 220,
            ),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: isImage || isVideo
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: isImage
                          ? Image.file(
                        File(file.path),
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                          : Container(
                        color: Colors.black12,
                        child: Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: 40,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    )
                        : Center(child: _buildFileIcon(file)),
                  ),
                  SizedBox(height: 8),
                  Text(
                    fileName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    formattedDate,
                    style: AppTheme.captionStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(Icons.share, size: 20, color: AppTheme.iconColor),
                        onPressed: () => Share.shareXFiles([XFile(file.path)]),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _deleteFile(file),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return Card(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: AppTheme.cardColor,
        child: ListTile(
          leading: isImage
              ? Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: FileImage(File(file.path)),
                fit: BoxFit.cover,
              ),
            ),
          )
              : _buildFileIcon(file),
          title: Text(
            fileName,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.bodyStyle,
          ),
          subtitle: Text(formattedDate, style: AppTheme.captionStyle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.share, color: AppTheme.iconColor),
                onPressed: () => Share.shareXFiles([XFile(file.path)]),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteFile(file),
              ),
            ],
          ),
          onTap: () => OpenFilex.open(file.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.themeData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: Text('Downloads', style: AppTheme.headingStyle.copyWith(color: Colors.white)),
          actions: [
            IconButton(
              icon: Icon(isGridView ? Icons.list : Icons.grid_view, color: Colors.white),
              onPressed: () => setState(() => isGridView = !isGridView),
              tooltip: isGridView ? 'List view' : 'Grid view',
            ),
            IconButton(
              icon: Icon(isSortedByDate ? Icons.sort_by_alpha : Icons.access_time, color: Colors.white),
              onPressed: () {
                setState(() => isSortedByDate = !isSortedByDate);
                _loadFiles();
              },
              tooltip: isSortedByDate ? 'Sort by name' : 'Sort by date',
            ),
            IconButton(
              icon: Icon(Icons.delete_sweep, color: Colors.white),
              onPressed: _clearAllFiles,
              tooltip: 'Clear all downloads',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadFiles,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: filters.map((filter) {
                              return Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(filter),
                                  selected: selectedFilter == filter,
                                  onSelected: (selected) {
                                    setState(() {
                                      selectedFilter = selected ? filter : 'All';
                                    });
                                  },
                                  selectedColor: AppTheme.primaryColor,
                                  labelStyle: TextStyle(
                                    color: selectedFilter == filter
                                        ? Colors.white
                                        : AppTheme.textColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  backgroundColor: AppTheme.cardColor,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 8, left: 8, right: 8, bottom: 12),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: AppTheme.primaryColor.withOpacity(0.05),
                            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 1),
                            ),
                            hintText: 'Search files...',
                            hintStyle: AppTheme.captionStyle.copyWith(
                                color: AppTheme.secondaryTextColor.withOpacity(0.6)),
                            prefixIcon: Icon(Icons.search, color: AppTheme.iconColor),
                            suffixIcon: searchQuery.isNotEmpty
                                ? IconButton(
                              icon: Icon(Icons.clear, color: AppTheme.iconColor),
                              onPressed: () {
                                searchController.clear();
                                setState(() => searchQuery = '');
                              },
                            )
                                : null,
                          ),
                          onChanged: (value) => setState(() => searchQuery = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                )
              else if (filteredFiles.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 60, color: AppTheme.secondaryTextColor),
                        SizedBox(height: 16),
                        Text(
                          'No files found',
                          style: AppTheme.subHeadingStyle,
                        ),
                        if (searchQuery.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              searchController.clear();
                              setState(() => searchQuery = '');
                            },
                            child: Text('Clear search',
                                style: AppTheme.bodyStyle.copyWith(color: AppTheme.primaryColor)),
                          ),
                      ],
                    ),
                  ),
                )
              else if (isGridView)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildFileItem(filteredFiles[index], index),
                        childCount: filteredFiles.length,
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildFileItem(filteredFiles[index], index),
                      childCount: filteredFiles.length,
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}