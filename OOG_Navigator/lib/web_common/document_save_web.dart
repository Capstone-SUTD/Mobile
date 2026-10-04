import 'dart:html' as html;
import 'dart:typed_data';

Future<void> saveDocument(List<int> bytes, String fileName) async {
  final body = html.document.body;
  if (body == null) {
    throw StateError('Document body is unavailable');
  }

  final mimeType = fileName.endsWith('.docx')
      ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
  final blob = html.Blob([Uint8List.fromList(bytes)], mimeType);
  final anchor = html.AnchorElement()
    ..download = fileName
    ..style.display = 'none';
  final url = html.Url.createObjectUrlFromBlob(blob);

  try {
    anchor.href = url;
    body.append(anchor);
    anchor.click();
    // Let the browser consume the URL before releasing its backing data.
    await Future<void>.delayed(const Duration(seconds: 1));
  } finally {
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}
