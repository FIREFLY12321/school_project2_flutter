import 'dart:io';
import 'package:path/path.dart' as path;

class SimpleFileTraversal {
  // Target file extensions
  static const List<String> targetExtensions = ['.dart', '.kt', '.java'];

  // Directories to skip
  static const List<String> skipDirectories = [
    '.git', '.idea', '.vscode', 'build', '.gradle', 'node_modules', '.dart_tool'
  ];

  // Target directories to traverse
  static const List<String> targetDirectories = [
    'lib',
    'android/app/src/main/kotlin/com/example/project2/',
  ];

  /// Main execution function
  static Future<void> run() async {
    print('Starting file traversal...');

    try {
      final projectRoot = Directory.current;
      final outputFile = File(path.join(projectRoot.path, 'lib/script_tools/merged_code.txt'));

      // Create output directory if it doesn't exist
      await outputFile.parent.create(recursive: true);

      final sink = outputFile.openWrite();

      // Write header
      await _writeHeader(sink);

      // Process each target directory
      int totalFiles = 0;

      for (String dirPath in targetDirectories) {
        final dir = Directory(path.join(projectRoot.path, dirPath));
        if (await dir.exists()) {
          print('Processing directory: $dirPath');
          final fileCount = await _processDirectory(dir, sink, dirPath);
          totalFiles += fileCount;
        } else {
          print('Directory not found: $dirPath');
        }
      }

      // Write footer
      await _writeFooter(sink, totalFiles);
      await sink.close();

      print('Completed! Total files: $totalFiles');
      print('Output file: ${outputFile.path}');

    } catch (e) {
      print('Error occurred: $e');
      rethrow;
    }
  }

  /// Write file header
  static Future<void> _writeHeader(IOSink sink) async {
    final now = DateTime.now().toIso8601String();
    sink.writeln('// Flutter Project Code Merge');
    sink.writeln('// Generated: $now');
    sink.writeln('// ==========================================================');
    sink.writeln();
  }

  /// Write file footer
  static Future<void> _writeFooter(IOSink sink, int totalFiles) async {
    sink.writeln();
    sink.writeln('// ==========================================================');
    sink.writeln('// Total files processed: $totalFiles');
    sink.writeln('// Generation completed: ${DateTime.now().toIso8601String()}');
    sink.writeln('// ==========================================================');
  }

  /// Process directory
  static Future<int> _processDirectory(
      Directory dir,
      IOSink sink,
      String relativePath
      ) async {
    int fileCount = 0;

    sink.writeln();
    sink.writeln('// Directory: $relativePath');
    sink.writeln('// ----------------------------------------------------------');

    final files = await _getAllFiles(dir);

    for (FileSystemEntity file in files) {
      if (file is File && _shouldIncludeFile(file)) {
        try {
          await _processFile(file, sink, dir.path);
          fileCount++;
        } catch (e) {
          print('Cannot process file ${file.path}: $e');
          sink.writeln('// ERROR: Cannot read file: ${path.relative(file.path, from: dir.path)}');
          sink.writeln();
        }
      }
    }

    return fileCount;
  }

  /// Get all files recursively
  static Future<List<FileSystemEntity>> _getAllFiles(Directory dir) async {
    final List<FileSystemEntity> files = [];

    await for (FileSystemEntity entity in dir.list(recursive: true)) {
      // Skip unwanted directories
      if (entity is Directory && _shouldSkipDirectory(entity)) {
        continue;
      }

      if (entity is File) {
        files.add(entity);
      }
    }

    // Sort by path
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// Process single file
  static Future<void> _processFile(File file, IOSink sink, String basePath) async {
    final relativePath = path.relative(file.path, from: basePath);

    // Write file header
    sink.writeln();
    sink.writeln('// File: $relativePath');
    sink.writeln('// ${'-' * 50}');

    // Read and write file content
    final content = await file.readAsString();
    sink.writeln(content);

    sink.writeln();
    sink.writeln('// End of file: $relativePath');
    sink.writeln();
  }

  /// Check if file should be included
  static bool _shouldIncludeFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return targetExtensions.contains(extension);
  }

  /// Check if directory should be skipped
  static bool _shouldSkipDirectory(Directory dir) {
    final dirName = path.basename(dir.path);
    final relativePath = path.relative(dir.path, from: Directory.current.path);

    // Check skip list
    for (String skip in skipDirectories) {
      if (dirName == skip || relativePath.contains(skip)) {
        return true;
      }
    }

    // Skip hidden directories
    if (dirName.startsWith('.') && dirName != '.') {
      return true;
    }

    return false;
  }

  /// Show simple statistics
  static Future<void> showStats() async {
    print('Calculating project statistics...');

    final projectRoot = Directory.current;
    int dartFiles = 0;
    int kotlinFiles = 0;
    int javaFiles = 0;
    int totalLines = 0;

    for (String dirPath in targetDirectories) {
      final dir = Directory(path.join(projectRoot.path, dirPath));
      if (await dir.exists()) {
        final files = await _getAllFiles(dir);

        for (FileSystemEntity file in files) {
          if (file is File && _shouldIncludeFile(file)) {
            final extension = path.extension(file.path).toLowerCase();
            final content = await file.readAsString();
            final lines = content.split('\n').length;

            totalLines += lines;

            switch (extension) {
              case '.dart':
                dartFiles++;
                break;
              case '.kt':
                kotlinFiles++;
                break;
              case '.java':
                javaFiles++;
                break;
            }
          }
        }
      }
    }

    print('\nProject Statistics:');
    print('Dart files: $dartFiles');
    print('Kotlin files: $kotlinFiles');
    print('Java files: $javaFiles');
    print('Total files: ${dartFiles + kotlinFiles + javaFiles}');
    print('Total lines: $totalLines');
  }
}

// Main function
void main(List<String> args) async {
  if (args.isNotEmpty && args[0] == 'stats') {
    await SimpleFileTraversal.showStats();
  } else {
    await SimpleFileTraversal.run();
  }
}