import 'dart:convert';
import 'package:http/http.dart' as http;

class AIAnalysisService {
  final String openAIApiKey; // Vous ajouterez ça plus tard

  AIAnalysisService({required this.openAIApiKey});

  // Analyser une plainte avec OpenAI
  Future<Map<String, dynamic>> analyzeComplaint(String complaintText) async {
    try {
      // Simulation d'analyse IA (à remplacer par OpenAI plus tard)
      await Future.delayed(Duration(seconds: 2));
      
      // Logique simple de catégorisation
      String category = _categorizeComplaint(complaintText);
      int severity = _determineSeverity(complaintText);
      
      return {
        'summary': _generateSummary(complaintText),
        'category': category,
        'key_points': _extractKeyPoints(complaintText),
        'severity': severity,
        'status': 'analysé'
      };
    } catch (e) {
      throw Exception('Erreur d\'analyse IA: $e');
    }
  }

  String _categorizeComplaint(String text) {
    text = text.toLowerCase();
    if (text.contains('travail') || text.contains('emploi') || text.contains('salaire')) {
      return 'travail';
    } else if (text.contains('santé') || text.contains('médecin') || text.contains('hôpital')) {
      return 'santé';
    } else if (text.contains('administratif') || text.contains('document') || text.contains('formulaire')) {
      return 'administratif';
    } else if (text.contains('environnement') || text.contains('pollution') || text.contains('déchet')) {
      return 'environnement';
    } else {
      return 'social';
    }
  }

  int _determineSeverity(String text) {
    text = text.toLowerCase();
    if (text.contains('urgent') || text.contains('grave') || text.contains('immédiat')) {
      return 3;
    } else if (text.contains('important') || text.contains('sérieux')) {
      return 2;
    } else {
      return 1;
    }
  }

  String _generateSummary(String text) {
    if (text.length > 100) {
      return '${text.substring(0, 100)}... [Résumé automatique]';
    }
    return '$text [Résumé complet]';
  }

  List<String> _extractKeyPoints(String text) {
    List<String> points = [];
    
    if (text.length > 50) points.add('Problème principal identifié');
    if (text.contains('?')) points.add('Question posée');
    if (text.length > 100) points.add('Contexte détaillé fourni');
    
    points.add('Nécessite un suivi');
    
    return points;
  }
}