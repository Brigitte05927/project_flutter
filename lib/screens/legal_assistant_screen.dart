import 'package:flutter/material.dart';
import '../services/legal_ai_service.dart';

// --- MODÈLE DE DONNÉES CLAIR ---
class ChatMessage {
  final String content;
  final String type; // 'user', 'ai', 'error'
  final List<String> sources; // Sources RAG
  final List<String> suggestions; // Suggestions de questions suivantes
  final DateTime time;

  ChatMessage({
    required this.content, 
    this.type = 'ai', 
    this.sources = const [], 
    this.suggestions = const [], 
    required this.time
  });
}

class LegalAssistantScreen extends StatefulWidget {
  const LegalAssistantScreen({super.key});

  @override
  State<LegalAssistantScreen> createState() => _LegalAssistantScreenState();
}

class _LegalAssistantScreenState extends State<LegalAssistantScreen> {
  final LegalAIService _legalService = LegalAIService();
  final _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _conversation = [];
  bool _isLoading = false;

  // Définition des couleurs du thème Vert
  static final Color primaryDarkGreen = Colors.green.shade900!; // Vert très foncé (thème principal)
  static final Color mediumGreen = Colors.green.shade700!;    // Vert moyen (pour les boutons/touches)
  static final Color lightGreen = Colors.green.shade300!;     // Vert clair (pour les fonds/sources)
  static final Color userChatColor = mediumGreen;              // Bulle utilisateur en Vert moyen
  static final Color aiChatColor = Colors.grey.shade100;      // Bulle AI (fond clair pour la lisibilité)

  @override
  void initState() {
    super.initState();
    _loadInitialMessage();
  }
  
  void _loadInitialMessage() {
    setState(() {
      _conversation.add(ChatMessage(
        content: "Bonjour ! Je suis votre Assistant Juridique AI (basé sur le RAG). Posez-moi une question sur le droit du travail, de la famille, ou autre. J'utiliserai mes sources pour vous répondre.",
        type: 'ai',
        time: DateTime.now(),
        suggestions: ['licenciement abusif', 'garde d\'enfants', 'créer une plainte'],
      ));
    });
  }

  Future<void> _sendMessage({String? quickQuestion}) async {
    final userMessage = quickQuestion ?? _messageController.text;

    if (userMessage.isEmpty) return;

    _messageController.clear();

    // 1. Ajouter le message utilisateur
    setState(() {
      _conversation.insert(0, ChatMessage(
        content: userMessage,
        type: 'user',
        time: DateTime.now(),
      ));
      _isLoading = true;
    });
    
    _scrollToBottom();

    try {
      // 2. Obtenir la réponse de l'IA (format Map pour RAG)
      final responseData = await _legalService.getLegalAdvice(userMessage);
      
      // 3. Ajouter la réponse de l'IA
      setState(() {
        _conversation.insert(0, ChatMessage(
          content: responseData['response'] ?? 'Erreur: Réponse IA vide.',
          type: 'ai',
          sources: (responseData['sources'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          suggestions: (responseData['suggestions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
          time: DateTime.now(),
        ));
      });
    } catch (e) {
      setState(() {
        _conversation.insert(0, ChatMessage(
          content: 'Désolé, une erreur de connexion à l\'AI est survenue: ${e.toString().replaceAll('Exception: ', '')}',
          type: 'error',
          time: DateTime.now(),
        ));
      });
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
        _scrollToBottom();
      }
    }
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  // --- WIDGET POUR UNE BULLE DE MESSAGE ---
  Widget _buildMessage(ChatMessage message) {
    final isUser = message.type == 'user';
    final isError = message.type == 'error';
    final isAI = message.type == 'ai';
    
    // Définition des couleurs de la bulle
    final color = isUser ? userChatColor : (isError ? Colors.red[600] : aiChatColor);
    final textColor = isUser || isError ? Colors.white : Colors.black87;
    final alignment = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    final margin = isUser ? const EdgeInsets.only(left: 8) : const EdgeInsets.only(right: 8);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône AI (en vert foncé)
          if (isAI) 
            CircleAvatar(
              backgroundColor: lightGreen.withOpacity(0.5),
              child: Icon(Icons.gavel, color: primaryDarkGreen, size: 20),
            ),

          Column(
            crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // 1. La Bulle de Contenu
              Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                margin: margin,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16.0).copyWith(
                    bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16.0),
                    bottomLeft: isUser ? const Radius.circular(16.0) : const Radius.circular(0),
                  ),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 2)),
                  ],
                ),
                child: Text(
                  message.content,
                  style: TextStyle(color: textColor, fontSize: 15.0),
                ),
              ),

              // 2. Sources RAG (pour l'IA uniquement)
              if (isAI && message.sources.isNotEmpty)
                _buildSourcesSection(message.sources, isUser),
              
              // 3. Suggestions (pour l'IA uniquement)
              if (isAI && message.suggestions.isNotEmpty)
                _buildSuggestionChips(message.suggestions),

              // 4. Heure du message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Text(
                  '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
            ],
          ),

          // Icône Utilisateur
          if (isUser) 
            CircleAvatar(
              backgroundColor: lightGreen,
              child: Icon(Icons.person, color: primaryDarkGreen, size: 20),
            ),
        ],
      ),
    );
  }

  // --- WIDGET SECTION SOURCES (en vert) ---
  Widget _buildSourcesSection(List<String> sources, bool isUser) {
    return Container(
      margin: EdgeInsets.only(top: 4, left: isUser ? 0 : 8, right: isUser ? 8 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.2), // Fond vert très clair
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lightGreen) // Bordure verte
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sources RAG citées :",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: primaryDarkGreen), // Titre en vert foncé
          ),
          const SizedBox(height: 2),
          ...sources.take(3).map((source) => Text( 
            '• $source',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )).toList(),
        ],
      ),
    );
  }

  // --- WIDGET SUGGESTIONS (Chips en vert) ---
  Widget _buildSuggestionChips(List<String> suggestions) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 4.0,
        children: suggestions.map((text) => GestureDetector(
          onTap: _isLoading ? null : () => _sendMessage(quickQuestion: text),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey[100] : lightGreen.withOpacity(0.3), // Fond vert très clair
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isLoading ? Colors.grey[300]! : mediumGreen), // Bordure en vert moyen
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: _isLoading ? Colors.grey[500] : primaryDarkGreen), // Texte en vert foncé
            ),
          ),
        )).toList(),
      ),
    );
  }

  // --- WIDGET BARRE DE SAISIE (en vert) ---
  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0),
            child: Icon(Icons.search, color: mediumGreen), // Icône de recherche en vert moyen
          ),
          // Champ de saisie
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: TextField(
                controller: _messageController,
                onSubmitted: _isLoading ? null : (text) => _sendMessage(),
                decoration: const InputDecoration.collapsed(
                  hintText: "Posez votre question juridique...",
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          // Bouton d'envoi
          Container(
            margin: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: _isLoading ? 
                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: primaryDarkGreen)) 
                : const Icon(Icons.send),
              color: primaryDarkGreen, // Bouton en vert foncé
              onPressed: _isLoading ? null : () => _sendMessage(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assistant Juridique IA (RAG)"),
        backgroundColor: primaryDarkGreen, // AppBar en vert foncé
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Liste des messages (Zone de Chat)
          Flexible(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              reverse: true, // Affiche les nouveaux messages en bas
              itemBuilder: (_, int index) => _buildMessage(_conversation[index]),
              itemCount: _conversation.length,
            ),
          ),
          
          // Zone de saisie
          _buildTextComposer(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
