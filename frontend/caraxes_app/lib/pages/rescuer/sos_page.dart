import 'package:caraxes_app/pages/rescuer/sos_card.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SosPage extends StatelessWidget {
  const SosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOS Requests'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sos')
            .orderBy('created_at', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // No data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No SOS requests found'));
          }

          final sosDocuments = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: sosDocuments.length,
            itemBuilder: (context, index) {
              final doc = sosDocuments[index];

              final data = doc.data() as Map<String, dynamic>;

              return SosCard(documentId: doc.id, data: data);
            },
          );
        },
      ),
    );
  }
}
