import 'dart:convert';
import 'package:http/http.dart' as http; // Import nécessaire pour les appels HTTP
import 'package:supabase_flutter/supabase_flutter.dart';

class LegalAIService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // IMPORTANT : URL de votre API Python FastAPI. 
  // - Pour le simulateur iOS/Mac/Linux/Windows, utilisez 'http://localhost:8000'
  // - Pour le simulateur Android, utilisez 'http://10.0.2.2:8000'
  final String _pythonApiUrl = 'http://192.168.88.201:8000';
  
  // --- Méthodes d'aide ---
  
  /// Récupère le token JWT de l'utilisateur Supabase.
  Future<String> _getUserAuthToken() async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Utilisateur non connecté. Impossible d\'appeler l\'API.');
    return session.accessToken;
  }

  /// Sauvegarde la conversation utilisateur/IA dans la table 'legal_chats' de Supabase.
  Future<void> _saveChat(String userMessage, String aiResponse) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Assurez-vous que la table 'legal_chats' existe dans votre base de données Supabase
    try {
      await _supabase.from('legal_chats').insert({
        'user_id': user.id,
        'user_message': userMessage,
        'ai_response': aiResponse,
        'message_type': 'juridique',
      });
    } catch (e) {
      print('Avertissement: Échec de la sauvegarde du chat dans Supabase: $e');
      // L'erreur de chat ne doit pas bloquer la réponse de l'IA.
    }
  }

  // --- LOGIQUE RAG (Appel réel à l'API Python /legal_advice) ---

  /// Envoie la question de l'utilisateur à l'API Python pour traitement RAG (Gemini).
  Future<Map<String, dynamic>> getLegalAdvice(String userMessage) async {
    final token = await _getUserAuthToken();
    final url = Uri.parse('$_pythonApiUrl/legal_advice');
    
    // Envoi de la requête POST au format JSON
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Ajout du token JWT
      },
      // Le corps de la requête utilise 'question' pour correspondre au modèle Pydantic AIQuestion dans main.py
      body: jsonEncode({'question': userMessage}), 
    );

    if (response.statusCode == 200) {
      // Réponse réussie de l'API Python
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      // Sauvegarde de l'historique (meilleure position pour éviter de sauvegarder des erreurs)
      await _saveChat(userMessage, data['response']);
      
      return {
        'response': data['response'],
        'sources': List<String>.from(data['sources']),
        'suggestions': List<String>.from(data['suggestions']),
      };
    } else {
      // Gestion des erreurs HTTP (400, 500, etc.)
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception('API RAG échec (${response.statusCode}): ${errorBody['detail']}');
      } catch (e) {
        throw Exception('API RAG échec (${response.statusCode}). Vérifiez l\'URL de l\'API et le statut du serveur.');
      }
    }
  }

  // --- Historique de Chat (Conservé) ---

  /// Récupère l'historique des chats juridiques depuis Supabase.
  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('legal_chats')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
// Note: Les anciennes fonctions de simulation (_generateLegalResponse, _getLegalSources, _getNextSuggestions) 
// ont été supprimées car elles sont remplacées par l'appel à l'API Python.