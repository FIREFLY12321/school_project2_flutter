
import 'dart:io';
import 'package:path/path.dart' as path;

class FileTraversalTool {
  // 配置
  static const List<String> targetExtensions = ['.dart', '.kt', '.java'];
  static const List<String> skipDirectories = [
    '.git',
    '.idea',
    '.vscode',
    'build',
    '.gradle',
    'node_modules',
    '.dart_tool',
    'android/.gradle',
    'android/build',
    'ios/build',
    '.flutter-plugins-dependencies'
  ];

  // 要遍歷的目錄
  static const List<String> targetDirectories = [
    'lib',
    'android/app/src/main/kotlin/com/example/project2/',

  ];

  /// 主要執行函數
  static Future<void> run() async {
    print('🚀 開始遍歷 Flutter 專案檔案...');

    try {
      final projectRoot = Directory.current;
      final outputFile = File(path.join(projectRoot.path, 'lib/script_tools/merge_result.txt'));

      // 建立輸出檔案
      final sink = outputFile.openWrite();

      // 寫入標題
      await _writeHeader(sink);

      // 遍歷每個目標目錄
      int totalFiles = 0;
      int totalLines = 0;

      for (String dirPath in targetDirectories) {
        final dir = Directory(path.join(projectRoot.path, dirPath));
        if (await dir.exists()) {
          print('📁 正在處理目錄: $dirPath');
          final result = await _processDirectory(dir, sink, dirPath);
          totalFiles += result['files']!;
          totalLines += result['lines']!;
        } else {
          print('⚠️  目錄不存在: $dirPath');
        }
      }

      // 寫入統計資訊
      await _writeFooter(sink, totalFiles, totalLines);

      await sink.close();

      print('✅ 完成！');
      print('📊 統計資訊:');
      print('   - 總檔案數: $totalFiles');
      print('   - 總行數: $totalLines');
      print('   - 輸出檔案: ${outputFile.path}');

    } catch (e) {
      print('❌ 發生錯誤: $e');
      rethrow;
    }
  }

  /// 寫入檔案標題
  static Future<void> _writeHeader(IOSink sink) async {
    final now = DateTime.now().toIso8601String();
    sink.writeln('=' * 80);
    sink.writeln('Flutter 專案程式碼備份');
    sink.writeln('生成時間: $now');
    sink.writeln('生成工具: Dart File Traversal Tool');
    sink.writeln('=' * 80);
    sink.writeln();
  }

  /// 寫入檔案結尾
  static Future<void> _writeFooter(IOSink sink, int totalFiles, int totalLines) async {
    sink.writeln();
    sink.writeln('=' * 80);
    sink.writeln('統計資訊');
    sink.writeln('=' * 80);
    sink.writeln('總檔案數: $totalFiles');
    sink.writeln('總程式碼行數: $totalLines');
    sink.writeln('生成完成時間: ${DateTime.now().toIso8601String()}');
    sink.writeln('=' * 80);
  }

  /// 處理目錄
  static Future<Map<String, int>> _processDirectory(
      Directory dir,
      IOSink sink,
      String relativePath
      ) async {
    int fileCount = 0;
    int lineCount = 0;

    sink.writeln();
    sink.writeln('🗂️  目錄: $relativePath');
    sink.writeln('-' * 60);

    final files = await _getAllFiles(dir);

    for (FileSystemEntity file in files) {
      if (file is File && _shouldIncludeFile(file)) {
        try {
          final result = await _processFile(file, sink, dir.path);
          fileCount++;
          lineCount += result;
        } catch (e) {
          print('⚠️  無法處理檔案 ${file.path}: $e');
          sink.writeln('// ❌ 無法讀取檔案: ${path.relative(file.path, from: dir.path)}');
          sink.writeln('// 錯誤: $e');
          sink.writeln();
        }
      }
    }

    return {'files': fileCount, 'lines': lineCount};
  }

  /// 獲取所有檔案（遞歸）
  static Future<List<FileSystemEntity>> _getAllFiles(Directory dir) async {
    final List<FileSystemEntity> files = [];

    await for (FileSystemEntity entity in dir.list(recursive: true)) {
      // 跳過不需要的目錄
      if (entity is Directory && _shouldSkipDirectory(entity)) {
        continue;
      }

      if (entity is File) {
        files.add(entity);
      }
    }

    // 按路徑排序
    files.sort((a, b) => a.path.compareTo(b.path));
    return files;
  }

