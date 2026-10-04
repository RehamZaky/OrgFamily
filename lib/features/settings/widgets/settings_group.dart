import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';

/// The Settings screen's one type scale — every text on the screen takes
/// its size and weight from here, so sections can't drift apart.
class SettingsText {
  SettingsText._();

  static TextStyle header(BuildContext context) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: context.colors.textSecondary,
      );

  static TextStyle title(BuildContext context) => TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.colors.textPrimary,
      );

  static TextStyle subtitle(BuildContext context) => TextStyle(
        fontSize: 13,
        height: 1.3,
        color: context.colors.textSecondary,
      );

  static const control = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
}

/// A section label above a [SettingsGroup].
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(4, 24, 4, 8),
      child: Text(label, style: SettingsText.header(context)),
    );
  }
}

/// One card holding a section's rows, separated by inset hairlines.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(height: 1, indent: 16, endIndent: 16, color: context.colors.border),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// The tinted square icon every row leads with.
class SettingsIcon extends StatelessWidget {
  const SettingsIcon(this.icon, {super.key, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

/// A compact row: tinted icon, one-line title and subtitle, and either a
/// trailing action or a chevron when the row itself is tappable.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Tints the row's background — for the one thing that needs attention.
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: highlighted ? color.withValues(alpha: 0.08) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              SettingsIcon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: SettingsText.title(context),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: SettingsText.subtitle(context),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Directionality.of(context) == TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: context.colors.textSecondary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A row whose control sits underneath it — icon and title on top, then a
/// full-width control (e.g. a segmented button) and an optional hint.
class SettingsControlRow extends StatelessWidget {
  const SettingsControlRow({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.control,
    this.hint,
  });

  final IconData icon;
  final Color color;
  final String title;
  final Widget control;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SettingsIcon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: SettingsText.title(context))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: control),
          if (hint != null) ...[
            const SizedBox(height: 8),
            Text(hint!, style: SettingsText.subtitle(context)),
          ],
        ],
      ),
    );
  }
}

/// [SegmentedButton] styling shared by every Settings choice, so their
/// labels use [SettingsText.control] rather than each picking its own.
ButtonStyle settingsSegmentedStyle() => const ButtonStyle(
      textStyle: WidgetStatePropertyAll(SettingsText.control),
      visualDensity: VisualDensity.compact,
    );
