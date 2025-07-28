import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'add_bug_screen.dart';
import 'bug_detail_screen.dart';
import 'apps_management_screen.dart';
import 'admin_users_screen.dart';

void main() async {
  // Firebase initialisieren
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const KattaDbApp());
}

class KattaDbApp extends StatelessWidget {
  const KattaDbApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Katta DB',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF2A2A2A),
          selectedColor: Colors.blue,
          labelStyle: const TextStyle(color: Colors.white),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF1E1E1E),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[800]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIconColor: Colors.grey,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

// Auth Wrapper - entscheidet ob Login oder HomePage angezeigt wird
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasData) {
          return const HomePage();
        }
        
        return const LoginScreen();
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _selectedFilter = 'Alle';
  Map<String, dynamic>? _userData;
  
  final List<String> _statusFilters = [
    'Alle',
    'Neu',
    'In Bearbeitung',
    'Gelöst',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animationController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        setState(() {
          _userData = doc.data();
        });
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
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          '🚌 ÖPNV Fehler-Tracker',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          // Benutzer-Menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.blue,
              radius: 16,
              child: Text(
                (user?.displayName ?? user?.email ?? 'U')[0].toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            offset: const Offset(0, 45),
            color: const Color(0xFF2A2A2A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 20),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Benutzer',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                        if (_userData != null)
                          Text(
                            'Rolle: ${_userData!['role'] ?? 'Tester'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[300],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (_userData?['role'] == 'admin')
                const PopupMenuItem(
                  value: 'admin',
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 20),
                      SizedBox(width: 12),
                      Text('Administration'),
                    ],
                  ),
                ),
              if (_userData?['role'] == 'admin')
                const PopupMenuItem(
                  value: 'apps',
                  child: Row(
                    children: [
                      Icon(Icons.apps, size: 20),
                      SizedBox(width: 12),
                      Text('Apps verwalten'),
                    ],
                  ),
                ),
              if (_userData?['role'] == 'admin')
                const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Abmelden', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              switch (value) {
                case 'logout':
                  await FirebaseAuth.instance.signOut();
                  break;
                case 'admin':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminUsersScreen(),
                    ),
                  );
                  break;
                case 'apps':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AppsManagementScreen(),
                    ),
                  );
                  break;
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Statistik-Bereich
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bugs').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox(height: 80);
              
              final bugs = snapshot.data!.docs;
              final newBugs = bugs.where((b) => 
                (b.data() as Map<String, dynamic>)['status'] == 'Neu'
              ).length;
              final inProgressBugs = bugs.where((b) => 
                (b.data() as Map<String, dynamic>)['status'] == 'In Bearbeitung'
              ).length;
              final resolvedBugs = bugs.where((b) => 
                (b.data() as Map<String, dynamic>)['status'] == 'Gelöst'
              ).length;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildStatCard('Gesamt', bugs.length, Colors.blue),
                    _buildStatCard('Neu', newBugs, Colors.orange),
                    _buildStatCard('In Arbeit', inProgressBugs, Colors.purple),
                    _buildStatCard('Gelöst', resolvedBugs, Colors.green),
                  ],
                ),
              );
            },
          ),
          
          // Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              itemBuilder: (context, index) {
                final filter = _statusFilters[index];
                final isSelected = _selectedFilter == filter;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
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
          
          // Bug Liste
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('bugs').snapshots(),
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

                var bugs = snapshot.data?.docs ?? [];
                
                // Filter anwenden
                if (_selectedFilter != 'Alle') {
                  bugs = bugs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == _selectedFilter;
                  }).toList();
                }

                if (bugs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bug_report,
                          size: 64,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'Alle' 
                              ? 'Noch keine Fehler erfasst!'
                              : 'Keine Fehler mit Status "$_selectedFilter"',
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
                  itemCount: bugs.length,
                  itemBuilder: (context, index) {
                    final bug = bugs[index].data() as Map<String, dynamic>;
                    
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
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.grey[800]!,
                            width: 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BugDetailScreen(
                                  bugId: bugs[index].id,
                                  bugData: bug,
                                ),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Priority Indicator
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: _getPriorityColor(bug['priority'] ?? 'Niedrig').withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _getPriorityColor(bug['priority'] ?? 'Niedrig'),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.bug_report,
                                    color: _getPriorityColor(bug['priority'] ?? 'Niedrig'),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        bug['title'] ?? 'Kein Titel',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.apps,
                                            size: 14,
                                            color: Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            bug['appName'] ?? 'Unbekannt',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(bug['status'] ?? 'Neu').withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              bug['status'] ?? 'Neu',
                                              style: TextStyle(
                                                color: _getStatusColor(bug['status'] ?? 'Neu'),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (bug['category'] != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          bug['category'],
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Arrow
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey[600],
                                ),
                              ],
                            ),
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
            MaterialPageRoute(builder: (context) => const AddBugScreen()),
          );
        },
        backgroundColor: Colors.blue,
        label: const Text('Neuer Fehler'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
              overflow: TextOverflow.ellipsis,
            ),
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