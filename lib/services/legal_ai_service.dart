import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class LegalAIService {
  // Initialisation du client Supabase
  final SupabaseClient _supabase = Supabase.instance.client;

  // IMPORTANT : URL de votre API Python FastAPI. 
  // Conservez l'IP locale (192.168.x.x) si vous testez sur un appareil physique ou sur le même réseau que votre ordinateur.
  // Utilisez 'http://10.0.2.2:8000' si vous testez sur l'émulateur Android.
  final String _pythonApiUrl = 'http://localhost:8000';
  
  // --- Méthodes d'aide ---
  
  /// Récupère le token JWT de l'utilisateur Supabase.
  Future<String> _getUserAuthToken() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      throw Exception('Erreur d\'authentification: Utilisateur non connecté. Impossible d\'appeler l\'API.');
    } 
    return session.accessToken;
  }

  /// Sauvegarde la conversation utilisateur/IA dans la table 'legal_chats' de Supabase.
  Future<void> _saveChat(String userMessage, String aiResponse, {List<String>? sources}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // Assurez-vous que la table 'legal_chats' a la colonne 'sources' de type text[] ou jsonb
      await _supabase.from('legal_chats').insert({
        'user_id': user.id,
        'user_message': userMessage,
        'ai_response': aiResponse,
        // Les 'suggestions' ne sont PAS sauvegardées, car elles sont spécifiques à la réponse
        'sources': sources ?? [], 
        'message_type': 'juridique',
      });
    } catch (e) {
      print('Avertissement: Échec de la sauvegarde du chat dans Supabase: $e');
    }
  }

  // --- LOGIQUE RAG (Appel réel à l'API Python /legal_advice) ---

  /// Envoie la question de l'utilisateur à l'API Python pour traitement RAG (Gemini).
  Future<Map<String, dynamic>> getLegalAdvice(String userMessage) async {
    final token = await _getUserAuthToken();
    final url = Uri.parse('$_pythonApiUrl/legal_advice');
    
    // Le corps de la requête utilise 'question' pour correspondre au modèle Pydantic AIQuestion
    final body = jsonEncode({'question': userMessage}); 

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Ajout du token JWT
      },
      body: body, 
    );

    if (response.statusCode == 200) {
      // Réponse réussie de l'API Python
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      // Conversion sécurisée des listes
      final sources = (data['sources'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final suggestions = (data['suggestions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final aiResponse = data['response'] as String? ?? 'Erreur: Réponse IA vide.';
      
      // Sauvegarde de l'historique AVEC les sources
      await _saveChat(userMessage, aiResponse, sources: sources);
      
      // 🏆 CORRECTION : Inclure les suggestions dans le Map de retour
      return {
        'response': aiResponse,
        'sources': sources,
        'suggestions': suggestions, // <-- C'EST LA CORRECTION
      };
    } else {
      // Gestion des erreurs HTTP (400, 500, etc.)
      try {
        final errorBody = jsonDecode(utf8.decode(response.bodyBytes));
        final detail = errorBody['detail'] as String? ?? 'Erreur inconnue de l\'API.';
        // Lance l'erreur pour que l'interface utilisateur la gère
        throw Exception('API RAG échec (${response.statusCode}): $detail');
      } catch (e) {
        throw Exception('API RAG échec (${response.statusCode}). Vérifiez l\'URL de l\'API, l\'état du serveur Python, et votre clé GEMINI.');
      }
    }
  }

  // --- Historique de Chat ---

  /// Récupère l'historique des chats juridiques depuis Supabase.
  Future<List<Map<String, dynamic>>> getChatHistory() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('legal_chats')
          .select('user_message, ai_response, created_at, sources') 
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response as List<dynamic>);
    } catch (e) {
      print('Erreur lors de la récupération de l\'historique: $e');
      return [];
    }
  }
}