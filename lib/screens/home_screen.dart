import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rive/rive.dart' as rive;
import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bhardwaj_weather/consts.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  Weather? _weather;
  final TextEditingController _cityController = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocationWeather();
    _startAutoRefreshTime();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefreshTime() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {});
    });
  }

  Future<void> _getCurrentLocationWeather() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied.');
    }

    Position position = await Geolocator.getCurrentPosition();
    _fetchWeatherByCoordinates(position.latitude, position.longitude);
  }

  Future<void> _fetchWeatherByCoordinates(double lat, double lon) async {
    Weather weather = await _wf.currentWeatherByLocation(lat, lon);
    setState(() {
      _weather = weather;
    });
  }

  Future<void> _fetchWeatherByCityName(String city) async {
    Weather weather = await _wf.currentWeatherByCityName(city);
    setState(() {
      _weather = weather;
    });
  }

  String _getAnimationAsset() {
    if (_weather == null) return 'assets/animations/default_weather.riv';

    switch (_weather!.weatherMain) {
      case 'Clear':
        return 'assets/animations/sunny.riv';
      case 'Rain':
        return 'assets/animations/rainy.riv';
      case 'Clouds':
        return 'assets/animations/cloudy.riv';
      case 'Snow':
        return 'assets/animations/snowy.riv';
      case 'Thunderstorm':
        return 'assets/animations/thunderstorm.riv';
      default:
        return 'assets/animations/default_weather.riv';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Bhardwaj Weather",
          style: TextStyle(
            color: _weather != null &&
                DateTime.now().isAfter(DateTime.parse(_weather!.sunrise.toString())) &&
                DateTime.now().isBefore(DateTime.parse(_weather!.sunset.toString()))
                ? Colors.black
                : Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocationWeather,
          ),
        ],
      ),
      body: _buildUI(),
    );
  }

  Widget _buildUI() {
    if (_weather == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        _buildWeatherAnimation(),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _searchBar(),
              const SizedBox(height: 16),
              AnimatedOpacity(
                opacity: _weather != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Column(
                  children: [
                    _locationHeader(),
                    _dateTimeInfo(),
                    _weatherIcon(),
                    _currentTemp(),
                    _extraInfo(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherAnimation() {
    return rive.RiveAnimation.asset(
      _getAnimationAsset(),
      fit: BoxFit.cover,
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: _cityController,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: 'Enter city name',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onSubmitted: (value) {
        if (value.isNotEmpty) {
          _fetchWeatherByCityName(value);
        }
      },
    );
  }

  Widget _locationHeader() {
    return Text(
      "${_weather?.areaName ?? ""}, ${_weather?.country ?? ""}",
      style: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _dateTimeInfo() {
    DateTime now = DateTime.now();

    return Column(
      children: [
        Text(
          DateFormat("h:mm a").format(now),
          style: const TextStyle(fontSize: 36),
        ),
        const SizedBox(height: 8),
        Text(
          "${DateFormat("EEEE, d MMM y").format(now)}",
          style: const TextStyle(fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _weatherIcon() {
    return Column(
      children: [
        Image.network(
          "http://openweathermap.org/img/wn/${_weather?.weatherIcon}@4x.png",
          height: 100,
        ),
        const SizedBox(height: 8),
        Text(
          _weather?.weatherDescription?.capitalize() ?? "",
          style: const TextStyle(color: Colors.black, fontSize: 20),
        ),
      ],
    );
  }

  Widget _currentTemp() {
    return Text(
      "${_weather?.temperature?.celsius?.toStringAsFixed(0)}° C",
      style: const TextStyle(
        color: Colors.black,
        fontSize: 80,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _extraInfo() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 800),
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(
            children: [
              const Icon(Icons.thermostat, color: Colors.white),
              const SizedBox(height: 5),
              Text("Feels like", style: const TextStyle(color: Colors.white)),
              Text(
                "${_weather?.tempFeelsLike?.celsius?.toStringAsFixed(1)}° C",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.thermostat_outlined, color: Colors.white),
              const SizedBox(height: 5),
              Text("Low", style: const TextStyle(color: Colors.white)),
              Text(
                "${_weather?.tempMin?.celsius?.toStringAsFixed(1)}° C",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.thermostat_outlined, color: Colors.white),
              const SizedBox(height: 5),
              Text("High", style: const TextStyle(color: Colors.white)),
              Text(
                "${_weather?.tempMax?.celsius?.toStringAsFixed(1)}° C",
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.white),
              const SizedBox(height: 5),
              Text("Sunrise", style: const TextStyle(color: Colors.white)),
              Text(
                formatSunsetSunriseTime(_weather?.sunrise),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          Column(
            children: [
              const Icon(Icons.nights_stay, color: Colors.white),
              const SizedBox(height: 5),
              Text("Sunset", style: const TextStyle(color: Colors.white)),
              Text(
                formatSunsetSunriseTime(_weather?.sunset),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper function to format sunrise and sunset times
  String formatSunsetSunriseTime(dynamic timestamp) {
    if (timestamp == null) return 'Not Available';
    if (timestamp is DateTime) return DateFormat("h:mm a").format(timestamp);
    if (timestamp is int) {
      DateTime time = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return DateFormat("h:mm a").format(time);
    }
    return 'Not Available';
  }
}

// String extension for capitalize method
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
