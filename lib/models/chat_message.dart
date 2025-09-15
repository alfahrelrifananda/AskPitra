import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  late final DateTime timestamp;

  ChatMessage({
    Key? key,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : super(key: key) {
    this.timestamp = timestamp ?? DateTime.now();
  }

  bool _hasCodeBlocks(String text) {
    final RegExp codeBlockExp = RegExp(
      r'\`\`\`(\w*)\n(.*?)\n\`\`\`',
      dotAll: true,
    );
    return codeBlockExp.hasMatch(text);
  }

  List<Widget> _parseContent(String text, TextStyle defaultStyle) {
    final List<Widget> widgets = [];
    final RegExp codeBlockExp = RegExp(r'```(\w*)\n(.*?)```', dotAll: true);
    int start = 0;

    codeBlockExp.allMatches(text).forEach((codeMatch) {
      if (codeMatch.start > start) {
        final beforeText = text.substring(start, codeMatch.start);
        widgets.add(_buildRichText(beforeText, defaultStyle));
      }

      final language = codeMatch.group(1) ?? '';
      final code = codeMatch.group(2) ?? '';
      widgets.add(_buildCodeBlock(language, code));

      start = codeMatch.end;
    });

    if (start < text.length) {
      widgets.add(_buildRichText(text.substring(start), defaultStyle));
    }

    return widgets;
  }

  Widget _buildRichText(String text, TextStyle defaultStyle) {
    return RichText(
      text: TextSpan(style: defaultStyle, children: _parseBoldSpans(text)),
    );
  }

  Widget _buildCodeBlock(String language, String code) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (language.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                language,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          SelectableText(
            code,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _parseBoldSpans(String text) {
    final List<TextSpan> spans = [];
    final RegExp boldExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    boldExp.allMatches(text).forEach((match) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start)));
      }

      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );

      start = match.end;
    });

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans;
  }

  void _showMessageOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: colorScheme.surface,
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: Icon(
                      Icons.content_copy,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      'Copy',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Icon(
                      Icons.copy_all,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: text));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Pesan Berhasil disalin'),
                          backgroundColor: colorScheme.primaryContainer,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onLongPress: () => _showMessageOptions(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                backgroundColor: colorScheme.secondaryContainer,
                child: Icon(
                  Icons.auto_awesome,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser
                      ? colorScheme.primaryContainer
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._parseContent(
                      text,
                      TextStyle(
                        color: isUser
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timestamp.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser
                            ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                            : colorScheme.onSecondaryContainer.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.person,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}