import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class JsonFileStore {
  JsonFileStore({
    Directory? directory,
    this.fileName = 'smart_nagpur_state.json',
  }) : _directory = directory;

  final Directory? _directory;
  final String fileName;

  Future<File> _stateFile() async {
    final directory = _directory ?? await getApplicationDocumentsDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  Future<Map<String, Object?>?> read() async {
    final file = await _stateFile();
    if (!await file.exists()) return null;

    try {
      final contents = await file.readAsString();
      if (contents.trim().isEmpty) return null;
      final decoded = jsonDecode(contents);
      return decoded is Map ? Map<String, Object?>.from(decoded) : null;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(Map<String, Object?> value) async {
    final file = await _stateFile();
    final encoder = const JsonEncoder.withIndent('  ');
    await file.writeAsString(encoder.convert(value), flush: true);
  }
}
