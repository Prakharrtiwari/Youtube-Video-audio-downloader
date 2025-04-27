import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader/core/permission_helper.dart';
import 'package:youtube_downloader/data/youtube_service.dart';
import 'package:youtube_downloader/presentation/provider/downloads_provider.dart';
import 'package:youtube_downloader/presentation/widgets/progress_dialog.dart';
import 'package:youtube_downloader/themes/theme.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'downloads_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _urlController = TextEditingController();
  final YouTubeService _service = YouTubeService();
  final StreamController<double> _progressStreamController = StreamController<double>.broadcast();

  List<String> resolutions = [];
  String? selectedResolution;
  bool isDownloading = false;
  bool isFetching = false;
  int _selectedIndex = 0;
  Video? videoDetails;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _progressStreamController.close();
    _animationController.dispose();
    super.dispose();
  }

  void fetchDetails() async {
    if (_urlController.text.isEmpty) {
      _showSnackBar('Please paste a YouTube URL');
      return;
    }
    setState(() {
      isFetching = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const ProgressDialog(
        title: 'Fetching Resolutions',
        message: 'Please wait...',
      ),
    );
    try {
      var res = await _service.getAvailableResolutions(_urlController.text);
      var video = await _service.getVideoDetails(_urlController.text);
      if (res.isEmpty) {
        _showSnackBar('No available resolutions found.');
      } else {
        setState(() {
          resolutions = res;
          selectedResolution = resolutions.isNotEmpty ? resolutions.first : null;
          videoDetails = video;
        });
        _animationController.reset();
        _animationController.forward();
      }
    } catch (e) {
      _showSnackBar('Failed to fetch video details: $e');
    } finally {
      setState(() {
        isFetching = false;
      });
      Navigator.of(context).pop();
    }
  }

  void startDownload() async {
    bool permissionGranted = await PermissionsHelper.requestStoragePermission();
    if (!permissionGranted) {
      _showSnackBar('Storage permission is required');
      return;
    }
    if (selectedResolution == null) {
      _showSnackBar('Please select a resolution');
      return;
    }
    setState(() {
      isDownloading = true;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreamBuilder<double>(
        stream: _progressStreamController.stream,
        initialData: 0.0,
        builder: (context, snapshot) {
          return ProgressDialog(
            progress: snapshot.data,
            title: 'Downloading',
            message: 'Please wait...',
          );
        },
      ),
    ).then((_) {
      setState(() {
        isDownloading = false;
      });
    });
    try {
      await _service.downloadVideo(
        _urlController.text,
        selectedResolution!,
            (progress) {
          _progressStreamController.add(progress / 100);
        },
      );
      Navigator.of(context).pop();
      _showSnackBar('Download Complete!', isSuccess: true);
      await Provider.of<DownloadsProvider>(context, listen: false).refreshAfterDownload();
    } catch (e) {
      Navigator.of(context).pop();
      _showSnackBar('Download failed: $e');
    } finally {
      setState(() {
        isDownloading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppColors.white,
          ),
        ),
        backgroundColor: isSuccess ? Colors.green : AppColors.primaryRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.reset();
      _animationController.forward();
    }
  }

  Widget _buildHomeContent(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryRed, AppColors.primaryRed.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'YouTube Downloader',
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.background, AppColors.background.withOpacity(0.9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Download Your Videos',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.w700,
                    color: AppColors.charcoal,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paste a YouTube URL to get started',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.035,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      labelText: 'YouTube Video URL',
                      labelStyle: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.035,
                        color: AppColors.grey,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.paste, color: AppColors.primaryRed),
                        onPressed: () {
                          // Implement paste functionality if needed
                        },
                      ),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      color: AppColors.charcoal,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isFetching ? null : fetchDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: Text(
                      'Fetch Resolutions',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (videoDetails != null) ...[
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                videoDetails!.thumbnails.highResUrl,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 180,
                                  color: AppColors.grey,
                                  child: const Center(
                                    child: Icon(Icons.error, color: AppColors.white, size: 36),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              videoDetails!.title,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                                color: AppColors.charcoal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              videoDetails!.author,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.03,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (resolutions.isNotEmpty) ...[
                  Text(
                    'Select Resolution',
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                      color: AppColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButton<String>(
                      value: selectedResolution,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: Icon(Icons.arrow_drop_down, color: AppColors.primaryRed),
                      dropdownColor: AppColors.white,
                      items: resolutions
                          .map((res) => DropdownMenuItem(
                        value: res,
                        child: Text(
                          res,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: AppColors.charcoal,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedResolution = val;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                if (!isDownloading && resolutions.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.download, color: AppColors.white, size: 22),
                      label: Text(
                        'Download Video',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white,
                        ),
                      ),
                      onPressed: startDownload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pages = [
      _buildHomeContent(context),
      const DownloadsPage(),
    ];
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: IndexedStack(
            index: _selectedIndex,
            children: pages,
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
            child: GNav(
              backgroundColor: Colors.transparent,
              color: AppColors.grey,
              activeColor: Color(0xFFE60000),
              tabBackgroundColor: AppColors.lightRed.withOpacity(0.1),
              tabBorderRadius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              gap: 8,
              selectedIndex: _selectedIndex,
              onTabChange: _onItemTapped,
              textStyle: GoogleFonts.poppins(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE60000),
              ),
              tabs: [
                GButton(
                  icon: Icons.home_outlined,
                  text: 'Home',
                  iconSize: _selectedIndex == 0 ? 26 : 22,
                  iconActiveColor: Color(0xFFE60000),
                  iconColor: AppColors.grey,
                ),
                GButton(
                  icon: Icons.download_outlined,
                  text: 'Downloads',
                  iconSize: _selectedIndex == 1 ? 26 : 22,
                  iconActiveColor: Color(0xFFE60000),
                  iconColor: AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}