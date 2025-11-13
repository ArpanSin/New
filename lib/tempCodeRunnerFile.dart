import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(const MissingChildApp());
}

class MissingChildApp extends StatelessWidget {
  const MissingChildApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Missing Child Finder",
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          ),
        ),
      ),
      home: const RoleSelectionPage(),
    );
  }
}

// ---------------------------- ROLE SELECTION PAGE ----------------------------

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Missing Child App"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Who Are You?",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // Police Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PoliceFormPage()),
                  );
                },
                child: const Text("Police"),
              ),

              const SizedBox(height: 20),

              // Citizen Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CitizenFormPage()),
                  );
                },
                child: const Text("Citizen"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------- IMAGE PICKER WIDGET ----------------------------

class ImagePickerBox extends StatefulWidget {
  final Function(File?) onImageSelected;

  const ImagePickerBox({super.key, required this.onImageSelected});

  @override
  State<ImagePickerBox> createState() => _ImagePickerBoxState();
}

class _ImagePickerBoxState extends State<ImagePickerBox> {
  File? selectedImage;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();

    final XFile? photo =
        await picker.pickImage(source: ImageSource.camera); // ✅ CAMERA FIXED

    if (photo != null) {
      setState(() {
        selectedImage = File(photo.path);
      });
      widget.onImageSelected(selectedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepOrange, width: 2),
        ),
        child: selectedImage == null
            ? const Center(
                child: Text(
                  "Tap to Upload Photo",
                  style: TextStyle(fontSize: 18, color: Colors.deepOrange),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  selectedImage!,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}

// ---------------------------- POLICE FORM PAGE ----------------------------

class PoliceFormPage extends StatefulWidget {
  const PoliceFormPage({super.key});

  @override
  State<PoliceFormPage> createState() => _PoliceFormPageState();
}

class _PoliceFormPageState extends State<PoliceFormPage> {
  File? image;
  final TextEditingController age = TextEditingController();
  final TextEditingController foundLocation = TextEditingController();
  final TextEditingController contact = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Police Report Form")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ImagePickerBox(onImageSelected: (file) => image = file),

            const SizedBox(height: 20),

            TextField(
              controller: age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Child Age (optional)",
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: foundLocation,
              decoration:
                  const InputDecoration(labelText: "Found At (optional)"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: contact,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Police Contact Number (required)",
              ),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                if (contact.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Contact number is required!"),
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Form Submitted ✅")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------- CITIZEN FORM PAGE ----------------------------

class CitizenFormPage extends StatefulWidget {
  const CitizenFormPage({super.key});

  @override
  State<CitizenFormPage> createState() => _CitizenFormPageState();
}

class _CitizenFormPageState extends State<CitizenFormPage> {
  File? image;
  final TextEditingController childName = TextEditingController();
  final TextEditingController age = TextEditingController();
  final TextEditingController lostLocation = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Citizen Child Report")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ImagePickerBox(onImageSelected: (file) => image = file),

            const SizedBox(height: 20),

            TextField(
              controller: childName,
              decoration: const InputDecoration(labelText: "Child Name"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Child Age"),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: lostLocation,
              decoration: const InputDecoration(
                  labelText: "Where did you lose the child?"),
            ),

            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Report Submitted ✅")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
