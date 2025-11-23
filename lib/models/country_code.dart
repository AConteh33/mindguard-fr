class CountryCode {
  final String name;
  final String code;  // e.g., 'US', 'FR', 'BJ'
  final String dialCode; // e.g., '+1', '+33', '+229'
  final String flag; // e.g., '🇺🇸', '🇫🇷', '🇧🇯'

  CountryCode({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
  });

  @override
  String toString() {
    return '$flag ${dialCode}';
  }
}