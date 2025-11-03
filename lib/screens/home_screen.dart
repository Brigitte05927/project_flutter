import 'package:flutter/material.dart';
import 'package:analyse_plaintes/services/legal_ai_service.dart'; // Commenté car non utilisé dans la classe
import '../services/auth_service.dart';
import 'complaint_form_screen.dart';
import 'legal_assistant_screen.dart';
import 'complaint_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final AuthService _authService = AuthService();

  // Définition des couleurs du thème
  static final Color primaryDarkGreen = const Color.fromARGB(255, 1, 34, 3); // Vert très foncé
  static final Color mediumGreen = Colors.green.shade700;    // Vert moyen
  static final Color lightGreen = Colors.green.shade300;     // Vert clair pour le fond

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    
    return Scaffold(
      // Utilisation d'un fond très légèrement vert clair pour le contraste
      backgroundColor: lightGreen.withOpacity(0.1), 
      
      appBar: AppBar(
        title: const Text(
          'Analyse de Plaintes Juridiques',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryDarkGreen, // AppBar en Vert très foncé
        foregroundColor: Colors.white,
        elevation: 0, // Enlever l'ombre pour un look plus plat
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. En-tête de Bienvenue (Design sophistiqué) ---
            _buildWelcomeHeader(context, user?.email),
            
            const SizedBox(height: 30),
            
            // --- 2. Titre des Options ---
            Text(
              'Que souhaitez-vous faire ?',
              style: TextStyle(
                fontSize: 20, 
                fontWeight: FontWeight.w600, 
                color: primaryDarkGreen
              ),
            ),
            
            const SizedBox(height: 20),
            
            // --- 3. Options principales (avec couleurs harmonisées) ---
            
            // Carte Assistant Juridique (Couleur Primaire)
            _buildFeatureCard(
              context,
              '🤖 Assistant Juridique IA',
              'Posez vos questions juridiques, obtenez des conseils instantanés.',
              Icons.gavel, // Icône changée pour plus de pertinence juridique
              primaryDarkGreen,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LegalAssistantScreen()),
                );
              },
            ),
            
            const SizedBox(height: 15),
            
            // Carte Nouvelle Plainte (Couleur Accent / Orange pour l'action)
            _buildFeatureCard(
              context,
              '📝 Nouvelle Plainte',
              'Créez et analysez une nouvelle plainte automatiquement.',
              Icons.description,
              Colors.orange.shade700, // Une couleur qui contraste bien avec le vert
              () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ComplaintFormScreen()),
                );
                
                if (result == true) { 
                  // Naviguer vers la liste après la soumission réussie
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ComplaintListScreen()),
                  );
                }
              },
            ),
            
            const SizedBox(height: 15),
            
            // Carte Mes Plaintes (Couleur Secondaire)
            _buildFeatureCard(
              context,
              '📂 Mes Plaintes',
              'Consultez l\'historique de vos documents et analyses.',
              Icons.folder_open,
              mediumGreen, // Utilisation du vert moyen
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ComplaintListScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Nouveau Widget pour l'en-tête de bienvenue (pour plus de clarté)
  Widget _buildWelcomeHeader(BuildContext context, String? email) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: primaryDarkGreen.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryDarkGreen.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bienvenue, Utilisateur 👋',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Votre assistant juridique intelligent est prêt. Gérez, analysez et comprenez vos dossiers.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const Divider(height: 20, color: Colors.white38),
          Text(
            'Email: ${email ?? 'Non connecté'}',
            style: const TextStyle(
              fontSize: 14, 
              color: Colors.white54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // Widget de carte de fonctionnalité amélioré
  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 8, // Augmentation de l'ombre
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Coins plus arrondis
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.1),
        highlightColor: color.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Row(
            children: [
              // Conteneur d'icône plus grand et plus visible
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color, // Couleur solide de la carte
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Colors.white, size: 35), // Icône blanche pour le contraste
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color, size: 28), // Flèche colorée
            ],
          ),
        ),
      ),
    );
  }
}