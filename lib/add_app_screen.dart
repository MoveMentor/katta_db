import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddAppScreen extends StatefulWidget {
  final String? appId;
  final Map<String, dynamic>? appData;

  const AddAppScreen({
    super.key,
    this.appId,
    this.appData,
  });

  @override
  State<AddAppScreen> createState() => _AddAppScreenState();
}

class _AddAppScreenState extends State<AddAppScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _developerController = TextEditingController();
  final _versionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _notesController = TextEditingController();
  
  bool _isLoading = false;
  bool _isActive = true;
  
  // Platform-Auswahl
  final Map<String, bool> _platforms = {
    'iOS': false,
    'Android': false,
    'Web': false,
  };

  // App-Kategorien
  String _selectedCategory = 'Verkehrsverbund';
  final List<String> _categories = [
    'Verkehrsverbund',
    'Städtisch',
    'Regional',
    'National',
    'Multimodal',
    'Andere',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.appData != null) {
      // Bearbeiten-Modus: Daten laden
      _nameController.text = widget.appData!['name'] ?? '';
      _developerController.text = widget.appData!['developer'] ?? '';
      _versionController.text = widget.appData!['currentVersion'] ?? '';
      _websiteController.text = widget.appData!['website'] ?? '';
      _supportEmailController.text = widget.appData!['supportEmail'] ?? '';
      _notesController.text = widget.appData!['notes'] ?? '';
      _selectedCategory = widget.appData!['category'] ?? 'Verkehrsverbund';
      _isActive = widget.appData!['isActive'] ?? true;
      
      // Platforms laden
      final platforms = List<String>.from(widget.appData!['platforms'] ?? []);
      for (final platform in platforms) {
        if (_platforms.containsKey(platform)) {
          _platforms[platform] = true;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _developerController.dispose();
    _versionController.dispose();
    _websiteController.dispose();
    _supportEmailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveApp() async {
    if (_formKey.currentState!.validate()) {
      // Mindestens eine Platform muss ausgewählt sein
      if (!_platforms.values.any((selected) => selected)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitte mindestens eine Plattform auswählen'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final appData = {
          'name': _nameController.text.trim(),
          'developer': _developerController.text.trim(),
          'currentVersion': _versionController.text.trim(),
          'category': _selectedCategory,
          'platforms': _platforms.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .toList(),
          'website': _websiteController.text.trim(),
          'supportEmail': _supportEmailController.text.trim(),
          'notes': _notesController.text.trim(),
          'isActive': _isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        if (widget.appId == null) {
          // Neue App
          appData['createdAt'] = FieldValue.serverTimestamp();
          await FirebaseFirestore.instance.collection('apps').add(appData);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('App erfolgreich hinzugefügt! 🎉'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // App bearbeiten
          await FirebaseFirestore.instance
              .collection('apps')
              .doc(widget.appId)
              .update(appData);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('App erfolgreich aktualisiert! ✅'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fehler beim Speichern: $e'),
              backgroundColor: Colors.red,
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
    final isEdit = widget.appId != null;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(isEdit ? 'App bearbeiten' : 'Neue App hinzufügen'),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basis-Informationen
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Basis-Informationen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'App-Name *',
                        hintText: 'z.B. MVG Fahrinfo',
                        prefixIcon: Icon(Icons.apps),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte App-Namen eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _developerController,
                      decoration: const InputDecoration(
                        labelText: 'Entwickler/Betreiber *',
                        hintText: 'z.B. Münchner Verkehrsgesellschaft',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte Entwickler eingeben';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
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
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Plattformen
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verfügbare Plattformen *',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Wähle mindestens eine Plattform aus',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    ..._platforms.entries.map((entry) {
                      return CheckboxListTile(
                        title: Text(entry.key),
                        value: entry.value,
                        onChanged: (value) {
                          setState(() {
                            _platforms[entry.key] = value ?? false;
                          });
                        },
                        activeColor: Colors.blue,
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Versions-Informationen
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Version & Support',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _versionController,
                      decoration: const InputDecoration(
                        labelText: 'Aktuelle Version',
                        hintText: 'z.B. 7.2.1',
                        prefixIcon: Icon(Icons.numbers),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _websiteController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        hintText: 'https://...',
                        prefixIcon: Icon(Icons.language),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _supportEmailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Support E-Mail',
                        hintText: 'support@example.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Zusätzliche Informationen
            Card(
              color: const Color(0xFF1E1E1E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zusätzliche Informationen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notizen',
                        hintText: 'Zusätzliche Informationen zur App...',
                        prefixIcon: Icon(Icons.note),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('App ist aktiv'),
                      subtitle: const Text('Inaktive Apps werden in Dropdowns ausgegraut'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                      activeColor: Colors.blue,
                      contentPadding: EdgeInsets.zero,
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
                onPressed: _isLoading ? null : _saveApp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? 'Änderungen speichern' : 'App hinzufügen',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}