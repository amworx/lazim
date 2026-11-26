import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/enums.dart';
import '../domain/models.dart';
import '../l10n/app_localizations.dart';

/// Localised labels and visuals for domain enums.
extension NeedStatusL10n on NeedStatus {
  String label(AppL10n l) => switch (this) {
        NeedStatus.open => l.statusOpen,
        NeedStatus.claimed => l.statusClaimed,
        NeedStatus.purchased => l.statusPurchased,
        NeedStatus.archived => l.statusArchived,
      };
}

extension NeedPriorityL10n on NeedPriority {
  String label(AppL10n l) => switch (this) {
        NeedPriority.low => l.priorityLow,
        NeedPriority.normal => l.priorityNormal,
        NeedPriority.urgent => l.priorityUrgent,
      };
}

extension NeedCategoryL10n on NeedCategory {
  String label(AppL10n l) => switch (this) {
        NeedCategory.groceries => l.categoryGroceries,
        NeedCategory.household => l.categoryHousehold,
        NeedCategory.pharmacy => l.categoryPharmacy,
        NeedCategory.personal => l.categoryPersonal,
        NeedCategory.kids => l.categoryKids,
        NeedCategory.kitchen => l.categoryKitchen,
        NeedCategory.electronics => l.categoryElectronics,
        NeedCategory.other => l.categoryOther,
      };

  IconData get icon => switch (this) {
        NeedCategory.groceries => Icons.shopping_basket_outlined,
        NeedCategory.household => Icons.cleaning_services_outlined,
        NeedCategory.pharmacy => Icons.medication_outlined,
        NeedCategory.personal => Icons.spa_outlined,
        NeedCategory.kids => Icons.child_care_outlined,
        NeedCategory.kitchen => Icons.kitchen_outlined,
        NeedCategory.electronics => Icons.electrical_services_outlined,
        NeedCategory.other => Icons.inventory_2_outlined,
      };
}

/// Icons a family can pick for a custom category. Keys are stored, so they must
/// stay stable; adding new ones is safe, renaming is not.
const Map<String, IconData> categoryIcons = {
  'label': Icons.label_outline_rounded,
  'shopping_basket': Icons.shopping_basket_outlined,
  'cleaning': Icons.cleaning_services_outlined,
  'medication': Icons.medication_outlined,
  'spa': Icons.spa_outlined,
  'child': Icons.child_care_outlined,
  'kitchen': Icons.kitchen_outlined,
  'electrical': Icons.electrical_services_outlined,
  'inventory': Icons.inventory_2_outlined,
  'pets': Icons.pets_outlined,
  'school': Icons.school_outlined,
  'car': Icons.directions_car_outlined,
  'tools': Icons.handyman_outlined,
  'gift': Icons.card_giftcard_outlined,
  'work': Icons.work_outline_rounded,
  'sports': Icons.sports_soccer_outlined,
};

IconData categoryIconFor(NeedCategoryDef def) {
  if (def.builtIn != null) return def.builtIn!.icon;
  return categoryIcons[def.iconKey] ?? categoryIcons['label']!;
}

/// Display name for a category: built-ins translate with the app language,
/// custom ones show the name the family typed.
String categoryLabel(NeedCategoryDef def, AppL10n l) =>
    def.builtIn?.label(l) ?? (def.name.trim().isEmpty ? l.categoryOther : def.name);

extension AttachmentKindL10n on AttachmentKind {  IconData get icon => switch (this) {
        AttachmentKind.link => Icons.link_rounded,
        AttachmentKind.image => Icons.image_outlined,
        AttachmentKind.pdf => Icons.picture_as_pdf_outlined,
        AttachmentKind.document => Icons.description_outlined,
        AttachmentKind.other => Icons.attach_file_rounded,
      };
}

/// Relative day label: Today / Yesterday / Nd ago / a date.
String relativeDay(DateTime at, AppL10n l, String localeName) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(at.year, at.month, at.day);
  final diff = today.difference(that).inDays;
  if (diff <= 0) return l.today;
  if (diff == 1) return l.yesterday;
  if (diff < 7) return l.daysAgo(diff);
  return DateFormat.yMMMd(localeName).format(at);
}

String clockTime(DateTime at, String localeName) =>
    DateFormat.Hm(localeName).format(at);

/// Formats a byte size for attachment chips.
String formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value >= 10 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

/// Picks a readable text colour for an arbitrary background.
Color onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : const Color(0xFF1C1A19);
