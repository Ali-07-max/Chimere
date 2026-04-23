import 'package:flutter/material.dart';

import '../models/achievement.dart';
import '../theme/app_theme.dart';

class AchievementTile extends StatelessWidget {
  const AchievementTile({super.key, required this.achievement});

  final Achievement achievement;

  IconData get _icon {
    // Map emoji to icon
    final emoji = achievement.iconEmoji;
    if (emoji.contains('🌟')) return Icons.star_rounded;
    if (emoji.contains('⚡')) return Icons.bolt_rounded;
    if (emoji.contains('🔥')) return Icons.local_fire_department_rounded;
    if (emoji.contains('💎')) return Icons.diamond_rounded;
    if (emoji.contains('🏆')) return Icons.emoji_events_rounded;
    if (emoji.contains('👑')) return Icons.military_tech_rounded;
    if (emoji.contains('🦋')) return Icons.bug_report_rounded;
    if (emoji.contains('🤝')) return Icons.handshake_rounded;
    if (emoji.contains('✨')) return Icons.auto_awesome_rounded;
    return Icons.star_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              _icon,
              color: AppTheme.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.lock_open_rounded,
            color: AppTheme.success,
          ),
        ],
      ),
    );
  }
}
