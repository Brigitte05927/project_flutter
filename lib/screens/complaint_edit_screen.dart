// complaint_edit_screen.dart

import 'package:flutter/material.dart';
import '../services/complaint_service.dart';
import '../models/complaint.dart';

class ComplaintEditScreen extends StatefulWidget {
  final Complaint complaint;

  const ComplaintEditScreen({super.key, required this.complaint});

  @override
  State<ComplaintEditScreen> createState() => _ComplaintEditScreenState();
}

class _ComplaintEditScreenState extends State<ComplaintEditScreen> {
  final ComplaintService _complaintService = ComplaintService();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialise les contrôleurs avec les valeurs actuelles de la plainte
    _titleController = TextEditingController(text: widget.complaint.title);
    _descriptionController = TextEditingController(text: widget.complaint.description);
  }

  Future<void> _submitUpdate() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showError('Veuillez remplir tous les champs');
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Appel au service de modification (PUT)
      await _complaintService.updateComplaint(
        complaintId: widget.complaint.id!,
        title: _titleController.text,
        description: _descriptionController.text,
      );

      _showSuccess('Plainte modifiée et ré-analysée avec succès !');

      // Ferme la page et renvoie 'true' pour que la liste soit rafraîchie
      if (mounted) {
        Navigator.pop(context, true); 
      }

    } catch (e) {
      _showError('Erreur lors de la modification: $e');
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier la plainte"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Modification de: ${widget.complaint.title}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Nouveau titre de la plainte",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: "Nouvelle description (sera ré-analysée par l'IA)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Modification et ré-analyse IA en cours..."),
                    ],
                  )
                : ElevatedButton(
                    onPressed: _submitUpdate,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("Mettre à jour la plainte"),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}