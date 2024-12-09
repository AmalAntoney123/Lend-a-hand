import 'package:flutter/material.dart';
import 'package:weather_animation/weather_animation.dart';
import 'package:weather/weather.dart';
import '../../services/weather_service.dart';
import 'package:geolocator/geolocator.dart';

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
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
          content: Text('Location permission is required to fetch weather data.'),
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
            fallRangeMinDurMill: 1000,
            fallRangeMaxDurMill: 2000,
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
        ],
      ),
    );
  }
}
