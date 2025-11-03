import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart'; 
import '../services/complaint_service.dart';
import '../models/complaint.dart';
import 'complaint_edit_screen.dart'; 

// ⚠️ SECURITE: REMPLACEZ CE TEXTE PAR VOTRE VRAIE CLÉ POUR LES TESTS.
// EN PRODUCTION, UTILISEZ UN FICHIER .env OU UN SERVICE BACKEND.
const String GEMINI_API_KEY = 'AIzaSyCfOQT3eJP8NOrj7xDDcm-lgeXBqYHPupM'; 

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  final ComplaintService _complaintService = ComplaintService();
  List<Complaint> _complaints = [];
  bool _isLoading = true;
  bool _hasServerError = false; // Suivre l'état de l'erreur
  
  // Définition des couleurs du thème Vert
  static final Color primaryDarkGreen = Colors.green.shade900!; // Vert très foncé (thème principal)
  static final Color mediumGreen = Colors.green.shade700!;    // Vert moyen (pour les boutons/touches)
  static final Color aiActionColor = Colors.lightGreen.shade700!; // Nouvelle couleur pour l'action IA
  static final Color editActionColor = Colors.orange.shade700!; // Garde l'orange pour Modifier
  static final Color deleteActionColor = Colors.red.shade700!;  // Garde le rouge pour Supprimer
  
  // 💡 Déclaration de l'instance _model
  late final GenerativeModel _model; 

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: GEMINI_API_KEY,
    );
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    setState(() {
      _isLoading = true;
      _hasServerError = false; // Réinitialiser l'erreur
    });
    try {
      final complaints = await _complaintService.getMyComplaints();
      setState(() {
        _complaints = complaints;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        // 💡 Afficher l'erreur et marquer l'état du serveur
        _showMessage('Erreur de connexion: $e. Vérifiez votre URL API.', isError: true);
        setState(() { 
          _isLoading = false; 
          _hasServerError = true; 
        });
      }
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : mediumGreen, // Utilise mediumGreen pour le succès
        ),
      );
    }
  }

  // Couleurs adaptées au thème ou spécifiques à la catégorie
  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'travail': return mediumGreen; // Vert pour le travail
      case 'santé': return Colors.red.shade700; // Rouge pour la santé
      case 'administratif': return Colors.blue.shade700; // Bleu pour l'administratif (pour varier)
      case 'environnement': return Colors.lightGreen.shade600; // Vert clair
      case 'social': return Colors.orange.shade700; // Orange pour le social
      default: return Colors.grey.shade600;
    }
  }

  IconData _getSeverityIcon(int? severity) {
    switch (severity) {
      case 1: return Icons.low_priority;
      case 2: return Icons.warning;
      case 3: return Icons.error;
      default: return Icons.help;
    }
  }
  
  // 💡 Fonction avec la NOUVELLE instruction système
  Future<String> _getAiResponse(Complaint complaint) async {
    if (GEMINI_API_KEY == 'YOUR_SECRET_API_KEY_HERE' || GEMINI_API_KEY.isEmpty) {
      return "ERREUR: La clé API Gemini n'a pas été configurée. Veuillez la remplacer dans le code (ligne 10).";
    }

    // 🏆 NOUVELLE INSTRUCTION SYSTÈME : Détaillée et structurée
    final systemInstruction = 
      'Vous êtes un assistant juridique et de conseil spécialisé en résolution de problèmes. Analysez la plainte fournie et proposez une solution complète et structurée. Votre réponse DOIT être divisée en sections claires et inclure : '
      '1) La Solution et les Stratégies de résolution possibles,'
      '2) Les Procédures et Étapes détaillées à suivre (avec un format de liste numérotée),'
      '3) Les Articles de droit (lois, codes) pertinents pour ce domaine et si possible leur référence exacte (ex: Code du travail article L.1221-1).'
      'Répondez uniquement en français.';
    
    // Intégrer l'instruction système directement dans le prompt puisque GenerateContentConfig n'existe
    final prompt = 
      systemInstruction + "\n\n" +
      'Plainte de catégorie "${complaint.category ?? 'Général'}" avec une sévérité de ${complaint.severity}:\n'
      'Titre: ${complaint.title}\n'
      'Résumé: ${complaint.summary ?? 'Non spécifié'}';

    try {
      final response = await _model.generateContent(
        [Content.text(prompt)],
      );
      
      return response.text ?? "Désolé, l'IA n'a pas pu générer de réponse détaillée.";
      
    } catch (e) {
      print('Erreur lors de l\'appel à l\'IA: $e');
      return "Une erreur de connexion ou de l'API est survenue. Vérifiez votre clé API et votre connexion Internet.";
    }
  }

  void _handleAiChat(BuildContext context, Complaint complaint) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(color: aiActionColor), // Indicateur en couleur IA
      ),
    );

    final reponseAI = await _getAiResponse(complaint);

    if (mounted) {
      Navigator.pop(context); 
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Conseils de l\'Assistant AI pour: ${complaint.title}'),
          content: SingleChildScrollView(
            // Le Text est maintenant dans un SingleChildScrollView pour les longues réponses
            child: Text(reponseAI), 
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Fermer', style: TextStyle(color: primaryDarkGreen)), // Bouton de fermeture en vert foncé
            ),
          ],
        ),
      );
    }
  }
  
  Future<void> _navigateToEdit(Complaint complaint) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintEditScreen(complaint: complaint),
      ),
    );

    if (result == true) {
      _loadComplaints();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mes Plaintes"),
        backgroundColor: primaryDarkGreen, // AppBar en Vert foncé
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadComplaints, // Permet de réessayer le chargement
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: mediumGreen)) // Indicateur en Vert moyen
          : _complaints.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _hasServerError ? Icons.signal_cellular_connected_no_internet_4_bar : Icons.description, 
                        size: 64, 
                        color: _hasServerError ? Colors.red : Colors.grey
                      ),
                      const SizedBox(height: 16),
                      Text(
                        // Afficher le bon message en cas d'erreur de connexion ou de données vides
                        _hasServerError 
                          ? "Impossible de charger les données. Veuillez vérifier le serveur Python et l'URL de connexion."
                          : "Aucune plainte enregistrée",
                        style: TextStyle(fontSize: 18, color: _hasServerError ? Colors.red : Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Bouton d'action en Vert moyen
                      ElevatedButton(
                        onPressed: () {
                          if (_hasServerError) {
                            _loadComplaints(); // Réessaie si c'est une erreur serveur
                          } else if (Navigator.of(context).canPop()) {
                            Navigator.pop(context); // Retourne à l'écran précédent
                          } else {
                            // Si pas d'erreur et pas d'écran précédent (page d'accueil/tab)
                            _showMessage("Ceci est l'écran principal.", isError: false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mediumGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: Text(_hasServerError ? "Réessayer la connexion" : "Retour à l'accueil"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = _complaints[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 2, // Ajout d'une légère élévation pour les cartes
                      child: ListTile(
                        leading: Icon(
                          _getSeverityIcon(complaint.severity),
                          color: _getCategoryColor(complaint.category), // Couleur basée sur la catégorie
                        ),
                        title: Text(
                          complaint.title,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (complaint.category != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Chip(
                                  label: Text(
                                    complaint.category!,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                  backgroundColor: _getCategoryColor(complaint.category),
                                ),
                              ),
                            if (complaint.summary != null)
                              Text(
                                complaint.summary!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Text(
                              "Soumis le: ${complaint.createdAt.toLocal().toString().split(' ')[0]}",
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        trailing: Row( 
                          mainAxisSize: MainAxisSize.min, 
                          children: [
                            // Bouton AI (Nouvelle couleur AI Action)
                            IconButton(
                              icon: Icon(Icons.psychology, color: aiActionColor), 
                              tooltip: 'Conseil IA',
                              onPressed: () => _handleAiChat(context, complaint),
                            ),
                            // Bouton Modifier (Couleur Orange)
                            IconButton(
                              icon: Icon(Icons.edit, color: editActionColor),
                              onPressed: () => _navigateToEdit(complaint),
                            ),
                            // Bouton Supprimer (Couleur Rouge)
                            IconButton(
                              icon: Icon(Icons.delete, color: deleteActionColor),
                              onPressed: () async {
                                try {
                                  await _complaintService.deleteComplaint(complaint.id!);
                                  _showMessage('Plainte supprimée', isError: false); // Success message
                                  _loadComplaints(); 
                                } catch (e) {
                                  _showMessage('Erreur: $e', isError: true);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
