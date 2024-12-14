import 'package:flutter/material.dart';
import 'package:lendahand/screens/volunteer/volunteer_donate_screen.dart';
import 'package:lendahand/screens/volunteer/volunteer_update_screen.dart';
import '../settings/settings_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:weather_animation/weather_animation.dart';
import '../../services/weather_service.dart';
import 'volunteer_donation_details_screen.dart';
import 'volunteer_groups_screen.dart';

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({Key? key}) : super(key: key);

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const VolunteerHomeTab(),
    const VolunteerUpdateScreen(),
    const VolunteerDonateScreen(),
    VolunteerGroupsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        title: Text(
          'Volunteer Dashboard',
          style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        height: 80,
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onBackground,
          backgroundColor: Theme.of(context).colorScheme.background,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.update),
              label: 'Updates',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.volunteer_activism),
              label: 'Donate',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
              label: 'Groups',
            ),
          ],
        ),
      ),
    );
  }
}

// Add Volunteer Home Tab
class VolunteerHomeTab extends StatefulWidget {
  const VolunteerHomeTab({Key? key}) : super(key: key);

  @override
  State<VolunteerHomeTab> createState() => _VolunteerHomeTabState();
}

class _VolunteerHomeTabState extends State<VolunteerHomeTab> {
  final WeatherService _weatherService = WeatherService();
  Weather? _weather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _isLoading = true);
    final weather = await _weatherService.getCurrentWeather();
    setState(() {
      _weather = weather;
      _isLoading = false;
    });
  }

  List<Widget> _getWeatherWidgets(String? condition) {
    if (condition == null) return const [];
    condition = condition.toLowerCase();

    if (condition.contains('clear')) {
      return const [
        SunWidget(
          sunConfig: SunConfig(
            width: 262,
            blurSigma: 13,
            blurStyle: BlurStyle.solid,
            coreColor: Color(0xffffa726),
            midColor: Color(0xd6ffee58),
            outColor: Color(0xffff9800),
            animMidMill: 2000,
            animOutMill: 2000,
          ),
        ),
      ];
    } else if (condition.contains('cloud')) {
      return const [
        CloudWidget(
          cloudConfig: CloudConfig(
            size: 250,
            color: Color(0x65212121),
            icon: IconData(63056, fontFamily: 'MaterialIcons'),
            x: 200,
            y: 35,
          ),
        ),
      ];
    }
    // Add more weather conditions as needed
    return const [];
  }

  Widget _buildLatestDonationCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final donationDoc = snapshot.data!.docs.first;
        final donation = donationDoc.data() as Map<String, dynamic>;
        final startDate = (donation['startDate'] as Timestamp).toDate();
        final endDate = (donation['endDate'] as Timestamp).toDate();
        final isBloodDonation = donation['isBloodDonation'] ?? false;
        final now = DateTime.now();
        final daysLeft = endDate.difference(now).inDays;
        final hasStarted = startDate.isBefore(now);
        final isActive = endDate.isAfter(now);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VolunteerDonationDetailsScreen(
                  donationId: donationDoc.id,
                  donation: donation,
                ),
              ),
            );
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isBloodDonation
                            ? Icons.bloodtype
                            : Icons.volunteer_activism,
                        color: isBloodDonation ? Colors.red : null,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Latest Campaign',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        donation['title'] ?? 'Untitled Campaign',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${DateFormat('MMM dd').format(startDate)} - ${DateFormat('MMM dd').format(endDate)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: !hasStarted
                              ? Colors.blue
                              : !isActive
                                  ? Colors.grey
                                  : daysLeft < 7
                                      ? Colors.red
                                      : Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          !hasStarted
                              ? 'Upcoming'
                              : !isActive
                                  ? 'Completed'
                                  : '$daysLeft days left',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLatestUpdateCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('updates')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final updates = snapshot.data!.docs;
        final now = DateTime.now();

        // Filter approved and unexpired updates
        final validUpdates = updates.where((doc) {
          final update = doc.data() as Map<String, dynamic>;
          final expiryDate = update['expiryDate'] as Timestamp?;
          final status = update['status'] as String?;
          return status == 'approved' && 
                 expiryDate != null && 
                 expiryDate.toDate().isAfter(now);
        }).toList();

        if (validUpdates.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get the latest update
        final latestUpdate = validUpdates.first;
        final updateData = latestUpdate.data() as Map<String, dynamic>;
        final type = updateData['type'] as String;
        final severity = updateData['severity'] as String;
        final expiryDate = updateData['expiryDate'] as Timestamp;

        return GestureDetector(
          onTap: () {
            final volunteerScreen = context.findAncestorStateOfType<_VolunteerScreenState>();
            if (volunteerScreen != null) {
              volunteerScreen.setState(() {
                volunteerScreen._currentIndex = 1;
              });
            }
          },
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: type == 'weather' ? Colors.blue : Colors.red,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        type == 'weather' ? Icons.cloud : Icons.warning,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Latest Alert',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          severity.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        updateData['title'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(updateData['description']),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            updateData['location'],
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const Spacer(),
                          const Icon(Icons.timer_outlined,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Expires ${DateFormat('MMM dd').format(expiryDate.toDate())}',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(
                minHeight: 180,
                maxHeight: 200,
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: WrapperScene(
                            sizeCanvas: const Size(350, 540),
                            isLeftCornerGradient: true,
                            colors: const [
                              Color(0xff283593),
                              Color(0xffff8a65),
                            ],
                            children: _getWeatherWidgets(_weather?.weatherMain),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Weather',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          offset: Offset(1, 1),
                                          blurRadius: 2,
                                          color: Colors.black26,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.cloud,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 28,
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                '${_weather?.temperature?.celsius?.toStringAsFixed(1)}°C',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _weather?.weatherDescription ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(1, 1),
                                      blurRadius: 2,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          _buildLatestDonationCard(),
        ],
      ),
    );
  }
}
