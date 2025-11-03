import 'package:flutter/material.dart';
import '../services/complaint_service.dart';
import 'complaint_list_screen.dart';
// Note: L'import de AIAnalysisService est conservé mais non utilisé, car l'analyse est côté backend

class ComplaintFormScreen extends StatefulWidget {
  const ComplaintFormScreen({super.key});

  @override
  State<ComplaintFormScreen> createState() => _ComplaintFormScreenState();
}

class _ComplaintFormScreenState extends State<ComplaintFormScreen> {
  final ComplaintService _complaintService = ComplaintService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  // Définition des couleurs du thème
  static final Color primaryDarkGreen = Colors.green.shade900!; // Vert très foncé (thème principal)
  static final Color mediumGreen = Colors.green.shade700!;    // Vert moyen (pour les boutons/touches)
  static final Color lightGreen = Colors.green.shade300!;     // Vert clair

  Future<void> _submitComplaint() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // 1. Créer la plainte via l'API (qui gère l'analyse IA)
      await _complaintService.createComplaint(
        title: _titleController.text,
        description: _descriptionController.text,
      );

      _showSuccess('Plainte créée et analysée avec succès !');

      // 2. Navigue en arrière et renvoie le signal 'true'
      if (mounted) {
        Navigator.pop(context, true); 
      }

    } catch (e) {
      _showError('Erreur lors de la soumission: $e');
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

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: mediumGreen,
        ),
      );
    }
  }

  // Fonction pour naviguer vers la liste des plaintes (utilisée par l'IconButton)
  void _navigateToList() {
    Navigator.push( 
      context,
      MaterialPageRoute(builder: (context) => const ComplaintListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- AppBar Professionnelle (Thème Vert) ---
      appBar: AppBar(
        title: const Text("Soumettre une Plainte"),
        backgroundColor: primaryDarkGreen, // Vert très foncé
        foregroundColor: Colors.white,
        elevation: 0, 
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt), 
            onPressed: _navigateToList,
            tooltip: "Voir mes plaintes",
          ),
        ],
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section d'Introduction Améliorée (Thème Vert) ---
            Text(
              "Analyse de Plainte Juridique par IA",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryDarkGreen,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Décrivez votre situation ci-dessous. Notre intelligence artificielle s'occupera de l'analyse immédiate.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 30), 

            // --- Champ Titre Amélioré ---
            Text(
              "Titre (Sujet principal) :",
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryDarkGreen),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: _getInputDecoration(
                "Ex: Problème administratif au travail",
                Icons.title,
              ),
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 25),

            // --- Champ Description Amélioré ---
            Text(
              "Description détaillée :",
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryDarkGreen),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 8,
              keyboardType: TextInputType.multiline,
              decoration: _getInputDecoration(
                "Décrivez votre problème en détail...\n\nL'IA analysera : type, points clés, urgence.",
                Icons.description,
              ).copyWith(
                alignLabelWithHint: true, 
              ),
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // --- Bouton de Soumission et Indicateur de Chargement (Thème Vert) ---
            _isLoading
                ? Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: mediumGreen),
                        const SizedBox(height: 10),
                        Text(
                          "Analyse en cours avec l'IA...",
                          style: TextStyle(color: mediumGreen),
                        ),
                      ],
                    ),
                  )
                : ElevatedButton(
                    onPressed: _submitComplaint,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), 
                      ),
                      backgroundColor: mediumGreen, // Vert moyen pour le bouton d'action
                      foregroundColor: Colors.white,
                      elevation: 5, 
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text("Analyser et Soumettre"),
                  ),
          ],
        ),
      ),
    );
  }

  // 💡 Fonction helper pour standardiser le style des champs de texte (Thème Vert)
  InputDecoration _getInputDecoration(String hintText, IconData icon) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, color: mediumGreen), // Icône en vert moyen
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none, 
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: mediumGreen, width: 2), // Bordure en vert moyen lors du focus
      ),
      filled: true,
      fillColor: Colors.grey[100], 
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}