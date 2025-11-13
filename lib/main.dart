// Part 1/5
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MissingChildApp());
}

class MissingChildApp extends StatelessWidget {
  const MissingChildApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFFFF5A1A); // orange accent
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Missing Child Finder',
      theme: ThemeData(
        primaryColor: seed,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      home: const MainShell(),
    );
  }
}

// ---------------- Models ----------------

enum ReporterRole { police, citizen }

class Submission {
  final String id;
  final ReporterRole role;
  final String? childName;
  final String? age;
  final String? location; // last seen / found location
  final String contact;
  final String? imagePath;
  final DateTime timestamp;

  Submission({
    required this.id,
    required this.role,
    this.childName,
    this.age,
    this.location,
    required this.contact,
    this.imagePath,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ---------------- In-memory store ----------------
class SubmissionStore {
  static final SubmissionStore _instance = SubmissionStore._internal();
  factory SubmissionStore() => _instance;
  SubmissionStore._internal();

  final List<Submission> _submissions = [];

  List<Submission> get all => List.unmodifiable(_submissions.reversed);
  void add(Submission s) => _submissions.add(s);
  void clear() => _submissions.clear();
}

// ---------------- Main Shell with Bottom Navigation ----------------

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  // pages
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePage(),
      const SearchPage(),
      const AddQuickPage(),
      const ReportsPage(),
      const ProfilePage(),
    ];
  }

  String getTitle(int index) {
    switch (index) {
      case 0:
        return 'Who Are You?';
      case 1:
        return 'Search Reports';
      case 2:
        return 'Add Report';
      case 3:
        return 'Submitted Reports';
      case 4:
        return 'Profile';
      default:
        return 'Missing Child Finder';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getTitle(_currentIndex)),
        actions: _currentIndex == 1
            ? [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  tooltip: 'Search by image',
                  onPressed: () async {
                    // open small dialog to pick image for quick search
                    final picked = await showDialog<String?>(
                      context: context,
                      builder: (_) => const ImageSearchDialog(),
                    );
                    if (picked != null && picked.isNotEmpty) {
                      // open search page with image parameter
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SearchPage(initialSearchImage: picked)));
                    }
                  },
                )
              ]
            : null,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.black54,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

// Part 2/5

