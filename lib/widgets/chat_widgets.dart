import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ChatWidgets {
  static Widget buildWelcomeScreen(
    ColorScheme colorScheme,
    List<String> suggestions,
    Function(String) onSuggestionTap,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 64,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Selamat datang di AskPitra!\nTanyakan apa saja tentang UPITRA',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          _buildKnowledgeIndicator(colorScheme),
          const SizedBox(height: 24),
          _buildSuggestionCards(colorScheme, suggestions, onSuggestionTap),
        ],
      ),
    );
  }

  static Widget _buildKnowledgeIndicator(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Knowledge Base Active',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSuggestionCards(
    ColorScheme colorScheme,
    List<String> suggestions,
    Function(String) onSuggestionTap,
  ) {
    return Builder(
      builder: (context) {
        return SizedBox(
          width: double.infinity,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return Card(
                color: colorScheme.secondaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  onTap: () => onSuggestionTap(suggestion),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.45,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      suggestion,
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  static Widget buildLoadingIndicator(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.secondaryContainer,
            child: Icon(
              Icons.auto_awesome,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Shimmer.fromColors(
              baseColor: colorScheme.surfaceVariant,
              highlightColor: colorScheme.surface,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildInputField(
    BuildContext context,
    ColorScheme colorScheme,
    TextEditingController textController,
    Function(String) onSubmit,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 12.0, bottom: 12.0),
      color: colorScheme.surface,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Tanyakan sesuatu...',
                    hintStyle: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                  onSubmitted: onSubmit,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: AnimatedBuilder(
                  animation: textController,
                  builder: (context, child) {
                    final bool hasText = textController.text.isNotEmpty;
                    return IconButton(
                      onPressed: hasText
                          ? () => onSubmit(textController.text)
                          : null,
                      style: IconButton.styleFrom(
                        backgroundColor: hasText
                            ? colorScheme.primary
                            : colorScheme.surfaceVariant,
                        padding: const EdgeInsets.all(8),
                      ),
                      icon: Icon(
                        Icons.send_rounded,
                        color: hasText
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showClearChatDialog(
    BuildContext context,
    ColorScheme colorScheme,
    VoidCallback onConfirm,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Clear Chat History?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to clear all chat history? Click cancel to abort.',
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.onSurfaceVariant,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}