import 'package:flutter/material.dart';
import '../models/conversation.dart';

class DialogUtils {
  static void showDeleteConversationDialog(
    BuildContext context,
    Conversation conversation,
    Function(Conversation) onDelete,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Obrolan'),
          content: Text(
            'Apakah Anda yakin ingin menghapus obrolan "${conversation.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onDelete(conversation);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  static void showAppAboutDialog(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    showAboutDialog(
      context: context,
      applicationName: 'AskPitra',
      applicationVersion: '1.0.0',
      applicationIcon: Icon(
        Icons.auto_awesome_outlined,
        size: 48,
        color: colorScheme.primary,
      ),
      children: [
        const Text(
          'AskPitra adalah asisten AI yang dirancang khusus untuk membantu mahasiswa mendapatkan informasi yang diperlukan.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Dibuat dengan ❤️ untuk komunitas UPITRA',
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  static void showClearConversationDialog(
    BuildContext context,
    VoidCallback onClear,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Semua Pesan'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus semua pesan dalam obrolan ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                onClear();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }
}
