import 'package:flutter_test/flutter_test.dart';
import 'package:org_family/core/utils/enum_display.dart';
import 'package:org_family/data/local/tables/budget_table.dart';

void main() {
  test('every transaction category has its own color', () {
    final colors = {for (final c in TransactionCategory.values) c.color};
    expect(colors, hasLength(TransactionCategory.values.length));
  });
}
