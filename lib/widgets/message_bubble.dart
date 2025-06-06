// Flutter imports
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Project imports
import 'package:ottr/models/message_model.dart';

/// Widget to display a message in a chat bubble
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isCurrentUser;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isCurrentUser 
                ? const Color(0xFFE3F2FD) // messageSentColor
                : Theme.of(context).colorScheme.surface, // messageReceivedColor
            borderRadius: BorderRadius.circular(16.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: const TextStyle(fontSize: 16.0),
              ),
              const SizedBox(height: 4.0),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 12.0,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (isCurrentUser) ...[
                    const SizedBox(width: 4.0),
                    _buildStatusIcon(),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build message status icon
  Widget _buildStatusIcon() {
    switch (message.status) {
      case MessageStatus.sending:
        return const Icon(
          Icons.access_time,
          size: 12.0,
          color: Colors.grey,
        );
      case MessageStatus.sent:
        return const Icon(
          Icons.check,
          size: 12.0,
          color: Colors.grey,
        );
      case MessageStatus.delivered:
        return const Icon(
          Icons.done_all,
          size: 12.0,
          color: Colors.grey,
        );
      case MessageStatus.read:
        return const Icon(
          Icons.done_all,
          size: 12.0,
          color: Colors.blue,
        );
    }
  }

  /// Format timestamp to readable time
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
    );

    if (messageDate == today) {
      // Today, show only time
      return DateFormat.jm().format(dateTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday, ${DateFormat.jm().format(dateTime)}';
    } else {
      // Other days
      return DateFormat('MMM d, h:mm a').format(dateTime);
    }
  }
}
