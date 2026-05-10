enum WeatherType {
  sunny('sunny'),
  cloudy('cloudy'),
  rainy('rainy'),
  snowy('snowy'),
  foggy('foggy');

  const WeatherType(this.value);

  final String value;

  static WeatherType fromValue(String value) {
    return WeatherType.values.firstWhere(
      (WeatherType weather) => weather.value == value,
      orElse: () => WeatherType.sunny,
    );
  }
}
