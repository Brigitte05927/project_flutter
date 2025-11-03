import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/complaint.dart';

class ComplaintService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 🏆 CORRECTION : L'adresse pour Flutter Web (Chrome) est OBLIGATOIREMENT 'localhost'.
  // L'adresse '10.0.2.2' (vue dans votre erreur) est pour Android Emulator uniquement.
  final String _pythonApiUrl = 'http://localhost:8000'; // ⬅️ C'EST LA LIGNE CLÉ À VÉRIFIER
  
  // Méthode pour obtenir le JWT de l'utilisateur
  Future<String> _getUserAuthToken() async {
    final session = _supabase.auth.currentSession;
    if (session == null) throw Exception('Utilisateur non connecté');
    return session.accessToken;
  }

  // --- CRÉER (AI Creation) - Passe par l'API Python ---
  Future<Complaint> createComplaint({
    required String title,
    required String description,
  }) async {
    final token = await _getUserAuthToken();
    final url = Uri.parse('$_pythonApiUrl/complaints/create');
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Envoi du JWT à Python
      },
      body: jsonEncode({
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      // Python renvoie la plainte créée et analysée.
      return Complaint.fromJson(jsonDecode(response.body));
    } else {
      // Si Python renvoie une erreur
      final errorBody = jsonDecode(response.body);
      throw Exception('Échec de la Création/Analyse AI: ${errorBody['detail']}');
    }
  }

  // --- LIRE (Lecture via l'API Python pour utiliser l'ID de test) ---
  Future<List<Complaint>> getMyComplaints() async {
    final token = await _getUserAuthToken();
    final url = Uri.parse('$_pythonApiUrl/complaints');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((json) => Complaint.fromJson(json)).toList();
    } else {
      // Gère les erreurs de connexion complètes ou les erreurs API
      try {
          final errorBody = jsonDecode(response.body);
          throw Exception('API: ${errorBody['detail']} (Statut: ${response.statusCode})');
      } catch (e) {
          // Ceci capture la timeout (ERR_CONNECTION_TIMED_OUT)
          throw Exception('Erreur de connexion (Statut: ${response.statusCode ?? 'N/A'}). Vérifiez le serveur Python et l\'URL: $_pythonApiUrl. Détail: $e');
      }
    }
  }

  // --- MODIFIER (AI Modification) - Passe par l'API Python ---
  Future<Complaint> updateComplaint({
    required String complaintId,
    String? title,
    String? description,
  }) async {
    final token = await _getUserAuthToken();
    final url = Uri.parse('$_pythonApiUrl/complaints/update');

    final payload = {
      'id': complaintId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
    };
    
    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      return Complaint.fromJson(jsonDecode(response.body));
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception('Échec de la Modification/Ré-analyse AI: ${errorBody['detail']}');
    }
  }

  // --- SUPPRIMER (AI Deletion) - Passe par l'API Python ---
  Future<void> deleteComplaint(String complaintId) async {
    final token = await _getUserAuthToken();
    final url = Uri.parse('$_pythonApiUrl/complaints/delete');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'id': complaintId,
      }),
    );

    if (response.statusCode != 200) {
      final errorBody = jsonDecode(response.body);
      throw Exception('Échec de la Suppression AI: ${errorBody['detail']}');
    }
  }
}