import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _searchQuery = '';
  String _selectedRole = 'Alle';
  String _selectedStatus = 'Aktiv';
  
  final List<String> _roles = ['Alle', 'admin', 'tester', 'viewer'];
  final List<String> _statuses = ['Alle', 'Aktiv', 'Inaktiv'];

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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Benutzer verwalten'),
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
                    hintText: 'Benutzer suchen...',
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
                // Filter
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _roles.length,
                          itemBuilder: (context, index) {
                            final role = _roles[index];
                            final isSelected = _selectedRole == role;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(role == 'Alle' ? role : role.toUpperCase()),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedRole = role;
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
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedStatus,
                      dropdownColor: const Color(0xFF2A2A2A),
                      style: const TextStyle(color: Colors.white),
                      underline: Container(),
                      items: _statuses.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedStatus = value!;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Benutzer-Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
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

                var users = snapshot.data?.docs ?? [];
                
                // Filter anwenden
                if (_searchQuery.isNotEmpty) {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name']?.toLowerCase() ?? '';
                    final email = data['email']?.toLowerCase() ?? '';
                    final query = _searchQuery.toLowerCase();
                    return name.contains(query) || email.contains(query);
                  }).toList();
                }

                if (_selectedRole != 'Alle') {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['role'] == _selectedRole;
                  }).toList();
                }

                if (_selectedStatus != 'Alle') {
                  users = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isActive = data['isActive'] ?? true;
                    return _selectedStatus == 'Aktiv' ? isActive : !isActive;
                  }).toList();
                }

                if (users.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keine Benutzer gefunden',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
                    final isCurrentUser = userId == currentUserId;
                    final isActive = userData['isActive'] ?? true;
                    
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
                        color: isActive 
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFF1E1E1E).withOpacity(0.6),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isCurrentUser 
                                ? Colors.blue.withOpacity(0.5)
                                : Colors.grey[800]!,
                            width: isCurrentUser ? 2 : 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Avatar
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: _getRoleColor(userData['role']),
                                child: Text(
                                  (userData['name'] ?? userData['email'] ?? 'U')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // User Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          userData['name'] ?? 'Kein Name',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: isActive 
                                                ? Colors.white 
                                                : Colors.grey,
                                          ),
                                        ),
                                        if (isCurrentUser) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.blue.withOpacity(0.5),
                                              ),
                                            ),
                                            child: const Text(
                                              'Du',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ),
                                        ],
                                        if (!isActive) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Inaktiv',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userData['email'] ?? '',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getRoleColor(userData['role']).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: _getRoleColor(userData['role']).withOpacity(0.5),
                                            ),
                                          ),
                                          child: Text(
                                            (userData['role'] ?? 'tester').toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: _getRoleColor(userData['role']),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (userData['createdAt'] != null)
                                          Text(
                                            'Seit ${_formatDate(userData['createdAt'])}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Actions
                              if (!isCurrentUser)
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  offset: const Offset(0, 40),
                                  color: const Color(0xFF2A2A2A),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  itemBuilder: (context) => [
                                    if (userData['role'] != 'admin')
                                      const PopupMenuItem(
                                        value: 'make_admin',
                                        child: Row(
                                          children: [
                                            Icon(Icons.admin_panel_settings, size: 20),
                                            SizedBox(width: 12),
                                            Text('Zum Admin machen'),
                                          ],
                                        ),
                                      ),
                                    if (userData['role'] != 'tester')
                                      const PopupMenuItem(
                                        value: 'make_tester',
                                        child: Row(
                                          children: [
                                            Icon(Icons.bug_report, size: 20),
                                            SizedBox(width: 12),
                                            Text('Zum Tester machen'),
                                          ],
                                        ),
                                      ),
                                    if (userData['role'] != 'viewer')
                                      const PopupMenuItem(
                                        value: 'make_viewer',
                                        child: Row(
                                          children: [
                                            Icon(Icons.visibility, size: 20),
                                            SizedBox(width: 12),
                                            Text('Zum Viewer machen'),
                                          ],
                                        ),
                                      ),
                                    const PopupMenuDivider(),
                                    PopupMenuItem(
                                      value: isActive ? 'deactivate' : 'activate',
                                      child: Row(
                                        children: [
                                          Icon(
                                            isActive ? Icons.block : Icons.check_circle,
                                            size: 20,
                                            color: isActive ? Colors.orange : Colors.green,
                                          ),
                                          const SizedBox(width: 12),
                                          Text(isActive ? 'Deaktivieren' : 'Aktivieren'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, size: 20, color: Colors.red),
                                          SizedBox(width: 12),
                                          Text('Löschen', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    switch (value) {
                                      case 'make_admin':
                                        await _updateUserRole(userId, 'admin', userData['name']);
                                        break;
                                      case 'make_tester':
                                        await _updateUserRole(userId, 'tester', userData['name']);
                                        break;
                                      case 'make_viewer':
                                        await _updateUserRole(userId, 'viewer', userData['name']);
                                        break;
                                      case 'activate':
                                      case 'deactivate':
                                        await _toggleUserStatus(userId, !isActive, userData['name']);
                                        break;
                                      case 'delete':
                                        await _showDeleteDialog(userId, userData['name'], userData['email']);
                                        break;
                                    }
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
      // Statistik-Footer
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          
          final users = snapshot.data!.docs;
          final activeUsers = users.where((u) => 
            (u.data() as Map<String, dynamic>)['isActive'] ?? true
          ).length;
          final adminCount = users.where((u) => 
            (u.data() as Map<String, dynamic>)['role'] == 'admin'
          ).length;
          
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Gesamt', users.length, Colors.blue),
                _buildStatItem('Aktiv', activeUsers, Colors.green),
                _buildStatItem('Admins', adminCount, Colors.orange),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.orange;
      case 'tester':
        return Colors.blue;
      case 'viewer':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateUserRole(String userId, String newRole, String? userName) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'role': newRole});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${userName ?? 'Benutzer'} ist jetzt $newRole'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleUserStatus(String userId, bool isActive, String? userName) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'isActive': isActive});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${userName ?? 'Benutzer'} wurde ${isActive ? 'aktiviert' : 'deaktiviert'}',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(String userId, String? userName, String? email) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Benutzer löschen?'),
          content: Text(
            'Möchtest du ${userName ?? email ?? 'diesen Benutzer'} wirklich löschen? '
            'Diese Aktion kann nicht rückgängig gemacht werden.',
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
                  // Benutzer löschen
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .delete();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Benutzer wurde gelöscht'),
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
}