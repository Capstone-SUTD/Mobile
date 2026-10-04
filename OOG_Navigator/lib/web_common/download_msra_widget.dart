import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'document_save_stub.dart'
    if (dart.library.io) 'document_save_io.dart'
    if (dart.library.html) 'document_save_web.dart';

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
    if (_isDownloading || !mounted) return;

    setState(() {
      _isDownloading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) throw Exception("Token not found");

      final uri = Uri.parse('https://backend-app-huhre9drhvh6dphh.southeastasia-01.azurewebsites.net/app/download');
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
        final extension = fileType == "MS" ? ".docx" : ".xlsx";
        final fileName = "${fileType}_v${fileType == "MS" ? widget.msVersion : widget.raVersion}$extension";
        await saveDocument(response.bodyBytes, fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$fileType downloaded successfully")),
          );
        }
      } else {
        throw Exception("Download failed: ${response.body}");
      }
    } catch (e) {
      print("Download error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to download $fileType: ${e.toString()}")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
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
