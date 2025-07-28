import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_app_screen.dart';

class AppsManagementScreen extends StatefulWidget {
  const AppsManagementScreen({super.key});

  @override
  State<AppsManagementScreen> createState() => _AppsManagementScreenState();
}

class _AppsManagementScreenState extends State<AppsManagementScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _searchQuery = '';
  String _selectedPlatform = 'Alle';
  
  final List<String> _platforms = ['Alle', 'iOS', 'Android', 'Web'];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pop(context);
      return;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!userDoc.exists || userDoc.data()?['role'] != 'admin') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Berechtigung für diesen Bereich'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('ÖPNV Apps verwalten'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Such- und Filter-Bereich
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Column(
              children: [
                // Suchfeld
                TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'App suchen...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A2A2A),
                  ),
                ),
                const SizedBox(height: 12),
                // Platform Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _platforms.length,
                    itemBuilder: (context, index) {
                      final platform = _platforms[index];
                      final isSelected = _selectedPlatform == platform;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(platform),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedPlatform = platform;
                            });
                          },
                          backgroundColor: isSelected 
                              ? Colors.blue 
                              : const Color(0xFF2A2A2A),
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Apps Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('apps')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Fehler: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                var apps = snapshot.data?.docs ?? [];
                
                // Filter anwenden
                if (_searchQuery.isNotEmpty) {
                  apps = apps.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toLowerCase() ?? '';
                    final developer = data['developer']?.toLowerCase() ?? '';
                    final query = _searchQuery.toLowerCase();
                    return name.contains(query) || developer.contains(query);
                  }).toList();
                }

                if (_selectedPlatform != 'Alle') {
                  apps = apps.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final platforms = List<String>.from(data['platforms'] ?? []);
                    return platforms.contains(_selectedPlatform);
                  }).toList();
                }

                if (apps.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.apps,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty || _selectedPlatform != 'Alle'
                              ? 'Keine Apps gefunden'
                              : 'Noch keine Apps hinzugefügt',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isEmpty && _selectedPlatform == 'Alle') ...[
                          const SizedBox(height: 8),
                          Text(
                            'Klicke auf + um die erste App hinzuzufügen',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: apps.length,
                  itemBuilder: (context, index) {
                    final appData = apps[index].data() as Map<String, dynamic>;
                    final appId = apps[index].id;
                    final platforms = List<String>.from(appData['platforms'] ?? []);
                    
                    return AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _animationController,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.3, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: _animationController,
                              curve: Interval(
                                0.1 * index,
                                0.4 + (0.1 * index),
                                curve: Curves.easeOut,
                              ),
                            )),
                            child: child,
                          ),
                        );
                      },
                      child: Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey[800]!,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.directions_bus,
                              color: Colors.blue,
                              size: 28,
                            ),
                          ),
                          title: Text(
                            appData['name'] ?? 'Unbekannte App',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Entwickler: ${appData['developer'] ?? 'Unbekannt'}',
                                style: TextStyle(color: Colors.grey[400]),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  ...platforms.map((platform) => Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getPlatformColor(platform).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getPlatformColor(platform).withOpacity(0.5),
                                      ),
                                    ),
                                    child: Text(
                                      platform,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getPlatformColor(platform),
                                      ),
                                    ),
                                  )).toList(),
                                  const Spacer(),
                                  Text(
                                    'Version: ${appData['currentVersion'] ?? '-'}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddAppScreen(
                                        appId: appId,
                                        appData: appData,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showDeleteDialog(appId, appData['name']);
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddAppScreen(),
            ),
          );
        },
        backgroundColor: Colors.blue,
        label: const Text('Neue App'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteDialog(String appId, String? appName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('App löschen?'),
          content: Text(
            'Möchtest du die App "$appName" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                
                try {
                  await FirebaseFirestore.instance
                      .collection('apps')
                      .doc(appId)
                      .delete();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('App wurde gelöscht'),
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

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'iOS':
        return Colors.orange;
      case 'Android':
        return Colors.green;
      case 'Web':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}