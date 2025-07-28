import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditBugScreen extends StatefulWidget {
  final String bugId;
  final Map<String, dynamic> bugData;

  const EditBugScreen({
    super.key,
    required this.bugId,
    required this.bugData,
  });

  @override
  State<EditBugScreen> createState() => _EditBugScreenState();
}

class _EditBugScreenState extends State<EditBugScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _versionController;
  late TextEditingController _deviceController;
  late TextEditingController _assignedToController;
  
  late String _selectedApp;
  late String _selectedCategory;
  late String _selectedPriority;
  late String _selectedPlatform;
  late String _selectedStatus;
  bool _isLoading = false;

  // Listen (gleich wie in AddBugScreen)
  final List<String> _apps = [
    'MVG Fahrinfo',
    'DB Navigator', 
    'Öffi',
    'VBB Bus & Bahn',
    'HVV',
    'KVB',
    'BVG Fahrinfo',
    'RMV',
    'VRR',
    'Andere'
  ];

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

  final List<String> _statuses = [
    'Neu',
    'In Bearbeitung',
    'Gelöst',
    'Geschlossen'
  ];

  @override
  void initState() {
    super.initState();
    // Controller mit aktuellen Werten initialisieren
    _titleController = TextEditingController(text: widget.bugData['title']);
    _descriptionController = TextEditingController(text: widget.bugData['description']);
    _versionController = TextEditingController(text: widget.bugData['appVersion']);
    _deviceController = TextEditingController(text: widget.bugData['deviceInfo']);
    _assignedToController = TextEditingController(text: widget.bugData['assignedTo'] ?? '');
    
    // Dropdown-Werte setzen
    _selectedApp = widget.bugData['appName'] ?? _apps.first;
    _selectedCategory = widget.bugData['category'] ?? _categories.first;
    _selectedPriority = widget.bugData['priority'] ?? _priorities[2]; // Mittel als Default
    _selectedPlatform = widget.bugData['platform'] ?? _platforms.first;
    _selectedStatus = widget.bugData['status'] ?? _statuses.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _versionController.dispose();
    _deviceController.dispose();
    _assignedToController.dispose();
    super.dispose();
  }

  Future<void> _updateBug() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final updateData = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'appName': _selectedApp,
          'appVersion': _versionController.text.trim(),
          'category': _selectedCategory,
          'priority': _selectedPriority,
          'platform': _selectedPlatform,
          'deviceInfo': _deviceController.text.trim(),
          'status': _selectedStatus,
          'assignedTo': _assignedToController.text.trim().isEmpty 
              ? null 
              : _assignedToController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Wenn Status auf "Gelöst" gesetzt wird
        if (_selectedStatus == 'Gelöst' && widget.bugData['status'] != 'Gelöst') {
          updateData['resolvedAt'] = FieldValue.serverTimestamp();
        }
        // Wenn Status von "Gelöst" auf etwas anderes geändert wird
        else if (_selectedStatus != 'Gelöst' && widget.bugData['status'] == 'Gelöst') {
          updateData['resolvedAt'] = null;
        }

        await FirebaseFirestore.instance
            .collection('bugs')
            .doc(widget.bugId)
            .update(updateData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fehler erfolgreich aktualisiert! ✅'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Zurück zur Detail-Ansicht
          Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Fehler ${widget.bugData['id'] ?? widget.bugId} bearbeiten'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          // Löschen-Button
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteDialog();
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Status-Auswahl (ganz oben für bessere Sichtbarkeit)
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status & Zuweisung',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: const Color(0xFF2A2A2A),
                      items: _statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Text(status),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _assignedToController,
                      decoration: const InputDecoration(
                        labelText: 'Zugewiesen an',
                        hintText: 'z.B. max.mustermann@example.com',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App-Informationen
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedApp,
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
                    ),
                    const SizedBox(height: 16),
                    
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
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
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
                        color: Colors.white,
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
            const SizedBox(height: 24),

            // Speichern Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateBug,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Änderungen speichern',
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

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text(
            'Fehler löschen?',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Möchtest du den Fehler "${widget.bugData['title']}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dialog schließen
                
                try {
                  await FirebaseFirestore.instance
                      .collection('bugs')
                      .doc(widget.bugId)
                      .delete();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fehler wurde gelöscht'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    
                    // Zurück zur Hauptseite (2x pop)
                    Navigator.of(context).pop(); // Edit Screen
                    Navigator.of(context).pop(); // Detail Screen
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Fehler beim Löschen: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Löschen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Neu':
        return Colors.blue;
      case 'In Bearbeitung':
        return Colors.orange;
      case 'Gelöst':
        return Colors.green;
      case 'Geschlossen':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}