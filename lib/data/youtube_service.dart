import 'dart:io';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:path/path.dart' as path;

class YouTubeService {
  final YoutubeExplode yt = YoutubeExplode();

  Future<Video> getVideoDetails(String url) async {
    try {
      print("Fetching video details for URL: $url");
      var video = await yt.videos.get(url);
      print("Video details fetched: ${video.title}");
      return video;
    } catch (e) {
      print("Error fetching video details: $e");
      throw Exception('Failed to fetch video details');
    }
  }

  Future<List<String>> getAvailableResolutions(String url) async {
    try {
      if (!url.contains('youtube.com') && !url.contains('youtu.be')) {
        print("Invalid YouTube URL: $url");
        return [];
      }
      print("Fetching stream manifest for URL: $url");
      var manifest = await yt.videos.streamsClient.getManifest(VideoId(url));
      List<String> resolutions = [];
      for (var muxed in manifest.muxed) {
        if (muxed.qualityLabel != null && !resolutions.contains(muxed.qualityLabel)) {
          resolutions.add(muxed.qualityLabel!);
        }
      }
      for (var video in manifest.video) {
        if (video.qualityLabel != null && !resolutions.contains(video.qualityLabel)) {
          resolutions.add(video.qualityLabel!);
        }
      }
      for (var audio in manifest.audio) {
        if (audio.bitrate != null) {
          var audioLabel = "Audio - ${audio.bitrate.kiloBitsPerSecond} Kbit/s";
          if (!resolutions.contains(audioLabel)) {
            resolutions.add(audioLabel);
          }
        }
      }
      resolutions.sort((a, b) {
        if (a.startsWith("Audio") && !b.startsWith("Audio")) return 1;
        if (!a.startsWith("Audio") && b.startsWith("Audio")) return -1;
        return a.compareTo(b);
      });
      print("Available resolutions: $resolutions");
      return resolutions;
    } catch (e, stackTrace) {
      print("Error fetching resolutions: $e");
      print("Stack trace: $stackTrace");
      return [];
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    Directory downloadsDir;
    if (Platform.isAndroid) {
      downloadsDir = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDir = await getApplicationDocumentsDirectory();
    }
    var youtubeVideosDir = Directory(path.join(downloadsDir.path, 'YouTubeVideos'));
    if (!await youtubeVideosDir.exists()) {
      await youtubeVideosDir.create(recursive: true);
    }
    return youtubeVideosDir;
  }

  Future<void> downloadVideo(
      String url,
      String qualityLabel,
      Function(double) onProgress,
      ) async {
    try {
      print("Starting download for URL: $url, Quality: $qualityLabel");
      var video = await yt.videos.get(url);
      print("Video title: ${video.title}");
      var manifest = await yt.videos.streamsClient.getManifest(video.id);
      print("Stream manifest fetched");
      var sanitizedTitle = video.title.replaceAll(RegExp(r'[^\w\s-]'), '_');
      var downloadDir = await _getDownloadsDirectory();
      if (qualityLabel.startsWith('Audio -')) {
        print("Downloading audio-only stream...");
        var targetBitrate = double.parse(qualityLabel.split('Audio - ')[1].split(' Kbit/s')[0]);
        var audioStream = manifest.audio.firstWhere(
              (element) => element.bitrate.kiloBitsPerSecond == targetBitrate,
          orElse: () => throw Exception('Selected audio stream not available!'),
        );
        var stream = yt.videos.streamsClient.get(audioStream);
        var totalSize = audioStream.size.totalBytes;
        var downloaded = 0;
        var filePath = path.join(downloadDir.path, '$sanitizedTitle.m4a');
        var file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          print("Deleted existing audio file: $filePath");
        }
        var sink = file.openWrite();
        double lastProgress = 0;
        await for (var data in stream) {
          downloaded += data.length;
          sink.add(data);
          double progress = (downloaded / totalSize) * 100;
          if ((progress - lastProgress).abs() >= 1) {
            onProgress(progress);
            lastProgress = progress;
            print("Audio download progress: ${progress.toStringAsFixed(1)}%");
          }
        }
        await sink.close();
        print("Audio saved successfully at $filePath");
        return;
      }
      StreamInfo? streamInfo;
      if (manifest.muxed.isNotEmpty) {
        streamInfo = manifest.muxed.firstWhere(
              (element) => element.qualityLabel == qualityLabel,
          orElse: () => throw Exception('Selected resolution not available!'),
        );
      }
      if (streamInfo != null) {
        print("Using muxed stream: ${streamInfo.qualityLabel}");
        var stream = yt.videos.streamsClient.get(streamInfo);
        var totalSize = streamInfo.size.totalBytes;
        var downloaded = 0;
        var filePath = path.join(downloadDir.path, '$sanitizedTitle.mp4');
        var file = File(filePath);
        if (await file.exists()) {
          await file.delete();
          print("Deleted existing video file: $filePath");
        }
        var sink = file.openWrite();
        double lastProgress = 0;
        await for (var data in stream) {
          downloaded += data.length;
          sink.add(data);
          double progress = (downloaded / totalSize) * 100;
          if ((progress - lastProgress).abs() >= 1) {
            onProgress(progress);
            lastProgress = progress;
            print("Download progress: ${progress.toStringAsFixed(1)}%");
          }
        }
        await sink.close();
        print("Video saved successfully at $filePath");
      } else {
        print("No muxed streams, combining video and audio...");
        var videoStream = manifest.video.firstWhere(
              (element) => element.qualityLabel == qualityLabel,
          orElse: () => throw Exception('Selected resolution not available!'),
        );
        var audioStream = manifest.audio.reduce((a, b) =>
        a.bitrate.kiloBitsPerSecond > b.bitrate.kiloBitsPerSecond ? a : b);
        var tempDir = await getTemporaryDirectory();
        var videoFilePath = path.join(tempDir.path, 'temp_video.mp4');
        var audioFilePath = path.join(tempDir.path, 'temp_audio.m4a');
        var outputFilePath = path.join(downloadDir.path, '$sanitizedTitle.mp4');
        print("Downloading video stream...");
        var videoStreamData = yt.videos.streamsClient.get(videoStream);
        var videoFile = File(videoFilePath);
        var videoSink = videoFile.openWrite();
        var videoTotalSize = videoStream.size.totalBytes;
        var videoDownloaded = 0;
        double lastProgress = 0;
        await for (var data in videoStreamData) {
          videoDownloaded += data.length;
          videoSink.add(data);
          double progress = (videoDownloaded / videoTotalSize) * 50;
          if ((progress - lastProgress).abs() >= 1) {
            onProgress(progress);
            lastProgress = progress;
            print("Video download progress: ${progress.toStringAsFixed(1)}%");
          }
        }
        await videoSink.close();
        print("Downloading audio stream...");
        var audioStreamData = yt.videos.streamsClient.get(audioStream);
        var audioFile = File(audioFilePath);
        var audioSink = audioFile.openWrite();
        var audioTotalSize = audioStream.size.totalBytes;
        var audioDownloaded = 0;
        await for (var data in audioStreamData) {
          audioDownloaded += data.length;
          audioSink.add(data);
          double progress = 50 + (audioDownloaded / audioTotalSize) * 50;
          if ((progress - lastProgress).abs() >= 1) {
            onProgress(progress);
            lastProgress = progress;
            print("Audio download progress: ${progress.toStringAsFixed(1)}%");
          }
        }
        await audioSink.close();
        if (!videoFile.existsSync() || !audioFile.existsSync()) {
          throw Exception('Temporary video or audio file missing');
        }
        var outputFile = File(outputFilePath);
        if (await outputFile.exists()) {
          await outputFile.delete();
          print("Deleted existing output file: $outputFilePath");
        }
        print("Merging streams with ffmpeg...");
        var ffmpegCommand =
            '-y -i "$videoFilePath" -i "$audioFilePath" -c:v copy -c:a aac -map 0:v:0 -map 1:a:0 "$outputFilePath"';
        var session = await FFmpegKit.execute(ffmpegCommand);
        var returnCode = await session.getReturnCode();
        var logs = await session.getLogs();
        for (var log in logs) {
          print("FFmpeg Log: ${log.getMessage()}");
        }
        if (!ReturnCode.isSuccess(returnCode)) {
          print("FFmpeg merge failed with return code: $returnCode");
          var sanitizedTitleNoAudio = '$sanitizedTitle\_no_audio';
          var fallbackFilePath = path.join(downloadDir.path, '$sanitizedTitleNoAudio.mp4');
          await videoFile.copy(fallbackFilePath);
          print("Fallback: Saved video without audio at $fallbackFilePath");
          throw Exception('Failed to merge streams, saved video without audio');
        }
        await videoFile.delete();
        await audioFile.delete();
        print("Video with audio saved at $outputFilePath");
      }
    } catch (e) {
      print("Error downloading: $e");
      throw Exception('Failed to download: $e');
    }
  }

  Future<List<FileSystemEntity>> getDownloadedVideos() async {
    try {
      var downloadDir = await _getDownloadsDirectory();
      print("Listing videos from: ${downloadDir.path}");
      if (!await downloadDir.exists()) {
        print("Directory does not exist: ${downloadDir.path}");
        return [];
      }
      var files = downloadDir
          .listSync()
          .where((entity) => entity.path.endsWith('.mp4') || entity.path.endsWith('.m4a'))
          .toList();
      print("Found ${files.length} file(s) in ${downloadDir.path}");
      return files;
    } catch (e) {
      print("Error fetching downloaded files: $e");
      return [];
    }
  }
}