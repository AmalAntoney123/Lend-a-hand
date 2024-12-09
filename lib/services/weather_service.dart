import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  static const String API_KEY =
      '2b93d73b77fbd632e037ae8e732e8a83'; // Get from openweathermap.org
  final WeatherFactory wf = WeatherFactory(API_KEY);

  Future<Weather?> getCurrentWeather() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Get weather for current location
      final weather = await wf.currentWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      return weather;
    } catch (e) {
      print('Error getting weather: $e');
      return null;
    }
  }
}