// ---------------- Home Page (Role selection) ----------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Who are you?', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.local_police),
              label: const Text('Police'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoliceFormPage())),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.person),
              label: const Text('Citizen'),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CitizenFormPage())),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage())),
              icon: Icon(Icons.list, color: color),
              label: Text('View Reports', style: TextStyle(color: color)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Image Search Dialog (camera + gallery) ----------------

class ImageSearchDialog extends StatefulWidget {
  const ImageSearchDialog({super.key});

  @override
  State<ImageSearchDialog> createState() => _ImageSearchDialogState();
}

class _ImageSearchDialogState extends State<ImageSearchDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _busy = false;

  Future<void> _pick(ImageSource src) async {
    setState(() => _busy = true);
    try {
      final XFile? f = await _picker.pickImage(source: src, imageQuality: 80);
      if (f != null) {
        Navigator.pop(context, f.path);
      } else {
        Navigator.pop(context, null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
        Navigator.pop(context, null);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Search by image'),
      content: SizedBox(
        height: 140,
        child: Column(
          children: [
            const Text('Choose source to pick an image for visual search.'),
            const SizedBox(height: 12),
            _busy ? const CircularProgressIndicator() : Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  onPressed: () => _pick(ImageSource.camera),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  onPressed: () => _pick(ImageSource.gallery),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancel'))],
    );
  }
}

// ---------------- Search Page ----------------

class SearchPage extends StatefulWidget {
  final String? initialSearchImage;
  const SearchPage({super.key, this.initialSearchImage});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _q = TextEditingController();
  String? _pickedImagePath;
  List<Submission> _results = [];

  @override
  void initState() {
    super.initState();
    _pickedImagePath = widget.initialSearchImage;
    if (_pickedImagePath != null) _searchByImage(_pickedImagePath!);
  }

  void _search() {
    final q = _q.text.trim().toLowerCase();
    final all = SubmissionStore().all;
    if (q.isEmpty && _pickedImagePath == null) {
      setState(() => _results = []);
      return;
    }
    final byText = all.where((s) {
      final name = s.childName?.toLowerCase() ?? '';
      final loc = s.location?.toLowerCase() ?? '';
      return (q.isNotEmpty && (name.contains(q) || loc.contains(q)));
    }).toList();

    // naive image "search": if image path selected, show all entries that have images (placeholder)
    final byImage = _pickedImagePath != null ? all.where((s) => s.imagePath != null).toList() : <Submission>[];

    // union but keep unique, prioritize text matches then image matches
    final Set<String> ids = {};
    final List<Submission> merged = [];
    for (final s in byText) {
      if (!ids.contains(s.id)) {
        merged.add(s);
        ids.add(s.id);
      }
    }
    for (final s in byImage) {
      if (!ids.contains(s.id)) {
        merged.add(s);
        ids.add(s.id);
      }
    }

    setState(() => _results = merged);
  }

  Future<void> _pickImage() async {
    final ImagePicker p = ImagePicker();
    try {
      final XFile? f = await p.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (f != null) {
        setState(() {
          _pickedImagePath = f.path;
        });
        _searchByImage(f.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick error: $e')));
    }
  }

  void _searchByImage(String path) {
    // placeholder: currently treat "search by image" as "show submissions with images"
    // backend/model to be integrated later for actual visual matching.
    _q.clear();
    final all = SubmissionStore().all;
    final matches = all.where((s) => s.imagePath != null).toList();
    setState(() => _results = matches);
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No visual matches found (placeholder search).')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResults = _results.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _q,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by name or location'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                tooltip: 'Pick image to search',
                onPressed: () async {
                  final ImagePicker p = ImagePicker();
                  final XFile? f = await p.pickImage(source: ImageSource.camera);
                  if (f != null) {
                    setState(() => _pickedImagePath = f.path);
                    _searchByImage(f.path);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton.icon(onPressed: _search, icon: const Icon(Icons.search), label: const Text('Search')),
              const SizedBox(width: 12),
              if (_pickedImagePath != null)
                OutlinedButton.icon(
                  onPressed: () => setState(() => _pickedImagePath = null),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear image'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pickedImagePath != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(File(_pickedImagePath!), height: 160, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: hasResults ? ListView.builder(
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final s = _results[i];
                return ReportCard(submission: s, onTap: () => _showDetails(s));
              },
            ) : Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('No submissions match your search.', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 8),
                TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsPage())), icon: const Icon(Icons.list), label: const Text('Browse all reports')),
              ],
            )),
          )
        ],
      ),
    );
  }

  void _showDetails(Submission s) {
    showModalBottomSheet(context: context, builder: (_) => ReportDetails(submission: s));
  }
}

// Part 3/5

// ---------------- Add Quick Page ----------------

class AddQuickPage extends StatelessWidget {
  const AddQuickPage({super.key});

  @override
  Widget build(BuildContext context) {
    // small UI offering quick selection and manual entry
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Create a report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            icon: const Icon(Icons.local_police),
            label: const Text('Police Report'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PoliceFormPage())),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Citizen Report'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CitizenFormPage())),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
          const SizedBox(height: 18),
          TextButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CitizenFormPage())), icon: const Icon(Icons.edit), label: const Text('Manual entry')),
        ]),
      ),
    );
  }
}

// ---------------- Police Form ----------------

class PoliceFormPage extends StatefulWidget {
  const PoliceFormPage({super.key});

  @override
  State<PoliceFormPage> createState() => _PoliceFormPageState();
}

class _PoliceFormPageState extends State<PoliceFormPage> {
  String? _imagePath;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _lastSeen = TextEditingController(); // last seen location
  final TextEditingController _contact = TextEditingController();
  bool _loading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pick() async {
    final src = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.close), title: const Text('Cancel'), onTap: () => Navigator.pop(context, null)),
        ]),
      ),
    );
    if (src == null) return;
    try {
      final f = await _picker.pickImage(source: src, imageQuality: 80);
      if (f != null) setState(() => _imagePath = f.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  void _submit() {
    final contact = _contact.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Police contact is required')));
      return;
    }
    setState(() => _loading = true);

    final s = Submission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ReporterRole.police,
      childName: _name.text.trim().isEmpty ? null : _name.text.trim(),
      age: _age.text.trim().isEmpty ? null : _age.text.trim(),
      location: _lastSeen.text.trim().isEmpty ? null : _lastSeen.text.trim(),
      contact: contact,
      imagePath: _imagePath,
    );

    SubmissionStore().add(s);

    Future.delayed(const Duration(milliseconds: 350), () {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Police report submitted')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportsPage()));
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _lastSeen.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Police Report Form')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          GestureDetector(
            onTap: _pick,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2)),
              child: _imagePath == null ? Center(child: Text('Tap to upload photo (camera / gallery)', style: TextStyle(color: Theme.of(context).colorScheme.primary))) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Child name (optional)')),
          const SizedBox(height: 12),
          TextField(controller: _age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Child age (optional)')),
          const SizedBox(height: 12),
          TextField(controller: _lastSeen, decoration: const InputDecoration(labelText: 'Last seen location (optional)')),
          const SizedBox(height: 12),
          TextField(controller: _contact, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Police contact number (required)')),
          const SizedBox(height: 18),
          _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submit, child: const Text('Submit Report'))
        ]),
      ),
    );
  }
}

