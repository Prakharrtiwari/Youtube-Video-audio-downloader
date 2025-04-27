import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:youtube_downloader/presentation/provider/downloads_provider.dart';
import 'package:youtube_downloader/themes/theme.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutQuad),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOutQuad),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _openVideo(String filePath) async {
    final result = await OpenFile.open(filePath);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open video: ${result.message}',
            style: GoogleFonts.poppins(color: AppColors.white),
          ),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Consumer<DownloadsProvider>(
      builder: (context, downloadsProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primaryRed,
            title: Text(
              'Downloads',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
            elevation: 0,
            centerTitle: true,
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Downloads',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.054,
                          fontWeight: FontWeight.w600,
                          color: AppColors.charcoal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'View all your downloaded videos',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.036,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 20),
                      downloadsProvider.error != null
                          ? Center(
                        child: Text(
                          downloadsProvider.error!,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.0405,
                            color: AppColors.primaryRed,
                          ),
                        ),
                      )
                          : downloadsProvider.isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
                          : downloadsProvider.files.isEmpty
                          ? Center(
                        child: Text(
                          'No downloads available.',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.0405,
                            color: AppColors.grey,
                          ),
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: downloadsProvider.files.length,
                        itemBuilder: (_, i) {
                          String fileName = path.basename(downloadsProvider.files[i].path);
                          return Card(
                            color: AppColors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              title: Text(
                                fileName,
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.036,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.charcoal,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(
                                Icons.play_circle_outline,
                                color: AppColors.primaryRed,
                              ),
                              onTap: () => _openVideo(downloadsProvider.files[i].path),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}