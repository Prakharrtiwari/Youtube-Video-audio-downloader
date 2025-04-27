import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:youtube_downloader/themes/theme.dart';

class ProgressDialog extends StatelessWidget {
  final double? progress;
  final String title;
  final String message;

  const ProgressDialog({
    super.key,
    this.progress,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.charcoal,
                ),
              ),
              const SizedBox(height: 18),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.lightRed.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  if (progress != null)
                    Text(
                      '${(progress! * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w700,
                        color: AppColors.charcoal,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.035,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}