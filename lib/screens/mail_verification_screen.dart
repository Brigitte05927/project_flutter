import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _emailSent = false;

  Future<void> _checkVerification() async {
    setState(() { _isLoading = true; });
    try {
      // Recharger l'utilisateur pour vérifier si l'email est confirmé
      await _authService.reloadUser();
      final user = _authService.currentUser;
      
      if (user != null) {
        // L'utilisateur est connecté, on peut accéder à l'application
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        }
      } else {
        _showError('Veuillez vérifier votre email et cliquer sur le lien de confirmation');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  Future<void> _resendVerification() async {
    setState(() { _isLoading = true; });
    try {
      await _authService.resendVerificationEmail(widget.email);
      if (mounted) {
        setState(() { _emailSent = true; });
        _showSuccess('Email de vérification envoyé !');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.mark_email_unread_outlined, size: 64, color: Colors.orange),
                  const SizedBox(height: 20),
                  const Text(
                    "Vérification d'email requise",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Un email de vérification a été envoyé à votre adresse.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Veuillez cliquer sur le lien dans l'email pour activer votre compte.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  if (_emailSent)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Email renvoyé avec succès !',
                              style: TextStyle(color: Colors.green),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            ElevatedButton(
                              onPressed: _checkVerification,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[800],
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: const Text("J'ai vérifié mon email"),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _resendVerification,
                              child: const Text("Renvoyer l'email de vérification"),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () async {
                                await _authService.signOut();
                                if (mounted) Navigator.pop(context);
                              },
                              child: const Text(
                                "Changer d'email",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}