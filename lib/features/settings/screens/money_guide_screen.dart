import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Explains the Income Source / Account / Transfer split on the Money
/// screens — reachable from Settings, since new users otherwise have no way
/// to learn why a transaction asks for both "why" and "where" the money
/// moved.
class MoneyGuideScreen extends StatelessWidget {
  const MoneyGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.moneyGuideTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Text(
            l10n.moneyGuideIntro,
            style: TextStyle(color: context.colors.textSecondary),
          ),
          const SizedBox(height: 20),
          _GuideCard(
            icon: Icons.work_outline,
            color: AppColors.success,
            heading: l10n.moneyGuideIncomeSourceHeading,
            body: l10n.moneyGuideIncomeSourceBody,
          ),
          const SizedBox(height: 12),
          _GuideCard(
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.info,
            heading: l10n.moneyGuideAccountHeading,
            body: l10n.moneyGuideAccountBody,
          ),
          const SizedBox(height: 12),
          _GuideCard(
            icon: Icons.swap_horiz,
            color: AppColors.primary,
            heading: l10n.moneyGuideTransferHeading,
            body: l10n.moneyGuideTransferBody,
          ),
          const SizedBox(height: 20),
          Text(l10n.moneyGuideExamplesHeading,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.moneyGuideExample1),
                  const SizedBox(height: 8),
                  Text(l10n.moneyGuideExample2),
                  const SizedBox(height: 8),
                  Text(l10n.moneyGuideExample3),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.color,
    required this.heading,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String heading;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heading, style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(body, style: TextStyle(color: context.colors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
