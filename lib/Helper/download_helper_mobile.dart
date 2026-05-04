import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<void> saveFile(List<int> bytes, String fileName) async {
  final dir = await getApplicationDocumentsDirectory();
  final filePath = '${dir.path}/$fileName';
  await File(filePath).writeAsBytes(bytes, flush: true);
}