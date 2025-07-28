import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'bug_detail_screen.dart';

class AddBugScreen extends StatefulWidget {
  const AddBugScreen({super.key});

  @override
  State<AddBugScreen> createState() => _AddBugScreenState();
}

class _AddBugScreenState extends State<AddBugScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _versionController = TextEditingController();
  final _deviceController = TextEditingController();
  
  String _selectedApp = '';
  String _selectedCategory = 'Funktionsfehler';
  String _selectedPriority = 'Mittel';
  String _selectedPlatform = 'iOS';
  bool _isLoading = false;
  bool _isLoadingApps = true;
  
  // Liste für temporäre Screenshots
  List<XFile> _selectedImages = [];
  bool _isUploadingImage = false;

  // Listen werden aus Firestore geladen
  List<String> _apps = [];

  final List<String> _categories = [
    'Funktionsfehler',
    'UI/Design',
    'Performance',
    'Absturz/Crash',
    'Datenqualität',
    'Andere'
  ];

  final List<String> _priorities = [
    'Kritisch',
    'Hoch', 
    'Mittel',
    'Niedrig'
  ];

  final List<String> _platforms = [
    'iOS',
    'Android'
  ];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('apps')
          .where('isActive', isEqualTo: true)
          .orderBy('name')
          .get();
      
      setState(() {
        _apps = snapshot.docs
            .map((doc) => doc.data()['name'] as String)
            .toList();
        
        // Füge "Andere" als Option hinzu falls keine Apps vorhanden
        if (_apps.isEmpty) {
          _apps = ['Andere'];
        }
        
        // Setze den ersten Wert als ausgewählt
        if (_selectedApp.isEmpty && _apps.isNotEmpty) {
          _selectedApp = _apps.first;
        }
        
        _isLoadingApps = false;
      });
    } catch (e) {
      debugPrint('Fehler beim Laden der Apps: $e');
      setState(() {
        _apps = ['Andere'];
        _selectedApp = 'Andere';
        _isLoadingApps = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    _deviceController.dispose();
    super.dispose();
  }

  Future<void> _saveBug() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Generiere eine eindeutige ID
        const uuid = Uuid();
        final bugId = 'BUG-${DateTime.now().year}-${uuid.v4().substring(0, 8).toUpperCase()}';

        // Erstelle das Bug-Dokument
        await FirebaseFirestore.instance.collection('bugs').doc(bugId).set({
          'id': bugId,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'appName': _selectedApp,
          'appVersion': _versionController.text.trim(),
          'category': _selectedCategory,
          'priority': _selectedPriority,
          'platform': _selectedPlatform,
          'deviceInfo': _deviceController.text.trim(),
          'status': 'Neu',
          'assignedTo': null,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'resolvedAt': null,
          'screenshots': [],
        });

        // Screenshots hochladen wenn vorhanden
        List<String> uploadedUrls = [];
        if (_selectedImages.isNotEmpty) {
          for (int i = 0; i < _selectedImages.length; i++) {
            final image = _selectedImages[i];
            try {
              final bytes = await image.readAsBytes();
              final fileName = 'screenshots/$bugId/${DateTime.now().millisecondsSinceEpoch}_${i}_${image.name}';
              final ref = FirebaseStorage.instance.ref().child(fileName);
              
              final uploadTask = await ref.putData(bytes);
              final downloadUrl = await uploadTask.ref.getDownloadURL();
              uploadedUrls.add(downloadUrl);
            } catch (e) {
              debugPrint('Fehler beim Upload von Bild $i: $e');
            }
          }

          // URLs zu Firestore hinzufügen
          if (uploadedUrls.isNotEmpty) {
            await FirebaseFirestore.instance.collection('bugs').doc(bugId).update({
              'screenshots': uploadedUrls,
            });
          }
        }

        if (mounted) {
          // Zeige Erfolgsmeldung
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler $bugId wurde erfolgreich erstellt! 🎉'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Gehe zur Detail-Ansicht des neuen Fehlers
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => BugDetailScreen(
                bugId: bugId,
                bugData: {
                  'id': bugId,
                  'title': _titleController.text.trim(),
                  'description': _descriptionController.text.trim(),
                  'appName': _selectedApp,
                  'appVersion': _versionController.text.trim(),
                  'category': _selectedCategory,
                  'priority': _selectedPriority,
                  'platform': _selectedPlatform,
                  'deviceInfo': _deviceController.text.trim(),
                  'status': 'Neu',
                  'assignedTo': null,
                  'screenshots': uploadedUrls,
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Speichern: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Screenshot hinzufügen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Aus Galerie wählen'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Foto aufnehmen'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isUploadingImage = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Auswählen des Bildes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('🐛 Neuen Fehler melden'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // App-Auswahl
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'App-Informationen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // App Dropdown
                    _isLoadingApps
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : DropdownButtonFormField<String>(
                            value: _selectedApp.isEmpty ? null : _selectedApp,
                            decoration: const InputDecoration(
                              labelText: 'ÖPNV-App',
                              prefixIcon: Icon(Icons.apps),
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: const Color(0xFF2A2A2A),
                            items: _apps.map((app) {
                              return DropdownMenuItem(
                                value: app,
                                child: Text(app),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedApp = value!;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte eine App auswählen';
                              }
                              return null;
                            },
                          ),
                    const SizedBox(height: 16),
                    
                    // Platform und Version
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPlatform,
                            decoration: const InputDecoration(
                              labelText: 'Platform',
                              prefixIcon: Icon(Icons.phone_iphone),
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: const Color(0xFF2A2A2A),
                            items: _platforms.map((platform) {
                              return DropdownMenuItem(
                                value: platform,
                                child: Text(platform),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPlatform = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _versionController,
                            decoration: const InputDecoration(
                              labelText: 'App-Version',
                              hintText: 'z.B. 7.2.1',
                              prefixIcon: Icon(Icons.numbers),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Bitte Version eingeben';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fehler-Details
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fehler-Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Titel
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titel *',
                        hintText: 'Kurze Beschreibung des Fehlers',
                        prefixIcon: Icon(Icons.title),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte einen Titel eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Beschreibung
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Detaillierte Beschreibung *',
                        hintText: 'Was genau ist passiert? Wie kann man den Fehler reproduzieren?',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte eine Beschreibung eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Kategorie und Priorität
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Kategorie',
                              prefixIcon: Icon(Icons.category),
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: const Color(0xFF2A2A2A),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Priorität',
                              prefixIcon: Icon(Icons.priority_high),
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: const Color(0xFF2A2A2A),
                            items: _priorities.map((priority) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(priority),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Text(priority),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedPriority = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Geräte-Informationen
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Geräte-Informationen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deviceController,
                      decoration: const InputDecoration(
                        labelText: 'Gerät & OS-Version',
                        hintText: 'z.B. iPhone 13, iOS 17.2',
                        prefixIcon: Icon(Icons.devices),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Screenshots
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Screenshots',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
                          onPressed: _isUploadingImage ? null : _showImagePickerOptions,
                          tooltip: 'Screenshot hinzufügen',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    if (_selectedImages.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.image_not_supported,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Keine Screenshots hinzugefügt',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: _isUploadingImage ? null : _showImagePickerOptions,
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Screenshot hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(200, 36),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: [
                          SizedBox(
                            height: 120,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _selectedImages.length,
                              itemBuilder: (context, index) {
                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[700]!),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: FutureBuilder<Uint8List>(
                                          future: _selectedImages[index].readAsBytes(),
                                          builder: (context, snapshot) {
                                            if (snapshot.hasData) {
                                              return Image.memory(
                                                snapshot.data!,
                                                fit: BoxFit.cover,
                                              );
                                            }
                                            return const Center(
                                              child: CircularProgressIndicator(),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 12,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                          padding: const EdgeInsets.all(4),
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_selectedImages.length} Screenshot${_selectedImages.length != 1 ? 's' : ''} ausgewählt',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    
                    if (_isUploadingImage)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Speichern Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveBug,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Fehler melden',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'kritisch':
        return Colors.red;
      case 'hoch':
        return Colors.orange;
      case 'mittel':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }
}