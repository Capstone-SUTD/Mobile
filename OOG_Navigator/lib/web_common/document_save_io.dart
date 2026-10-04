import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveDocument(List<int> bytes, String fileName) async {
  final directory = await getDownloadsDirectory();
  if (directory == null) {
    throw Exception("Could not access downloads directory");
  }

  final file = File('${directory.path}/$fileName');
  await file.writeAsBytes(bytes, flush: true);
  final result = await OpenFile.open(file.path);
  if (result.type != ResultType.done) {
    throw Exception(result.message);
  }
}
