import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class WeatherSuggestions extends StatefulWidget {
  final String weatherCondition;
  final double temperature;

  const WeatherSuggestions({
    Key? key,
    required this.weatherCondition,
    required this.temperature,
  }) : super(key: key);

  @override
  State<WeatherSuggestions> createState() => _WeatherSuggestionsState();
}

class _WeatherSuggestionsState extends State<WeatherSuggestions>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _pageController = PageController(viewportFraction: 0.85);
    
    // Auto-scroll suggestions
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _autoScroll();
      }
    });
  }

  void _autoScroll() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        final suggestions = _getWeatherSuggestions();
        if (_currentPage < suggestions.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _autoScroll();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _getWeatherSuggestions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: Icon(
                      _getWeatherIcon(),
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: const Text(
                      'Weather Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: suggestions.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final suggestion = suggestions[index];
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = _pageController.page! - index;
                    value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
                  }
                  return Transform.scale(
                    scale: Curves.easeOutQuint.transform(value),
                    child: child,
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getCardColor(index).withOpacity(0.7),
                        _getCardColor(index).withOpacity(0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getCardColor(index).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: -5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Icon(
                                    suggestion.icon,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    suggestion.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Text(
                              suggestion.text,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 15,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              suggestions.length,
              (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 8,
                width: _currentPage == index ? 24 : 8,
                decoration: BoxDecoration(
                  color: _currentPage == index
                      ? _getCardColor(index)
                      : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getCardColor(int index) {
    final condition = widget.weatherCondition.toLowerCase();
    if (condition.contains('rain')) {
      return Colors.blue;
    } else if (condition.contains('snow')) {
      return Colors.lightBlue;
    } else if (condition.contains('clear')) {
      return Colors.orange;
    } else if (condition.contains('cloud')) {
      return Colors.grey;
    } else if (condition.contains('thunderstorm')) {
      return Colors.deepPurple;
    }
    return Colors.teal;
  }

  IconData _getWeatherIcon() {
    final condition = widget.weatherCondition.toLowerCase();
    if (condition.contains('rain') || condition.contains('drizzle')) {
      return Icons.umbrella;
    } else if (condition.contains('snow')) {
      return Icons.ac_unit;
    } else if (condition.contains('clear')) {
      return Icons.wb_sunny;
    } else if (condition.contains('cloud')) {
      return Icons.cloud;
    } else if (condition.contains('thunderstorm')) {
      return Icons.flash_on;
    }
    return Icons.info_outline;
  }

  List<WeatherAdvice> _getWeatherSuggestions() {
    final condition = widget.weatherCondition.toLowerCase();
    final suggestions = <WeatherAdvice>[];

    if (condition.contains('rain') || condition.contains('drizzle')) {
      suggestions.addAll([
        WeatherAdvice(
          icon: Icons.umbrella,
          title: 'Rain Protection',
          text: 'Carry an umbrella and wear waterproof clothing to stay dry.',
        ),
        WeatherAdvice(
          icon: Icons.directions_car,
          title: 'Drive Safely',
          text: 'Reduce speed and maintain safe distance. Roads may be slippery.',
        ),
        WeatherAdvice(
          icon: Icons.warning,
          title: 'Flood Warning',
          text: 'Watch out for water accumulation and avoid flood-prone areas.',
        ),
      ]);
    } else if (condition.contains('snow')) {
      suggestions.addAll([
        WeatherAdvice(
          icon: Icons.ac_unit,
          title: 'Winter Gear',
          text: 'Bundle up with warm layers and wear insulated, waterproof boots.',
        ),
        WeatherAdvice(
          icon: Icons.directions_car,
          title: 'Winter Driving',
          text: 'Drive slowly and keep emergency supplies in your vehicle.',
        ),
        WeatherAdvice(
          icon: Icons.house,
          title: 'Home Safety',
          text: 'Keep your home warm and check on elderly neighbors.',
        ),
      ]);
    } else if (condition.contains('clear')) {
      suggestions.addAll([
        WeatherAdvice(
          icon: Icons.wb_sunny,
          title: 'Sun Protection',
          text: 'Use sunscreen and wear protective clothing. Stay hydrated!',
        ),
        WeatherAdvice(
          icon: Icons.directions_run,
          title: 'Outdoor Activity',
          text: 'Perfect weather for outdoor exercises and activities.',
        ),
      ]);
    } else if (condition.contains('thunderstorm')) {
      suggestions.addAll([
        WeatherAdvice(
          icon: Icons.flash_on,
          title: 'Storm Safety',
          text: 'Stay indoors and away from windows during the storm.',
        ),
        WeatherAdvice(
          icon: Icons.power,
          title: 'Power Outage',
          text: 'Keep emergency lights and backup power sources ready.',
        ),
      ]);
    }

    // Add temperature-based suggestions
    if (widget.temperature > 35) {
      suggestions.add(
        WeatherAdvice(
          icon: Icons.thermostat,
          title: 'Heat Alert',
          text: 'Extreme heat! Stay hydrated and avoid direct sun exposure.',
        ),
      );
    } else if (widget.temperature < 10) {
      suggestions.add(
        WeatherAdvice(
          icon: Icons.ac_unit,
          title: 'Cold Alert',
          text: 'Very cold conditions! Dress warmly and protect exposed skin.',
        ),
      );
    }

    return suggestions;
  }
}

class WeatherAdvice {
  final IconData icon;
  final String title;
  final String text;

  WeatherAdvice({
    required this.icon,
    required this.title,
    required this.text,
  });
}
