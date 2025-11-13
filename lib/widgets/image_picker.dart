import 'dart:io';
import 'package:flutter/material.dart';


class PhotoPicker extends StatefulWidget {
  final Function(File) onImagePicked;
  const PhotoPicker({super.key, required this.onImagePicked});

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  File? _imageFile;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );

    if (image != null) {
      setState(() => _imageFile = File(image.path));
      widget.onImagePicked(File(image.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[200],
          border: Border.all(color: Colors.blueAccent),
        ),
        child: _imageFile == null
            ? const Center(
                child: Text(
                  '📷 Tap to upload photo',
                  style: TextStyle(color: Colors.black54),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_imageFile!, fit: BoxFit.cover),
              ),
      ),
    );
  }
}
