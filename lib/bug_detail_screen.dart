import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'edit_bug_screen.dart';

class BugDetailScreen extends StatefulWidget {
  final String bugId;
  final Map<String, dynamic> bugData;

  const BugDetailScreen({
    super.key,
    required this.bugId,
    required this.bugData,
  });

  @override
  State<BugDetailScreen> createState() => _BugDetailScreenState();
}

class _BugDetailScreenState extends State<BugDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text('Fehler ${widget.bugData['id'] ?? widget.bugId}'),
        backgroundColor: const Color(0xFF1E1E1E),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditBugScreen(
                    bugId: widget.bugId,
                    bugData: widget.bugData,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bugs')
            .doc(widget.bugId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status und Priorität Header
                Card(
                  color: _getPriorityColor(data['priority']).withOpacity(0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        // Priorität
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(data['priority']),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data['priority'] ?? 'Unbekannt',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(data['status']),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            data['status'] ?? 'Neu',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Kategorie
                        Chip(
                          label: Text(data['category'] ?? 'Unbekannt'),
                          backgroundColor: Colors.grey.shade800,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Titel
                Card(
                  color: const Color(0xFF1E1E1E),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Titel',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data['title'] ?? 'Kein Titel',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow('App', data['appName'] ?? 'Unbekannt'),
                        _buildInfoRow('Version', data['appVersion'] ?? '-'),
                        _buildInfoRow('Platform', data['platform'] ?? '-'),
                        _buildInfoRow('Gerät', data['deviceInfo'] ?? '-'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Beschreibung
                Card(
                  color: const Color(0xFF1E1E1E),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Beschreibung',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data['description'] ?? 'Keine Beschreibung vorhanden',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Zeitinformationen
                Card(
                  color: const Color(0xFF1E1E1E),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Zeitinformationen',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTimeRow(
                          'Erstellt',
                          data['createdAt'],
                        ),
                        _buildTimeRow(
                          'Zuletzt aktualisiert',
                          data['updatedAt'],
                        ),
                        if (data['resolvedAt'] != null)
                          _buildTimeRow(
                            'Behoben',
                            data['resolvedAt'],
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Zugewiesene Person
                if (data['assignedTo'] != null)
                  Card(
                    color: const Color(0xFF1E1E1E),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zugewiesen an',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.blue,
                                child: Text(
                                  data['assignedTo']!.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                data['assignedTo']!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

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
                            Row(
                              children: [
                                const Icon(Icons.photo_library, color: Colors.white),
                                const SizedBox(width: 8),
                                const Text(
                                  'Screenshots',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
                              onPressed: () => _showImagePickerOptions(context),
                              tooltip: 'Screenshot hinzufügen',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<List<String>>(
                          stream: _getScreenshotsStream(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            final screenshots = snapshot.data ?? [];
                            
                            if (screenshots.isEmpty) {
                              return Center(
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.image_not_supported,
                                      size: 48,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Keine Screenshots vorhanden',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    ElevatedButton.icon(
                                      onPressed: () => _showImagePickerOptions(context),
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Screenshot hinzufügen'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        minimumSize: const Size(200, 36),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: [
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: screenshots.length,
                                    itemBuilder: (context, index) {
                                      return _buildScreenshotThumbnail(
                                        screenshots[index],
                                        index,
                                        screenshots,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${screenshots.length} Screenshot${screenshots.length != 1 ? 's' : ''}',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Aktionen
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _updateStatus(context, 'In Bearbeitung');
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('In Bearbeitung'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _updateStatus(context, 'Gelöst');
                        },
                        icon: const Icon(Icons.check),
                        label: const Text('Als gelöst markieren'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(String label, dynamic timestamp) {
    String timeString = '-';
    if (timestamp != null) {
      if (timestamp is Timestamp) {
        timeString = DateFormat('dd.MM.yyyy HH:mm').format(timestamp.toDate());
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            timeString,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, String newStatus) async {
    try {
      final updateData = {
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (newStatus == 'Gelöst') {
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
      }
      
      await FirebaseFirestore.instance
          .collection('bugs')
          .doc(widget.bugId)
          .update(updateData);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status geändert zu: $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'kritisch':
        return Colors.red;
      case 'hoch':
        return Colors.orange;
      case 'mittel':
        return Colors.yellow[700]!;
      default:
        return Colors.green;
    }
  }

  Color _getStatusColor(String? status) {
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

  Stream<List<String>> _getScreenshotsStream() {
    return FirebaseFirestore.instance
        .collection('bugs')
        .doc(widget.bugId)
        .snapshots()
        .map((snapshot) {
      final data = snapshot.data();
      if (data != null && data['screenshots'] != null) {
        return List<String>.from(data['screenshots']);
      }
      return [];
    });
  }

  Widget _buildScreenshotThumbnail(String url, int index, List<String> allUrls) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(url, index, allUrls),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[700]!),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _deleteScreenshot(url),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImagePickerOptions(BuildContext context) {
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
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        _uploadImage(image);
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
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      // Loading Dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Bild wird hochgeladen...'),
                ],
              ),
            ),
          ),
        ),
      );

      // Upload zu Firebase Storage
      final bytes = await image.readAsBytes();
      final fileName = 'screenshots/${widget.bugId}/${DateTime.now().millisecondsSinceEpoch}_${image.name}';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      
      final uploadTask = await ref.putData(bytes);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // URL zur Firestore hinzufügen
      await FirebaseFirestore.instance.collection('bugs').doc(widget.bugId).update({
        'screenshots': FieldValue.arrayUnion([downloadUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context); // Loading Dialog schließen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot erfolgreich hinzugefügt! 📸'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading Dialog schließen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Upload: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteScreenshot(String url) async {
    // Bestätigungsdialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Screenshot löschen?'),
        content: const Text('Möchtest du diesen Screenshot wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Aus Firestore entfernen
      await FirebaseFirestore.instance.collection('bugs').doc(widget.bugId).update({
        'screenshots': FieldValue.arrayRemove([url]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Aus Storage löschen
      try {
        await FirebaseStorage.instance.refFromURL(url).delete();
      } catch (e) {
        // Storage-Fehler ignorieren (Datei existiert möglicherweise nicht mehr)
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Screenshot wurde gelöscht'),
            backgroundColor: Colors.orange,
          ),
        );
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
  }

  void _showFullScreenImage(String url, int initialIndex, List<String> allUrls) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imageUrls: allUrls,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

// Vollbild-Bildbetrachter
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.5),
        title: Text('${_currentIndex + 1} / ${widget.imageUrls.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: CachedNetworkImage(
                imageUrl: widget.imageUrls[index],
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.red, size: 48),
                    SizedBox(height: 16),
                    Text('Bild konnte nicht geladen werden'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}