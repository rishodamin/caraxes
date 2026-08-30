import 'package:caraxes_app/pages/citizen/safe_zones_screen.dart';
import 'package:caraxes_app/pages/rescuer/disaster_locations.dart';
import 'package:caraxes_app/pages/rescuer/sos_page.dart';
import 'package:caraxes_app/pages/victim/safe_zone_page.dart';
import 'package:caraxes_app/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RescuerHomePage extends StatefulWidget {
  const RescuerHomePage({super.key});

  @override
  State<RescuerHomePage> createState() => _RescuerHomePageState();
}

class _RescuerHomePageState extends State<RescuerHomePage> {
  int _currentIndex = 0;

  List<QueryDocumentSnapshot> sosRequests = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchSosRequests();
  }

  /// Fetch SOS requests from Firestore
  Future<List<QueryDocumentSnapshot>> getSosRequests() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('sos')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs;
    } catch (e) {
      throw Exception('Failed to fetch SOS requests: $e');
    }
  }

  /// Fetch and update the UI
  Future<void> fetchSosRequests() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final requests = await getSosRequests();

      if (!mounted) return;

      setState(() {
        sosRequests = requests;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });

      debugPrint('Error fetching SOS requests: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Create pages inside build so they receive updated values.
    final List<Widget> pages = [
      _RescuerDashboard(
        sosRequestsCount: sosRequests.length,
        isLoading: isLoading,
        errorMessage: errorMessage,
        onRefresh: fetchSosRequests,
      ),

      const SafeZonePage(),

      const ReportDisasterPage(),

      const Center(child: Text('Route Page (Placeholder)')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caraxes - Rescuer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchSosRequests,
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
            },
          ),
        ],
      ),

      body: pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },

        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),

          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),

          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Reports',
          ),

          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'Route',
          ),
        ],
      ),
    );
  }
}

/// ===============================
/// DASHBOARD
/// ===============================

class _RescuerDashboard extends StatelessWidget {
  final int sosRequestsCount;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRefresh;

  const _RescuerDashboard({
    required this.sosRequestsCount,
    required this.isLoading,
    required this.errorMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,

      child: ListView(
        padding: const EdgeInsets.all(16.0),

        children: [
          Text(
            'Rescuer Dashboard',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 24),

          // ===============================
          // STATS ROW
          // ===============================
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  title: 'Active Incidents',
                  value: '12',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.red,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SosPage()),
                    );
                  },

                  child: _StatCard(
                    title: 'Pending SOS',

                    value: isLoading ? '...' : sosRequestsCount.toString(),

                    icon: Icons.sos,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),

          // ===============================
          // ERROR MESSAGE
          // ===============================
          if (errorMessage != null) ...[
            const SizedBox(height: 16),

            Card(
              color: Colors.red.shade50,

              child: Padding(
                padding: const EdgeInsets.all(12),

                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        'Failed to load SOS requests',
                        style: TextStyle(color: Colors.red.shade900),
                      ),
                    ),

                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: onRefresh,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ===============================
          // HIGH PRIORITY REPORTS
          // ===============================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              Text(
                'High Priority Reports',
                style: Theme.of(context).textTheme.titleMedium,
              ),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SosPage()),
                  );
                },
                child: const Text('See All'),
              ),
            ],
          ),

          Card(
            child: ListView.separated(
              shrinkWrap: true,

              physics: const NeverScrollableScrollPhysics(),

              itemCount: 3,

              separatorBuilder: (context, index) {
                return const Divider(height: 1);
              },

              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.priority_high, color: Colors.red),

                  title: Text('Critical Damage Report #${index + 1}'),

                  subtitle: const Text('2 mins ago • Sector A'),

                  trailing: const Icon(Icons.chevron_right),

                  onTap: () {},
                );
              },
            ),
          ),

          const SizedBox(height: 24),

          // ===============================
          // QUICK ACCESS
          // ===============================
          Text('Quick Access', style: Theme.of(context).textTheme.titleMedium),

          const SizedBox(height: 8),

          GridView.count(
            crossAxisCount: 2,

            shrinkWrap: true,

            physics: const NeverScrollableScrollPhysics(),

            mainAxisSpacing: 16,
            crossAxisSpacing: 16,

            childAspectRatio: 2.5,

            children: [
              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.group),
                label: const Text('Team'),
              ),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.inventory),
                label: const Text('Supplies'),
              ),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.contact_phone),
                label: const Text('Contacts'),
              ),

              OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.settings),
                label: const Text('Settings'),
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

/// ===============================
/// STAT CARD
/// ===============================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Icon(icon, color: color, size: 32),

            const SizedBox(height: 16),

            Text(
              value,

              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 4),

            Text(title, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
