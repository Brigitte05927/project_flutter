import 'package:analyse_plaintes/screens/mail_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSignUp = false; // Connexion (false) ou Inscription (true)
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Définition des couleurs du thème
  // Utilisation d'un vert très foncé pour le thème principal
  static final Color primaryDarkGreen = Colors.green.shade900; // Nouveau vert très foncé
  static final Color darkGreen = Colors.green.shade800; // Vert foncé
  static final Color mediumGreen = Colors.green.shade600; // Vert moyen pour le dégradé

  Future<void> _submit() async {
    // 1. Validation de base
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Veuillez remplir les champs Email et Mot de passe.');
      return;
    }

    if (_isSignUp && _passwordController.text != _confirmPasswordController.text) {
      _showError('Les mots de passe ne correspondent pas.');
      return;
    }
    if (_isSignUp && _fullNameController.text.isEmpty) {
      _showError('Veuillez entrer votre nom complet pour l\'inscription.');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      if (_isSignUp) {
        // Logique d'Inscription
        await _authService.signUp(
          email: _emailController.text,
          password: _passwordController.text,
          fullName: _fullNameController.text,
        );
        // Rediriger vers l'écran de vérification
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => EmailVerificationScreen(email: _emailController.text)),
          );
        }
      } else {
        // Logique de Connexion
        await _authService.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
        _navigateToHome();
      }
    } on AuthException catch (e) {
      if (e.code == 'email_not_confirmed') {
        // Si l'email n'est pas vérifié, rediriger pour vérification
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => EmailVerificationScreen(email: _emailController.text)),
          );
        }
      } else {
        _showError('Erreur de connexion/inscription: ${e.message}');
      }
    } catch (e) {
      _showError('Une erreur inattendue est survenue: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  // --- Fonction pour les champs de texte avec style ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    bool isEmail = false,
  }) {
    bool obscure = false;
    // Gère l'obscurcissement du mot de passe
    if (isPassword) obscure = _obscurePassword;
    if (isConfirmPassword) obscure = _obscureConfirmPassword;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: labelText,
          prefixIcon: Icon(icon, color: primaryDarkGreen), // ⬅️ Utilisation du nouveau vert très foncé
          // Style de la bordure
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryDarkGreen, width: 2), // ⬅️ Utilisation du nouveau vert très foncé
          ),
          filled: true,
          fillColor: Colors.white, // Fond blanc
          // Bouton pour afficher/masquer le mot de passe
          suffixIcon: isPassword || isConfirmPassword
              ? IconButton(
                  icon: Icon(
                    obscure ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      if (isPassword) _obscurePassword = !_obscurePassword;
                      if (isConfirmPassword) _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hauteur de l'écran pour le dégradé
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      // Utilisation d'un Stack pour le fond avec dégradé
      body: Stack(
        children: [
          // 1. Fond avec Dégradé (Vert foncé)
          Container(
            height: screenHeight * 0.4, // Le dégradé occupe le haut de l'écran
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryDarkGreen, mediumGreen], // ⬅️ Nouveau dégradé plus sombre
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // 2. Contenu Centré (Formulaire)
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 50.0),
              child: Column(
                children: [
                  // --- Logo/Icône de l'Application ---
                  Icon(
                    _isSignUp ? Icons.how_to_reg : Icons.lock_open,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isSignUp ? "Créer votre Espace" : "Bienvenue",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Carte du Formulaire (plus stylée) ---
                  Card(
                    elevation: 15, // Ombre marquée
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // --- Titre du Formulaire ---
                          Text(
                            _isSignUp ? "INSCRIPTION" : "CONNEXION",
                            style: TextStyle(
                              fontSize: 22, 
                              fontWeight: FontWeight.bold, 
                              color: primaryDarkGreen // ⬅️ Utilisation du nouveau vert très foncé
                            ),
                          ),
                          const Divider(height: 25, thickness: 1.5),
                          
                          // --- Champs du Formulaire ---
                          if (_isSignUp) ...[
                            _buildTextField(
                              controller: _fullNameController,
                              labelText: "Nom complet",
                              icon: Icons.person_outline,
                            ),
                          ],
                          
                          _buildTextField(
                            controller: _emailController,
                            labelText: "Email",
                            icon: Icons.email_outlined,
                            isEmail: true,
                          ),
                          
                          _buildTextField(
                            controller: _passwordController,
                            labelText: "Mot de passe",
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                          
                          if (_isSignUp) ...[
                            _buildTextField(
                              controller: _confirmPasswordController,
                              labelText: "Confirmer le mot de passe",
                              icon: Icons.lock_reset,
                              isConfirmPassword: true,
                            ),
                          ],
                          
                          const SizedBox(height: 20),
                          
                          // --- Bouton Soumettre ---
                          _isLoading
                              ? CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(primaryDarkGreen), // ⬅️ Utilisation du nouveau vert très foncé
                                )
                              : ElevatedButton(
                                  onPressed: _submit,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryDarkGreen, // ⬅️ Utilisation du nouveau vert très foncé
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 55),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8, // Ombre sur le bouton
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  child: Text(_isSignUp ? "S'INSCRIRE" : "SE CONNECTER"),
                                ),
                          
                          const SizedBox(height: 16),
                          
                          // --- Lien de Bascule ---
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isSignUp = !_isSignUp;
                                // Nettoyage des champs non utilisés lors du basculement
                                if (!_isSignUp) {
                                  _fullNameController.clear();
                                  _confirmPasswordController.clear();
                                }
                              });
                            },
                            child: Text(
                              _isSignUp
                                  ? "Déjà un compte ? Connectez-vous"
                                  : "Pas de compte ? Créez-en un ici",
                              style: TextStyle(
                                color: primaryDarkGreen, // ⬅️ Utilisation du nouveau vert très foncé
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
