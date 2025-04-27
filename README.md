# YouTube Downloader

A Flutter-based mobile application that allows users to download YouTube videos and audio in various resolutions and formats with a sleek, user-friendly interface. Built with modern Flutter practices, this app provides a seamless experience for downloading and managing media files on Android devices.

## Features

### 1. Video and Audio Downloading
- **Download Videos**: Fetch and download YouTube videos in multiple resolutions (e.g., 360p, 720p, 1080p) using the `youtube_explode_dart` package.
- **Audio Extraction**: Download audio-only streams in high-quality formats (e.g., M4A) with selectable bitrate options.
- **FFmpeg Integration**: Merge video and audio streams for high-quality downloads when muxed streams are unavailable, using `ffmpeg_kit_flutter`.

### 2. Intuitive User Interface
- **Responsive Design**: A clean, modern UI with a gradient-themed app bar, card-based layouts, and smooth animations powered by Flutter's `AnimationController`.
- **Dynamic Resolution Selector**: Displays available resolutions and audio bitrates in a dropdown menu, allowing users to choose their preferred quality.
- **Video Preview**: Shows a thumbnail, title, and author of the video after fetching details, enhancing user confidence in their selection.

### 3. Download Management
- **Real-Time Progress**: Displays a circular progress indicator with percentage updates during downloads, using a `StreamController` for smooth feedback.
- **Downloads Tab**: Lists all downloaded videos and audio files in a dedicated tab, sorted by modification date (latest first).
- **Reactive Updates**: Automatically refreshes the downloads list after a new file is downloaded, using the `provider` package for state management.
- **File Playback**: Allows users to open downloaded files directly from the app using the `open_file` package.

### 4. Storage and Permissions
- **Custom Download Directory**: Saves files to `/storage/emulated/0/Download/YouTubeVideos` on Android, ensuring easy access.
- **Permission Handling**: Requests storage permissions dynamically, with support for Android 11+ (`manageExternalStorage`) using `permission_handler` and `device_info_plus`.
- **File Management**: Automatically deletes existing files before downloading to prevent duplicates and ensures temporary files are cleaned up after FFmpeg merging.

### 5. Error Handling and Feedback
- **Robust Error Handling**: Catches and displays errors for invalid URLs, failed downloads, or file system issues via SnackBars.
- **Fallback Mechanism**: Saves video without audio as a fallback if FFmpeg merging fails, ensuring users still receive a usable file.
- **Debug Logging**: Extensive console logging for debugging, including video details, download progress, and FFmpeg operations.

### 6. State Management
- **Provider-Based Architecture**: Uses the `provider` package to manage the downloads list centrally, ensuring reactive UI updates without tight coupling between pages.
- **Efficient State Updates**: Minimizes widget rebuilds by using `Consumer` widgets, optimizing performance for the Downloads tab.

### 7. Animations and Aesthetics
- **Smooth Transitions**: Implements `FadeTransition` and `SlideTransition` for page and content animations, enhancing the user experience.
- **Google Fonts**: Utilizes `google_fonts` for consistent, modern typography with the Poppins font.
- **Custom Theme**: Features a cohesive color scheme with vibrant reds, clean whites, and subtle gradients defined in a custom `AppColors` class.

## Technical Details

- **Framework**: Flutter (Dart)
- **Key Packages**:
  - `youtube_explode_dart`: For fetching video metadata and streams.
  - `ffmpeg_kit_flutter`: For merging video and audio streams.
  - `provider`: For state management.
  - `path_provider`, `path`: For file system operations.
  - `open_file`: For opening downloaded files.
  - `google_fonts`, `google_nav_bar`: For UI styling.
  - `permission_handler`, `device_info_plus`: For storage permissions.
- **Platform Support**: Primarily Android, with extensible support for iOS (pending iOS-specific storage handling).
- **Storage**: Files saved to a dedicated `YouTubeVideos` folder in the device's Downloads directory.
- **State Management**: Uses `ChangeNotifierProvider` for reactive updates to the downloads list.

## Video:-
https://github.com/user-attachments/assets/71aff229-7011-4713-ac4f-bc08864a9ab8


