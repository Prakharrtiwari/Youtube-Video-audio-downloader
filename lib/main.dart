import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_downloader/presentation/pages/home_page.dart';
import 'package:youtube_downloader/presentation/provider/downloads_provider.dart';
import 'package:youtube_downloader/themes/theme.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DownloadsProvider(),
      child: MaterialApp(
        title: 'YouTube Downloader',
        theme: ThemeData(
          primaryColor: AppColors.primaryRed,
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const HomePage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

Future<void> requestPermissions() async {
  var storageStatus = await Permission.storage.status;
  if (!storageStatus.isGranted) {
    await Permission.storage.request();
  }
  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
}