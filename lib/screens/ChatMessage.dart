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

  // Définition des couleurs du thème Vert (ajusté pour la clarté)
  static final Color primaryDarkGreen = Colors.green.shade900!; 
  static final Color mediumGreen = Colors.green.shade700!;    
  static final Color lightGreen = Colors.green.shade300!;     
  static final Color userChatColor = mediumGreen;              
  static final Color aiChatColor = Colors.grey.shade100;      

  @override
  void initState() {
    super.initState();
    _loadInitialData(); // Charge l'historique et le message initial
  }
  
  // Fonction combinée pour charger l'historique et le message initial
  Future<void> _loadInitialData() async {
    // 1. Charger l'historique depuis Supabase
    final history = await _legalService.getChatHistory();
    
    // Mappe les messages de l'historique (Note: l'historique ne stocke que la réponse IA)
    final List<ChatMessage> loadedMessages = history.map((chat) {
      // Nous insérons deux messages pour simuler l'historique complet (Question Utilisateur puis Réponse AI)
      final List<ChatMessage> pair = [];

      // Message utilisateur (basé sur le user_message sauvegardé)
      if (chat['user_message'] is String && (chat['user_message'] as String).isNotEmpty) {
        pair.add(ChatMessage(
          content: chat['user_message'] as String,
          type: 'user',
          time: DateTime.parse(chat['created_at'] as String),
        ));
      }

      // Réponse AI
      // NOTE IMPORTANTE: L'historique Supabase ne stocke pas les 'suggestions'
      pair.add(ChatMessage(
        content: chat['ai_response'] as String,
        type: 'ai',
        time: DateTime.parse(chat['created_at'] as String),
        sources: (chat['sources'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        suggestions: const [], 
      ));
      
      return pair;
    }).expand((i) => i).toList(); // Aplatit la liste de paires de messages

    _conversation.addAll(loadedMessages); 
    // Tri par temps pour s'assurer que l'ordre est correct (le plus récent en haut)
    _conversation.sort((a, b) => b.time.compareTo(a.time)); 

    // 3. Ajouter le message de bienvenue (uniquement si l'historique est vide)
    if (_conversation.isEmpty) {
       _conversation.insert(0, ChatMessage(
        content: "Bonjour ! Je suis votre Assistant Juridique IA (RAG) du Burundi. Posez-moi une question sur le droit du travail, de la famille, ou tout autre domaine de mes documents.",
        type: 'ai',
        time: DateTime.now(),
        suggestions: ['licenciement abusif', 'garde d\'enfants', 'causes de suspension du contrat de travail'],
      ));
    }
    
    if (mounted) {
      setState(() {});
      _scrollToTop();
    }
  }

  Future<void> _sendMessage({String? quickQuestion}) async {
    final userMessage = quickQuestion ?? _messageController.text;

    if (userMessage.isEmpty || _isLoading) return;

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
    
    _scrollToTop(); 

    try {
      // 2. Obtenir la réponse de l'IA
      final responseData = await _legalService.getLegalAdvice(userMessage);
      
      // Assurer la conversion de la liste de suggestions
      final sources = (responseData['sources'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      final suggestions = (responseData['suggestions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];
      
      // 3. Ajouter la réponse de l'IA
      setState(() {
        _conversation.insert(0, ChatMessage(
          content: responseData['response'] as String,
          type: 'ai',
          sources: sources,
          suggestions: suggestions,
          time: DateTime.now(),
        ));
      });
    } catch (e) {
      // 4. Ajouter le message d'erreur
      setState(() {
        _conversation.insert(0, ChatMessage(
          content: 'Désolé, une erreur est survenue: ${e.toString().replaceAll('Exception: ', '')}',
          type: 'error',
          time: DateTime.now(),
        ));
      });
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
        _scrollToTop();
      }
    }
  }
  
  // Défile vers le haut car la ListView est en 'reverse: true'
  void _scrollToTop() { 
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
    
    final color = isUser ? userChatColor : (isError ? Colors.red[600] : aiChatColor);
    final textColor = isUser || isError ? Colors.white : Colors.black87;
    final alignment = isUser ? MainAxisAlignment.end : MainAxisAlignment.start;
    
    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        mainAxisAlignment: alignment,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icône AI 
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
                margin: isUser ? const EdgeInsets.only(left: 8) : const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16.0).copyWith(
                    bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(16.0),
                    bottomLeft: isUser ? const Radius.circular(16.0) : const Radius.circular(4),
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
              
              // 3. Suggestions (pour l'IA uniquement) - C'EST LA CLEF POUR CONTINUER LA CONVERSATION
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

  // --- WIDGET SECTION SOURCES ---
  Widget _buildSourcesSection(List<String> sources, bool isUser) {
    return Container(
      margin: EdgeInsets.only(top: 4, left: isUser ? 0 : 8, right: isUser ? 8 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: lightGreen.withOpacity(0.2), 
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lightGreen) 
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Sources RAG citées :",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: primaryDarkGreen), 
          ),
          const SizedBox(height: 2),
          ...sources.take(3).map((source) => Text( 
            '• ${source.replaceAll(".pdf", "")}', // Enlève l'extension
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
          // 🏆 Action : Appelle _sendMessage avec le texte de la suggestion
          onTap: _isLoading ? null : () => _sendMessage(quickQuestion: text),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _isLoading ? Colors.grey[100] : lightGreen.withOpacity(0.3), 
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _isLoading ? Colors.grey[300]! : mediumGreen), 
            ),
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: _isLoading ? Colors.grey[500] : primaryDarkGreen), 
            ),
          ),
        )).toList(),
      ),
    );
  }

  // --- WIDGET BARRE DE SAISIE ---
  Widget _buildTextComposer() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.only(bottom: 8), 
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
            child: Icon(Icons.search, color: mediumGreen), 
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
          // Bouton d'envoi / Indicateur de chargement
          Container(
            margin: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              icon: _isLoading ? 
                SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: primaryDarkGreen)) 
                : const Icon(Icons.send),
              color: primaryDarkGreen, 
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
        backgroundColor: primaryDarkGreen, 
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
              reverse: true, // Affiche les nouveaux messages en haut
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