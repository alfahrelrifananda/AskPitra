import 'package:flutter/material.dart';
import '../models/conversation.dart';

class AppDrawer extends StatelessWidget {
  final ColorScheme colorScheme;
  final List<Conversation> conversations;
  final Conversation? currentConversation;
  final bool isDarkMode;
  final VoidCallback onNewConversation;
  final Function(Conversation) onSwitchConversation;
  final Function(Conversation) onDeleteConversation;
  final VoidCallback onThemeToggle;
  final VoidCallback onShowAbout;

  const AppDrawer({
    super.key,
    required this.colorScheme,
    required this.conversations,
    required this.currentConversation,
    required this.isDarkMode,
    required this.onNewConversation,
    required this.onSwitchConversation,
    required this.onDeleteConversation,
    required this.onThemeToggle,
    required this.onShowAbout,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: colorScheme.surface,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Column(
        children: [
          _buildHeader(context),
          _buildNewChatButton(),
          _buildConversationsList(),
          const Divider(),
          _buildThemeToggle(),
          _buildAboutButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 50, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.primaryContainer.withOpacity(0.1),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 48,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'AskPitra',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'AI Assistant untuk UPITRA',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onPrimaryContainer.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewChatButton() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onNewConversation,
          icon: const Icon(Icons.add),
          label: const Text('Obrolan Baru'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    return Expanded(
      child: conversations.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final isSelected = currentConversation?.id == conversation.id;

                return ConversationListItem(
                  conversation: conversation,
                  isSelected: isSelected,
                  colorScheme: colorScheme,
                  onTap: () => onSwitchConversation(conversation),
                  onDelete: () => onDeleteConversation(conversation),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada obrolan',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    return ListTile(
      leading: Icon(
        isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: colorScheme.onSurfaceVariant,
      ),
      title: const Text('Mode Gelap'),
      trailing: Switch(
        value: isDarkMode,
        onChanged: (bool value) => onThemeToggle(),
        activeColor: colorScheme.primary,
      ),
      onTap: onThemeToggle,
    );
  }

  Widget _buildAboutButton() {
    return ListTile(
      leading: Icon(Icons.info_outline, color: colorScheme.onSurfaceVariant),
      title: const Text('Tentang Aplikasi'),
      onTap: onShowAbout,
    );
  }
}

class ConversationListItem extends StatelessWidget {
  final Conversation conversation;
  final bool isSelected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.isSelected,
    required this.colorScheme,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected
            ? colorScheme.primaryContainer.withOpacity(0.3)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 16, right: 4),
          leading: Icon(
            Icons.chat_outlined,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurface.withOpacity(0.6),
            size: 20,
          ),
          title: Text(
            conversation.title,
            style: TextStyle(
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            _formatDate(conversation.updatedAt),
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          trailing: PopupMenuButton(
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Text('Hapus', style: TextStyle(color: Colors.red.shade400)),
                  ],
                ),
                onTap: onDelete,
              ),
            ],
          ),
          onTap: onTap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Hari ini';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
