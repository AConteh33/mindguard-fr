import '../models/country_code.dart';

class CountryCodesService {
  static List<CountryCode> getCountryCodes() {
    return [
      CountryCode(name: 'Benin', code: 'BJ', dialCode: '+229', flag: '🇧🇯'),
      CountryCode(name: 'Sierra Leone', code: 'SL', dialCode: '+232', flag: '🇸🇱'),
      CountryCode(name: 'Saudi Arabia', code: 'SA', dialCode: '+966', flag: '🇸🇦'),
      CountryCode(name: 'United States', code: 'US', dialCode: '+1', flag: '🇺🇸'),
      CountryCode(name: 'Canada', code: 'CA', dialCode: '+1', flag: '🇨🇦'),
      CountryCode(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: '🇬🇧'),
      CountryCode(name: 'France', code: 'FR', dialCode: '+33', flag: '🇫🇷'),
      CountryCode(name: 'Germany', code: 'DE', dialCode: '+49', flag: '🇩🇪'),
      CountryCode(name: 'Italy', code: 'IT', dialCode: '+39', flag: '🇮🇹'),
      CountryCode(name: 'Spain', code: 'ES', dialCode: '+34', flag: '🇪🇸'),
      CountryCode(name: 'Netherlands', code: 'NL', dialCode: '+31', flag: '🇳🇱'),
      CountryCode(name: 'Belgium', code: 'BE', dialCode: '+32', flag: '🇧🇪'),
      CountryCode(name: 'Czech Republic', code: 'CZ', dialCode: '+420', flag: '🇨🇿'),
      CountryCode(name: 'Romania', code: 'RO', dialCode: '+40', flag: '🇷🇴'),
      CountryCode(name: 'Greece', code: 'GR', dialCode: '+30', flag: '🇬🇷'),
      CountryCode(name: 'Portugal', code: 'PT', dialCode: '+351', flag: '🇵🇹'),
      CountryCode(name: 'Hungary', code: 'HU', dialCode: '+36', flag: '🇭🇺'),
      CountryCode(name: 'Austria', code: 'AT', dialCode: '+43', flag: '🇦🇹'),
      CountryCode(name: 'Bulgaria', code: 'BG', dialCode: '+359', flag: '🇧🇬'),
      CountryCode(name: 'Denmark', code: 'DK', dialCode: '+45', flag: '🇩🇰'),
      CountryCode(name: 'Finland', code: 'FI', dialCode: '+358', flag: '🇫🇮'),
      CountryCode(name: 'Croatia', code: 'HR', dialCode: '+385', flag: '🇭🇷'),
      CountryCode(name: 'Ireland', code: 'IE', dialCode: '+353', flag: '🇮🇪'),
      CountryCode(name: 'Lithuania', code: 'LT', dialCode: '+370', flag: '🇱🇹'),
      CountryCode(name: 'Luxembourg', code: 'LU', dialCode: '+352', flag: '🇱🇺'),
      CountryCode(name: 'Latvia', code: 'LV', dialCode: '+371', flag: '🇱🇻'),
      CountryCode(name: 'Malta', code: 'MT', dialCode: '+356', flag: '🇲🇹'),
      CountryCode(name: 'Norway', code: 'NO', dialCode: '+47', flag: '🇳🇴'),
      CountryCode(name: 'Sweden', code: 'SE', dialCode: '+46', flag: '🇸🇪'),
      CountryCode(name: 'Slovenia', code: 'SI', dialCode: '+386', flag: '🇸🇮'),
      CountryCode(name: 'Slovakia', code: 'SK', dialCode: '+421', flag: '🇸🇰'),
      CountryCode(name: 'Albania', code: 'AL', dialCode: '+355', flag: '🇦🇱'),
      CountryCode(name: 'Estonia', code: 'EE', dialCode: '+372', flag: '🇪🇪'),
      CountryCode(name: 'Serbia', code: 'RS', dialCode: '+381', flag: '🇷🇸'),
      CountryCode(name: 'Switzerland', code: 'CH', dialCode: '+41', flag: '🇨🇭'),
      CountryCode(name: 'Cyprus', code: 'CY', dialCode: '+357', flag: '🇨🇾'),
      CountryCode(name: 'Iceland', code: 'IS', dialCode: '+354', flag: '🇮🇸'),
      CountryCode(name: 'Liechtenstein', code: 'LI', dialCode: '+423', flag: '🇱🇮'),
      CountryCode(name: 'Monaco', code: 'MC', dialCode: '+377', flag: '🇲🇨'),
      CountryCode(name: 'Montenegro', code: 'ME', dialCode: '+382', flag: '🇲🇪'),
      CountryCode(name: 'North Macedonia', code: 'MK', dialCode: '+389', flag: '🇲🇰'),
      CountryCode(name: 'Andorra', code: 'AD', dialCode: '+376', flag: '🇦🇩'),
      CountryCode(name: 'Gibraltar', code: 'GI', dialCode: '+350', flag: '🇬🇮'),
      CountryCode(name: 'Poland', code: 'PL', dialCode: '+48', flag: '🇵🇱'),
      CountryCode(name: 'Vatican City', code: 'VA', dialCode: '+379', flag: '🇻🇦'),
      CountryCode(name: 'India', code: 'IN', dialCode: '+91', flag: '🇮🇳'),
      CountryCode(name: 'Australia', code: 'AU', dialCode: '+61', flag: '🇦🇺'),
      CountryCode(name: 'Japan', code: 'JP', dialCode: '+81', flag: '🇯🇵'),
      CountryCode(name: 'China', code: 'CN', dialCode: '+86', flag: '🇨🇳'),
      CountryCode(name: 'South Africa', code: 'ZA', dialCode: '+27', flag: '🇿🇦'),
      CountryCode(name: 'Nigeria', code: 'NG', dialCode: '+234', flag: '🇳🇬'),
      CountryCode(name: 'Ghana', code: 'GH', dialCode: '+233', flag: '🇬🇭'),
      CountryCode(name: 'Senegal', code: 'SN', dialCode: '+221', flag: '🇸🇳'),
      CountryCode(name: 'Côte d\'Ivoire', code: 'CI', dialCode: '+225', flag: '🇨🇮'),
      CountryCode(name: 'Togo', code: 'TG', dialCode: '+228', flag: '🇹🇬'),
      CountryCode(name: 'Niger', code: 'NE', dialCode: '+227', flag: '🇳🇪'),
      CountryCode(name: 'Burkina Faso', code: 'BF', dialCode: '+226', flag: '🇧🇫'),
      CountryCode(name: 'Mali', code: 'ML', dialCode: '+223', flag: '🇲🇱'),
      CountryCode(name: 'Cameroon', code: 'CM', dialCode: '+237', flag: '🇨🇲'),
    ];
  }

  static CountryCode getCountryCodeByDialCode(String dialCode) {
    final codes = getCountryCodes();
    return codes.firstWhere(
      (element) => element.dialCode == dialCode,
      orElse: () => codes.firstWhere((element) => element.code == 'BJ'), // Default to Benin
    );
  }

  static CountryCode getCountryCodeByCode(String code) {
    final codes = getCountryCodes();
    return codes.firstWhere(
      (element) => element.code == code,
      orElse: () => codes.firstWhere((element) => element.code == 'BJ'), // Default to Benin
    );
  }
}