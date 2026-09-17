import 'package:flutter_test/flutter_test.dart';
import 'package:groutix_app/models/inspection_report.dart';

void main() {
  group('InspectionReportDoc & Summary Tests', () {
    test('Calculates YES, NO, and Unanswered counts accurately across all 8 sections', () {
      final report = InspectionReportDoc(
        findings: {
          'main_bathroom': 'YES',
          'ensuite': 'NO',
          'shower_walls': 'YES',
          'failed_cracked_grout': 'YES',
          'mould_black_grout': 'NO',
        },
      );

      final summary = report.summary;
      expect(summary.yesCount, equals(3));
      expect(summary.noCount, equals(2));
      expect(summary.totalItems, greaterThan(20));
      expect(summary.unansweredCount, equals(summary.totalItems - 5));
    });

    test('Toggling findings updates report state immutably', () {
      final initial = InspectionReportDoc();
      final updated = initial.copyWith(
        findings: {'single_shower': 'YES'},
      );

      expect(initial.findings.containsKey('single_shower'), isFalse);
      expect(updated.findings['single_shower'], equals('YES'));
      expect(updated.summary.yesCount, equals(1));
    });
  });
}
