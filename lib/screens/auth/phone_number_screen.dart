import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/country_codes_service.dart';
import '../../models/country_code.dart';
import '../../widgets/visual/animated_background_visual.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  CountryCode? _selectedCountryCode;

  

  @override
  void initState() {
    super.initState();
    // Default to Benin
    _selectedCountryCode = CountryCodesService.getCountryCodeByCode('BJ');
  }

  void _showCountryCodeSelector() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Sélectionnez votre pays',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 400,
                  child: ListView.builder(
                    itemCount: CountryCodesService.getCountryCodes().length,
                    itemBuilder: (context, index) {
                      final countryCode = CountryCodesService.getCountryCodes()[index];
                      return ListTile(
                        leading: Text(
                          countryCode.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(countryCode.name),
                        trailing: Text(countryCode.dialCode),
                        onTap: () {
                          setState(() {
                            _selectedCountryCode = countryCode;
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    },
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
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Combine country code and phone number
      final fullPhoneNumber = _selectedCountryCode!.dialCode + _phoneController.text.trim();

      // Start Firebase phone authentication - this will handle both sign-in and registration
      await authProvider.signInWithPhone(fullPhoneNumber);
      
      // Navigate to phone verification screen with the phone number
      // The flowType parameter will determine if it's login or registration
      context.go('/phone-verification?phone=${Uri.encodeComponent(fullPhoneNumber)}&flowType=login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de vérification: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackgroundVisual(
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Icon(
                      Icons.phone_iphone,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Entrez votre numéro',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Nous vous enverrons un code de vérification',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: ShadButton.outline(
                                      onPressed: () {
                                        _showCountryCodeSelector();
                                      },
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _selectedCountryCode?.toString() ?? '+229',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          const Icon(Icons.arrow_drop_down),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 4,
                                  child: TextFormField(
                                    controller: _phoneController,
                                    decoration: InputDecoration(
                                      labelText: 'Numéro de téléphone',
                                      hintText: 'Entrez votre numéro',
                                      border: const OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Veuillez entrer votre numéro de téléphone';
                                      }
                                      // Basic phone validation based on selected country
                                      final phoneDigitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                                      if (phoneDigitsOnly.length < 6) { // Minimum length varies by country
                                        return 'Numéro de téléphone invalide';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            ShadButton(
                              onPressed: _isLoading ? null : _handleNext,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Suivant'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () {
                        context.go('/login');
                      },
                      child: const Text('J\'ai un compte ? Connexion'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}