import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          const Center(
            child: Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              l10n.aboutAppName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              l10n.aboutVersion,
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.aboutDescription,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.aboutBuiltWith,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(l10n.aboutTechStack,
                      style: TextStyle(color: context.colors.textSecondary)),
                  const SizedBox(height: 4),
                  Text(
                    l10n.aboutLocalNote,
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
