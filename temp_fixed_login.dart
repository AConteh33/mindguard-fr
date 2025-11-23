import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final emailOrPhone = _emailController.text.trim();
      
      // Determine if the input is an email or phone number
      if (emailOrPhone.contains('@')) {
        // It's an email
        await Provider.of<AuthProvider>(context, listen: false).signIn(
          emailOrPhone,
          _passwordController.text,
        );
      } else {
        // It's a phone number - the AuthProvider will handle normalization
        await Provider.of<AuthProvider>(context, listen: false).signInWithPhone(
          emailOrPhone, // Pass the raw input, AuthProvider will normalize
        );

        // Navigate to phone verification screen for SMS code with minimal data
        context.go('/phone-verification?phone=${Uri.encodeComponent(emailOrPhone)}&flowType=login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
      body: SafeArea(
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
                      Icons.shield_moon,
                      size: 80,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bienvenue sur MindGuard FR',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Connectez-vous pour gérer votre bien-être numérique',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ShadCard(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email ou numéro de téléphone',
                                hintText: 'Entrez votre email ou numéro',
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre email ou numéro';
                                }
                                
                                // Check if it's an email
                                if (value.contains('@')) {
                                  // Validate as email
                                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                                    return 'Veuillez entrer un email valide';
                                  }
                                } else {
                                  // Validate as phone number
                                  final phoneDigitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                                  if (phoneDigitsOnly.length < 9) {
                                    return 'Numéro de téléphone invalide';
                                  }
                                }
                                
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                hintText: 'Entrez votre mot de passe',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword 
                                      ? Icons.visibility_outlined 
                                      : Icons.visibility_off_outlined,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _showPassword = !_showPassword;
                                    });
                                  },
                                ),
                                border: const OutlineInputBorder(),
                              ),
                              obscureText: !_showPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre mot de passe';
                                }
                                if (value.length < 6) {
                                  return 'Le mot de passe doit contenir au moins 6 caractères';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            ShadButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text('Se connecter'),
                            ),
                            const SizedBox(height: 16),
                            ShadButton.outline(
                              onPressed: () {
                                context.go('/phone-number');
                              },
                              child: const Text('Connexion avec numéro'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Mot de passe oublié?'),
                        ShadButton.link(
                          onPressed: () {
                            // Handle forgot password
                          },
                          child: const Text('Réinitialiser'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        context.go('/phone-number');
                      },
                      child: const Text('S\'inscrire avec le numéro de téléphone'),
                    ),
                  ],
                    if (kDebugMode) _buildQuickLoginButtons(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }


  // Quick login buttons for development
  Widget _buildQuickLoginButtons() {
    return Column(
      children: [
        const Divider(
          height: 40,
          thickness: 1,
        ),
        const Center(
          child: Text(
            'Développement uniquement',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Connexion rapide (Développement)',
          style: Theme.of(context).textTheme.titleSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          alignment: WrapAlignment.center,
          children: [
            ShadButton.outline(
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false)
                    .quickLogin('parent');
                if (mounted) {
                  context.go('/main');
                }
              },
              child: const Text('Parent'),
            ),
            ShadButton.outline(
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false)
                    .quickLogin('child');
                if (mounted) {
                  context.go('/main');
                }
              },
              child: const Text('Enfant'),
            ),
            ShadButton.outline(
              onPressed: () async {
                await Provider.of<AuthProvider>(context, listen: false)
                    .quickLogin('professional');
                if (mounted) {
                  context.go('/main');
                }
              },
              child: const Text('Pro'),
            ),
          ],
        ),
      ],
    );
