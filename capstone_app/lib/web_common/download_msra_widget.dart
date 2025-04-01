import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';

class DownloadMSRAWidget extends StatefulWidget {
  final String projectId;
  final int msVersion;
  final int raVersion;

  const DownloadMSRAWidget({
    Key? key,
    required this.projectId,
    required this.msVersion,
    required this.raVersion,
  }) : super(key: key);

  @override
  State<DownloadMSRAWidget> createState() => _DownloadMSRAWidgetState();
}

class _DownloadMSRAWidgetState extends State<DownloadMSRAWidget> {
  bool _isDownloading = false;

  Future<void> _downloadFile(String fileType) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("Token not found");

      final uri = Uri.parse('http://10.0.2.2:3000/app/download');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'projectid': int.tryParse(widget.projectId),
          'filetype': fileType,
          'version': fileType == "MS" ? widget.msVersion : widget.raVersion,
        }),
      );

      if (response.statusCode == 200) {
        await _saveAndOpenFile(response.bodyBytes, fileType);
      } else {
        throw Exception("Download failed: ${response.body}");
      }
    } catch (e) {
      print("Download error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to download $fileType: ${e.toString()}")),
      );
    } finally {
      setState(() {
        _isDownloading = false;
      });
    }
  }

  Future<void> _saveAndOpenFile(List<int> bytes, String fileType) async {
    try {
      // Get the directory for saving the file
      final directory = await getDownloadsDirectory();
      if (directory == null) {
        throw Exception("Could not access downloads directory");
      }

      // Create file name with appropriate extension
      final extension = fileType == "MS" ? ".docx" : ".xlsx";
      final fileName = "${fileType}_v${fileType == "MS" ? widget.msVersion : widget.raVersion}$extension";
      final file = File('${directory.path}/$fileName');

      // Write the file
      await file.writeAsBytes(bytes, flush: true);

      // Open the file
      await OpenFile.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$fileType downloaded successfully")),
      );
    } catch (e) {
      print("File save error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save $fileType: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildDownloadButton("Download MS", "MS"),
        _buildDownloadButton("Download RA", "RA"),
      ],
    );
  }

  Widget _buildDownloadButton(String label, String fileType) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isDownloading ? null : () => _downloadFile(fileType),
          icon: _isDownloading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download, color: Colors.deepPurple),
          label: Text(
            _isDownloading ? "Downloading..." : label,
            style: const TextStyle(color: Colors.deepPurple),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(color: Colors.deepPurple),
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "Version: ${fileType == "MS" ? widget.msVersion : widget.raVersion}",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}