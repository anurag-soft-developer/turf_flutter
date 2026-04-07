import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../team/model/team_model.dart';

class TeamSocialLinksRow extends StatelessWidget {
  const TeamSocialLinksRow({super.key, required this.links});

  final TeamSocialLinks links;

  bool get _hasAny =>
      (links.instagram?.isNotEmpty ?? false) ||
      (links.twitter?.isNotEmpty ?? false) ||
      (links.facebook?.isNotEmpty ?? false) ||
      (links.youtube?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    if (!_hasAny) return const SizedBox.shrink();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (links.instagram != null && links.instagram!.isNotEmpty)
          _SocialButton(
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            url: links.instagram!,
            color: const Color(0xFFE1306C),
          ),
        if (links.twitter != null && links.twitter!.isNotEmpty)
          _SocialButton(
            icon: Icons.alternate_email,
            label: 'Twitter',
            url: links.twitter!,
            color: const Color(0xFF1DA1F2),
          ),
        if (links.facebook != null && links.facebook!.isNotEmpty)
          _SocialButton(
            icon: Icons.facebook_outlined,
            label: 'Facebook',
            url: links.facebook!,
            color: const Color(0xFF1877F2),
          ),
        if (links.youtube != null && links.youtube!.isNotEmpty)
          _SocialButton(
            icon: Icons.play_circle_outline,
            label: 'YouTube',
            url: links.youtube!,
            color: const Color(0xFFFF0000),
          ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String url;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => _launch(url),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launch(String raw) async {
    final normalized = raw.startsWith('http') ? raw : 'https://$raw';
    final uri = Uri.tryParse(normalized);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Silently ignore if unable to launch
    }
  }
}