// ---------------- Citizen Form ----------------

class CitizenFormPage extends StatefulWidget {
  const CitizenFormPage({super.key});

  @override
  State<CitizenFormPage> createState() => _CitizenFormPageState();
}

class _CitizenFormPageState extends State<CitizenFormPage> {
  String? _imagePath;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _age = TextEditingController();
  final TextEditingController _lastSeen = TextEditingController(); // last seen location
  final TextEditingController _contact = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  bool _loading = false;

  Future<void> _pick() async {
    final src = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
          ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
          ListTile(leading: const Icon(Icons.close), title: const Text('Cancel'), onTap: () => Navigator.pop(context, null)),
        ]),
      ),
    );
    if (src == null) return;
    try {
      final f = await _picker.pickImage(source: src, imageQuality: 80);
      if (f != null) setState(() => _imagePath = f.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Image pick failed: $e')));
    }
  }

  void _submit() {
    final contact = _contact.text.trim();
    if (contact.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your contact number is required')));
      return;
    }
    setState(() => _loading = true);

    final s = Submission(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ReporterRole.citizen,
      childName: _name.text.trim().isEmpty ? null : _name.text.trim(),
      age: _age.text.trim().isEmpty ? null : _age.text.trim(),
      location: _lastSeen.text.trim().isEmpty ? null : _lastSeen.text.trim(),
      contact: contact,
      imagePath: _imagePath,
    );

    SubmissionStore().add(s);

    Future.delayed(const Duration(milliseconds: 350), () {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted')));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReportsPage()));
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _lastSeen.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Citizen Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(children: [
          GestureDetector(
            onTap: _pick,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2)),
              child: _imagePath == null ? Center(child: Text('Tap to upload photo (camera / gallery)', style: TextStyle(color: Theme.of(context).colorScheme.primary))) : ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_imagePath!), fit: BoxFit.cover, width: double.infinity)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Child name (optional)')),
          const SizedBox(height: 12),
          TextField(controller: _age, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Child age (optional)')),
          const SizedBox(height: 12),
          TextField(controller: _lastSeen, decoration: const InputDecoration(labelText: 'Last seen location')),
          const SizedBox(height: 12),
          TextField(controller: _contact, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Your contact number (required)')),
          const SizedBox(height: 18),
          _loading ? const CircularProgressIndicator() : ElevatedButton(onPressed: _submit, child: const Text('Submit Report')),
        ]),
      ),
    );
  }
}

// Part 4/5

// ---------------- Reports Page & Card ----------------

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  List<Submission> get submissions => SubmissionStore().all;

  String _fmtDate(DateTime t) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(t);
    } catch (_) {
      return t.toLocal().toString();
    }
  }

  void _showDetails(Submission s) {
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (_) => ReportDetails(submission: s));
  }

  @override
  Widget build(BuildContext context) {
    final all = submissions;
    return Scaffold(
      body: all.isEmpty ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('No reports yet', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          ElevatedButton.icon(onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell())), icon: const Icon(Icons.add), label: const Text('Create a report'))
        ]),
      ) : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: all.length,
        itemBuilder: (_, i) {
          final s = all[i];
          return ReportCard(submission: s, onTap: () => _showDetails(s));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell())),
        child: const Icon(Icons.home),
      ),
    );
  }
}

class ReportCard extends StatelessWidget {
  final Submission submission;
  final VoidCallback? onTap;
  const ReportCard({super.key, required this.submission, this.onTap});

