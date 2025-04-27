import 'dart:io';
import 'package:flutter/material.dart';
import 'package:youtube_downloader/data/youtube_service.dart';

class DownloadsProvider with ChangeNotifier {
  final YouTubeService _service = YouTubeService();
  List<FileSystemEntity> _files = [];
  bool _isLoading = true;
  String? _error;

  List<FileSystemEntity> get files => _files;
  bool get isLoading => _isLoading;
  String? get error => _error;

  DownloadsProvider() {
    fetchDownloads();
  }

  Future<void> fetchDownloads() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      var downloads = await _service.getDownloadedVideos();
      downloads.sort((a, b) =>
          (b as File).statSync().modified.compareTo((a as File).statSync().modified));
      _files = downloads;
      _isLoading = false;
      notifyListeners();
      print("Fetched downloads: ${downloads.map((e) => e.path).toList()}");
    } catch (e) {
      _isLoading = false;
      _error = 'Error fetching downloads: $e';
      notifyListeners();
      print("Error fetching downloads: $e");
    }
  }

  Future<void> refreshAfterDownload() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Allow file system to settle
    await fetchDownloads();
  }
}