  /// 處理單個檔案
  static Future<int> _processFile(File file, IOSink sink, String basePath) async {
    final relativePath = path.relative(file.path, from: basePath);
    final extension = path.extension(file.path);
    final fileSize = await file.length();

    // 檔案資訊標題
    sink.writeln();
    sink.writeln('📄 檔案: $relativePath');
    sink.writeln('   大小: ${_formatFileSize(fileSize)}');
    sink.writeln('   類型: $extension');
    sink.writeln('   完整路徑: ${file.path}');
    sink.writeln('┌' + '─' * 78 + '┐');

    // 讀取並寫入檔案內容
    final content = await file.readAsString();
    final lines = content.split('\n');

    // 加入行號
    for (int i = 0; i < lines.length; i++) {
      final lineNumber = (i + 1).toString().padLeft(4, ' ');
      sink.writeln('│ $lineNumber │ ${lines[i]}');
    }

    sink.writeln('└' + '─' * 78 + '┘');
    sink.writeln();

    return lines.length;
  }

  /// 判斷是否應該包含此檔案
  static bool _shouldIncludeFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    return targetExtensions.contains(extension);
  }

  /// 判斷是否應該跳過此目錄
  static bool _shouldSkipDirectory(Directory dir) {
    final dirName = path.basename(dir.path);
    final relativePath = path.relative(dir.path, from: Directory.current.path);

    // 檢查是否在跳過列表中
    for (String skip in skipDirectories) {
      if (dirName == skip || relativePath.contains(skip)) {
        return true;
      }
    }

    // 跳過隱藏目錄
    if (dirName.startsWith('.') && dirName != '.') {
      return true;
    }

    return false;
  }

  /// 格式化檔案大小
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  /// 取得專案統計資訊
  static Future<Map<String, dynamic>> getProjectStats() async {
    final projectRoot = Directory.current;
    int dartFiles = 0;
    int kotlinFiles = 0;
    int javaFiles = 0;
    int totalLines = 0;
    int totalSize = 0;

    for (String dirPath in targetDirectories) {
      final dir = Directory(path.join(projectRoot.path, dirPath));
      if (await dir.exists()) {
        final files = await _getAllFiles(dir);

        for (FileSystemEntity file in files) {
          if (file is File && _shouldIncludeFile(file)) {
            final extension = path.extension(file.path).toLowerCase();
            final fileSize = await file.length();
            final content = await file.readAsString();
            final lines = content.split('\n').length;

            totalSize += fileSize;
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

    return {
      'dartFiles': dartFiles,
      'kotlinFiles': kotlinFiles,
      'javaFiles': javaFiles,
      'totalFiles': dartFiles + kotlinFiles + javaFiles,
      'totalLines': totalLines,
      'totalSize': totalSize,
    };
  }

  /// 只顯示統計資訊（不生成備份檔案）
  static Future<void> showStats() async {
    print('📊 正在計算專案統計資訊...');

    final stats = await getProjectStats();

    print('\n📈 專案統計資訊:');
    print('┌─────────────────────────────────────┐');
    print('│ Dart 檔案:   ${stats['dartFiles'].toString().padLeft(8)} 個      │');
    print('│ Kotlin 檔案: ${stats['kotlinFiles'].toString().padLeft(8)} 個      │');
    print('│ Java 檔案:   ${stats['javaFiles'].toString().padLeft(8)} 個      │');
    print('├─────────────────────────────────────┤');
    print('│ 總檔案數:   ${stats['totalFiles'].toString().padLeft(8)} 個      │');
    print('│ 總程式行數: ${stats['totalLines'].toString().padLeft(8)} 行      │');
    print('│ 總檔案大小: ${_formatFileSize(stats['totalSize']).padLeft(8)}       │');
    print('└─────────────────────────────────────┘');
  }
}

// 執行腳本的主函數
void main(List<String> args) async {
  if (args.isNotEmpty && args[0] == 'stats') {
    await FileTraversalTool.showStats();
  } else {
    await FileTraversalTool.run();
  }
}
