import 'package:intl/intl.dart';

/// Currencies offered in the picker — kept short and curated rather than
/// every ISO 4217 code, matching the rest of the app's small fixed-choice
/// pickers (categories, icons, etc.).
const supportedCurrencyCodes = ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED'];

/// [currencyCode] defaults to EGP, matching [BudgetSettings.currencyCode]'s
/// own default — used before the settings row has loaded yet.
String formatCents(int cents, {String currencyCode = 'EGP'}) {
  return NumberFormat.simpleCurrency(name: currencyCode).format(cents / 100);
}