  String _fmt(DateTime t) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(t);
    } catch (_) {
      return t.toLocal().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleLabel = submission.role == ReporterRole.police ? 'Police' : 'Citizen';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: submission.imagePath != null ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(submission.imagePath!), width: 64, height: 64, fit: BoxFit.cover)) :
          Container(width: 64, height: 64, alignment: Alignment.center, decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200), child: const Icon(Icons.person, size: 36, color: Colors.grey)),
        title: Text(submission.childName ?? 'Unnamed child', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$roleLabel · ${submission.age ?? "age unknown"}'),
          const SizedBox(height: 4),
          Text('Last seen: ${submission.location ?? "—"}', maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('Contact: ${submission.contact}', style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(_fmt(submission.timestamp), style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ]),
        isThreeLine: true,
        trailing: IconButton(icon: const Icon(Icons.arrow_forward_ios), onPressed: onTap),
        onTap: onTap,
      ),
    );
  }
}

class ReportDetails extends StatelessWidget {
  final Submission submission;
  const ReportDetails({super.key, required this.submission});

  String _fmt(DateTime t) {
    try {
      return DateFormat('dd MMM yyyy, hh:mm a').format(t);
    } catch (_) {
      return t.toLocal().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(18)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(submission.role == ReporterRole.police ? 'Police Report' : 'Citizen Report', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        if (submission.imagePath != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(submission.imagePath!), height: 200, width: double.infinity, fit: BoxFit.cover)),
        const SizedBox(height: 12),
        ListTile(title: const Text('Child Name'), subtitle: Text(submission.childName ?? '—')),
        ListTile(title: const Text('Age'), subtitle: Text(submission.age ?? '—')),
        ListTile(title: const Text('Last seen location'), subtitle: Text(submission.location ?? '—')),
        ListTile(
          title: const Text('Contact'),
          subtitle: Text(submission.contact),
          trailing: IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: submission.contact));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact copied')));
            },
          ),
        ),
        ListTile(title: const Text('Submitted At'), subtitle: Text(_fmt(submission.timestamp))),
        const SizedBox(height: 12),
        ElevatedButton.icon(icon: const Icon(Icons.close), label: const Text('Close'), onPressed: () => Navigator.pop(context)),
        const SizedBox(height: 12),
      ]),
    );
  }
}
// Part 5/5

// ---------------- Profile Page ----------------

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? _imagePath;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  Future<void> _pick() async {
    final src = await showModalBottomSheet<ImageSource?>(
      context: context,
      builder: (_) => SafeArea(child: Wrap(children: [
        ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Camera'), onTap: () => Navigator.pop(context, ImageSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('Gallery'), onTap: () => Navigator.pop(context, ImageSource.gallery)),
        ListTile(leading: const Icon(Icons.close), title: const Text('Cancel'), onTap: () => Navigator.pop(context, null)),
      ])),
    );
    if (src == null) return;
    final f = await _picker.pickImage(source: src, imageQuality: 80);
    if (f != null) setState(() => _imagePath = f.path);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: GestureDetector(
            onTap: _pick,
            child: _imagePath == null ? CircleAvatar(radius: 46, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, size: 42, color: Colors.grey)) : CircleAvatar(radius: 46, backgroundImage: FileImage(File(_imagePath!))),
          ),
        ),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Your name (optional)')),
        const SizedBox(height: 12),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Your contact (optional)')),
        const SizedBox(height: 18),
        ElevatedButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved locally (in-memory)'))), child: const Text('Save Profile')),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: () { SubmissionStore().clear(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All local reports cleared'))); }, child: const Text('Clear all local reports')),
      ]),
    );
  }
}

// ---------------- Image picker box (used in other pages if needed) ----------------

class ImagePickerBox extends StatefulWidget {
  final Function(String? path) onImageSelected;
  final String? initialImagePath;
  const ImagePickerBox({super.key, required this.onImageSelected, this.initialImagePath});

  @override
  State<ImagePickerBox> createState() => _ImagePickerBoxState();
}

class _ImagePickerBoxState extends State<ImagePickerBox> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _imagePath = widget.initialImagePath;
  }

  Future<void> _chooseSource() async {
    final choice = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancel'),
            onTap: () => Navigator.pop(ctx, null),
          )
        ]),
      ),
    );

    if (choice == null) return;
    try {
      final XFile? picked = await _picker.pickImage(source: choice, imageQuality: 80);
      if (picked != null) {
        setState(() => _imagePath = picked.path);
        widget.onImageSelected(picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not pick image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: _chooseSource,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: _imagePath == null
            ? Center(
                child: Text(
                  'Tap to Upload Photo\n(camera or gallery)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: borderColor, fontSize: 16),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_imagePath!), fit: BoxFit.cover),
              ),
      ),
    );
  }
}