import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart' as auth_provider;
import '../../services/phone_verification_service.dart';
import '../../widgets/visual/animated_background_visual.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? name;
  final String? role;
  final String? gender;
  final String? flowType; // 'login' or 'registration'

  const PhoneVerificationScreen({
    super.key,
    required this.phoneNumber,
    this.name,
    this.role,
    this.gender,
    this.flowType = 'registration', // default to registration flow
  });

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  int _resendToken = 0;
  final PhoneVerificationService _phoneVerificationService = PhoneVerificationService();

  @override
  void initState() {
    super.initState();
    _startPhoneVerification();
  }

  Future<void> _startPhoneVerification() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Store the user details in the service
      _phoneVerificationService.tempName = widget.name;
      _phoneVerificationService.tempRole = widget.role;
      _phoneVerificationService.tempGender = widget.gender;
      _phoneVerificationService.phoneNumber = widget.phoneNumber;

      await Provider.of<auth_provider.AuthProvider>(context, listen: false).registerWithPhone(
        widget.phoneNumber,
        widget.name,
        widget.role,
        gender: widget.gender,
      );

      // Show a message to the user that the code has been sent
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Code de vérification envoyé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'envoi du code: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleVerificationCode() async {
    if (_codeController.text.length != 6) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('Veuillez entrer un code de 6 chiffres'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    if (_phoneVerificationService.verificationId == null) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('En attente de la génération du code de vérification. Veuillez patienter quelques secondes.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (widget.flowType == 'registration' &&
          widget.name != null && widget.name!.isNotEmpty &&
          widget.role != null && widget.role!.isNotEmpty) {
        // This is a registration flow
        await Provider.of<auth_provider.AuthProvider>(context, listen: false).verifyPhoneCodeAndRegister(
          _phoneVerificationService.verificationId!, // Get verificationId from the service
          _codeController.text.trim(),
          widget.name,
          widget.role,
          gender: widget.gender,
        );
      } else {
        // This is a login flow - just verify the phone number
        final credential = PhoneAuthProvider.credential(
          verificationId: _phoneVerificationService.verificationId!,
          smsCode: _codeController.text.trim(),
        );

        await FirebaseAuth.instance.signInWithCredential(credential);

        // Load user from Firestore
        if (FirebaseAuth.instance.currentUser != null) {
          await Provider.of<auth_provider.AuthProvider>(context, listen: false)
              .loadUserFromFirestore(FirebaseAuth.instance.currentUser!.uid);
        }
      }

      // Clear the service data
      _phoneVerificationService.clear();

      // Navigate to appropriate screen after successful verification
      if (mounted) {
        context.go('/main');
      }
    } catch (e) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text('Erreur de vérification: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendVerificationCode() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Resend the verification code
      await Provider.of<auth_provider.AuthProvider>(context, listen: false).registerWithPhone(
        widget.phoneNumber,
        widget.name,
        widget.role,
        gender: widget.gender,
      );

      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            const SnackBar(
              content: Text('Nouveau code de vérification envoyé'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(
              content: Text('Erreur lors du renvoi du code: ${e.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
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
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vérification du numéro'),
      ),
      body: AnimatedBackgroundVisual(
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Icon(
                    Icons.phone_locked,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Code de vérification',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Un code de vérification a été envoyé à ${widget.phoneNumber}',
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
                            controller: _codeController,
                            decoration: InputDecoration(
                              labelText: 'Code de vérification',
                              hintText: 'Entrez le code reçu',
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Veuillez entrer le code';
                              }
                              if (value.length != 6) {
                                return 'Code invalide';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ShadButton(
                            onPressed: _isLoading ? null : _handleVerificationCode,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text('Vérifier'),
                          ),
                          const SizedBox(height: 16),
                          ShadButton.outline(
                            onPressed: _isLoading ? null : _resendVerificationCode,
                            child: const Text('Renvoyer le code'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      context.pop();
                    },
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}