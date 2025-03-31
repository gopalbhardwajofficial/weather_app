import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:weather/weather.dart';
import 'package:geolocator/geolocator.dart';
import 'package:bhardwaj_weather/consts.dart';
import 'package:bhardwaj_weather/widgets/weather_animations.dart';
import 'package:bhardwaj_weather/widgets/animated_text.dart';
import 'package:bhardwaj_weather/widgets/weather_suggestions.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final WeatherFactory _wf = WeatherFactory(OPENWEATHER_API_KEY);
  Weather? _weather;
  List<Weather>? _forecast;
  final TextEditingController _cityController = TextEditingController();
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isSearching = false;
  List<Weather> _hourlyForecast = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _getCurrentLocationWeather();
    _startAutoRefreshTime();
    _animationController.forward();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  void _startAutoRefreshTime() {
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {});
    });
  }

  Future<void> _getCurrentLocationWeather() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 5),
      );

      // Get list of weather data for nearby locations
      List<Weather> nearbyWeather = await _wf.fiveDayForecastByLocation(
        position.latitude,
        position.longitude,
      );

      // Find the closest location by comparing coordinates
      Weather closestWeather = nearbyWeather.reduce((curr, next) {
        double currDist = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          curr.latitude!,
          curr.longitude!,
        );
        double nextDist = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          next.latitude!,
          next.longitude!,
        );
        return currDist < nextDist ? curr : next;
      });

      // Fetch detailed weather for the closest location
      await _fetchWeatherByCoordinates(
        closestWeather.latitude!,
        closestWeather.longitude!,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchWeatherByCoordinates(double lat, double lon) async {
    try {
      Weather weather = await _wf.currentWeatherByLocation(lat, lon);
      List<Weather> forecast = await _wf.fiveDayForecastByLocation(lat, lon);
      setState(() {
        _weather = weather;
        _forecast = forecast;
        _hourlyForecast = forecast.sublist(0, 12);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching weather: ${e.toString()}')),
      );
    }
  }

  Future<void> _fetchWeatherByCityName(String city) async {
    try {
      Weather weather = await _wf.currentWeatherByCityName(city);
      List<Weather> forecast = await _wf.fiveDayForecastByCityName(city);
      setState(() {
        _weather = weather;
        _forecast = forecast;
        _isSearching = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: City not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2E335A),
              const Color(0xFF1C1B33),
            ],
          ),
        ),
        child: _buildUI(),
      ),
    );
  }

  Widget _buildUI() {
    if (_weather == null) {
      return const Center(child: CircularProgressIndicator(
        color: Colors.white,
      ));
    }

    return Stack(
      children: [
        if (_weather != null)
          Positioned.fill(
            child: WeatherAnimation(
              weatherCondition: _weather!.weatherMain ?? '',
            ),
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  if (_isSearching) _buildSearchBar(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildMainWeatherInfo(),
                            const SizedBox(height: 30),
                            _buildDetailedInfo(),
                            const SizedBox(height: 30),
                            _buildHourlyForecast(),
                            const SizedBox(height: 30),
                            WeatherSuggestions(
                              weatherCondition: _weather!.weatherMain ?? "",
                              temperature: _weather!.temperature?.celsius ?? 0,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Row(
                      children: [
                        _buildRotatingLogo(),
                        const SizedBox(width: 10),
                        AnimatedLoopText(
                          text: 'Weather App',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search,
                        color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isSearching = !_isSearching;
                        if (!_isSearching) {
                          _cityController.clear();
                        }
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location, color: Colors.white),
                    onPressed: _getCurrentLocationWeather,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_weather?.areaName ?? ""}, ${_weather?.country ?? ""}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('EEEE, d MMMM').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRotatingLogo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 20),
      builder: (context, value, child) {
        return Transform.rotate(
          angle: value * 2 * 3.14159,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.wb_sunny,
              color: Colors.white,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _cityController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search city...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          prefixIcon: const Icon(Icons.search, color: Colors.white),
        ),
        onSubmitted: (value) {
          if (value.isNotEmpty) {
            _fetchWeatherByCityName(value);
          }
        },
      ),
    );
  }

  Widget _buildMainWeatherInfo() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1000),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.white.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Transform.scale(
                          scale: 1.0 + (value * 0.2),
                          child: Text(
                            '${_weather?.temperature?.celsius?.toStringAsFixed(1)}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _weather?.weatherMain ?? '',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                    Transform.scale(
                      scale: value,
                      child: Transform.rotate(
                        angle: value * 2 * 3.14159,
                        child: Icon(
                          _getWeatherIcon(_weather?.weatherMain ?? ''),
                          color: Colors.white,
                          size: 80,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWeatherDetail(
                      Icons.thermostat,
                      'Feels Like',
                      '${_weather?.tempFeelsLike?.celsius?.toStringAsFixed(1)}°C',
                    ),
                    _buildWeatherDetail(
                      Icons.water_drop,
                      'Humidity',
                      '${_weather?.humidity}%',
                    ),
                    _buildWeatherDetail(
                      Icons.air,
                      'Wind',
                      '${_weather?.windSpeed?.toStringAsFixed(1)} m/s',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeatherDetail(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(
                'Feels Like',
                '${_weather?.tempFeelsLike?.celsius?.toStringAsFixed(0)}°',
                Icons.thermostat,
              ),
              _buildDetailItem(
                'Low',
                '${_weather?.tempMin?.celsius?.toStringAsFixed(0)}°',
                Icons.arrow_downward,
              ),
              _buildDetailItem(
                'High',
                '${_weather?.tempMax?.celsius?.toStringAsFixed(0)}°',
                Icons.arrow_upward,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailItem(
                'Sunrise',
                DateFormat('HH:mm').format(_weather?.sunrise ?? DateTime.now()),
                Icons.wb_sunny,
              ),
              _buildDetailItem(
                'Sunset',
                DateFormat('HH:mm').format(_weather?.sunset ?? DateTime.now()),
                Icons.nightlight_round,
              ),
              _buildDetailItem(
                'Humidity',
                '${_weather?.humidity}%',
                Icons.water_drop,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    return Container(
      height: 150,
      margin: const EdgeInsets.only(left: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _hourlyForecast.length,
        itemBuilder: (context, index) {
          final hourly = _hourlyForecast[index];
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 500 + (index * 100)),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(hourly.date!),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                        ),
                      ),
                      Icon(
                        _getWeatherIcon(hourly.weatherMain ?? ''),
                        color: Colors.white,
                        size: 32,
                      ),
                      Text(
                        '${hourly.temperature?.celsius?.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getWeatherIcon(String weatherCondition) {
    switch (weatherCondition.toLowerCase()) {
      case 'thunderstorm':
        return Icons.flash_on;
      case 'drizzle':
        return Icons.grain;
      case 'rain':
        return Icons.water_drop;
      case 'snow':
        return Icons.ac_unit;
      case 'clear':
        return Icons.wb_sunny;
      case 'clouds':
        return Icons.cloud;
      default:
        return Icons.cloud;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
