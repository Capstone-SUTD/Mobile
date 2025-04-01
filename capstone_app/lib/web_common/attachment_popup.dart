import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class AttachmentPopup extends StatelessWidget {
  /// A callback that provides the selected file path back to the caller.
  final ValueChanged<String> onAttach;

  const AttachmentPopup({
    Key? key,
    required this.onAttach,
  }) : super(key: key);

  Future<void> _pickFile(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        onAttach(result.files.single.path!);
        Navigator.pop(context); // Close the dialog after selection
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error selecting file: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Attach a File'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.attach_file, size: 48),
          const SizedBox(height: 16),
          const Text('Select a file to attach'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _pickFile(context),
            child: const Text('Choose File'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}