import 'package:flutter/material.dart';
import 'package:weather_animation/weather_animation.dart';
import 'package:weather/weather.dart';
import '../../services/weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../home/home_screen.dart';
import '../../services/update_service.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  final WeatherService _weatherService = WeatherService();
  final UpdateService _updateService = UpdateService();
  Weather? _weather;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() => _isLoading = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final weather = await _weatherService.getCurrentWeather();
      setState(() {
        _weather = weather;
        _isLoading = false;
      });
    } else {
      // Handle the case when permission is not granted
      setState(() {
        _isLoading = false;
      });
      // Optionally, show a message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Location permission is required to fetch weather data.'),
        ),
      );
    }
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
            scaleBegin: 1,
            scaleEnd: 1.08,
            scaleCurve: Cubic(0.40, 0.00, 0.20, 1.00),
            slideX: 20,
            slideY: 0,
            slideDurMill: 3000,
            slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
          ),
        ),
        CloudWidget(
          cloudConfig: CloudConfig(
            size: 160,
            color: Color(0x77212121),
            icon: IconData(63056, fontFamily: 'MaterialIcons'),
            x: 250,
            y: 130,
            scaleBegin: 1,
            scaleEnd: 1,
            slideX: 33,
            slideY: 6,
            slideDurMill: 2000,
            slideCurve: Cubic(0.40, 0.00, 0.20, 1.00),
          ),
        ),
      ];
    } else if (condition.contains('rain')) {
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
        RainWidget(
          rainConfig: RainConfig(
            count: 20,
            lengthDrop: 8,
            widthDrop: 2,
            color: Color(0xff4fc3f7),
            isRoundedEndsDrop: true,
            fallRangeMinDurMill: 500,
            fallRangeMaxDurMill: 1500,
          ),
        ),
      ];
    } else if (condition.contains('snow')) {
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
        SnowWidget(
          snowConfig: SnowConfig(
            count: 20,
            size: 15,
            color: Colors.white,
          ),
        ),
      ];
    } else if (condition.contains('thunder') || condition.contains('storm')) {
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
        RainWidget(
          rainConfig: RainConfig(
            count: 20,
            lengthDrop: 8,
            widthDrop: 2,
            color: Color(0xff4fc3f7),
            isRoundedEndsDrop: true,
            fallRangeMinDurMill: 500,
            fallRangeMaxDurMill: 1500,
          ),
        ),
        ThunderWidget(
          thunderConfig: ThunderConfig(
            color: Color(0xffffeb3b),
            flashStartMill: 50,
            flashEndMill: 300,
            blurSigma: 15,
            blurStyle: BlurStyle.solid,
          ),
        ),
      ];
    }

    // Default weather widgets for partly cloudy
    return const [
      SunWidget(
        sunConfig: SunConfig(
          width: 220,
          blurSigma: 10,
          blurStyle: BlurStyle.solid,
          coreColor: Color(0xffffa726),
          midColor: Color(0xd6ffee58),
          outColor: Color(0xffff9800),
          animMidMill: 2000,
          animOutMill: 2000,
        ),
      ),
      CloudWidget(
        cloudConfig: CloudConfig(
          size: 180,
          color: Color(0x77212121),
          icon: IconData(63056, fontFamily: 'MaterialIcons'),
          x: 250,
          y: 130,
        ),
      ),
    ];
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

        final donation =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final startDate = (donation['startDate'] as Timestamp).toDate();
        final endDate = (donation['endDate'] as Timestamp).toDate();
        final isBloodDonation = donation['isBloodDonation'] ?? false;
        final now = DateTime.now();
        final daysLeft = endDate.difference(now).inDays;
        final hasStarted = startDate.isBefore(now);
        final isActive = endDate.isAfter(now);

        return GestureDetector(
          onTap: () {
            HomeScreen.navigateToTab(context, 2);
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
      stream: _updateService.getUpdates(),
      builder: (context, snapshot) {
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final updates = snapshot.data!.docs;
        final now = DateTime.now();

        // Filter unexpired updates
        final unexpiredUpdates = updates.where((doc) {
          final update = doc.data() as Map<String, dynamic>;
          final expiryDate = update['expiryDate'] as Timestamp?;
          return expiryDate != null && expiryDate.toDate().isAfter(now);
        }).toList();

        if (unexpiredUpdates.isEmpty) {
          return const SizedBox.shrink();
        }

        // Get the latest update
        final latestUpdate = unexpiredUpdates.first;
        final updateData = latestUpdate.data() as Map<String, dynamic>;
        final type = updateData['type'] as String;
        final severity = updateData['severity'] as String;
        final expiryDate = updateData['expiryDate'] as Timestamp;

        return GestureDetector(
          onTap: () {
            HomeScreen.navigateToTab(context, 1); // Navigate to Updates tab
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
                        'Latest Update',
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
                        // Weather Animation Background
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
                        // Weather Information Overlay
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
          _buildLatestUpdateCard(),
          const SizedBox(height: 16),
          _buildLatestDonationCard(),
        ],
      ),
    );
  }
}
