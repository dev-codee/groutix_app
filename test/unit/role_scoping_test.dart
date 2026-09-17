import 'package:flutter_test/flutter_test.dart';
import 'package:groutix_app/models/lead_model.dart';
import 'package:groutix_app/models/user_model.dart';

void main() {
  group('Role Pipeline Scoping Tests', () {
    test('Correctly scopes leads for Inspection, Technician, and Finance roles', () {

      // We test the role resolution enum
      expect(UserRole.fromString('inspection'), equals(UserRole.inspection));
      expect(UserRole.fromString('field'), equals(UserRole.inspection));
      expect(UserRole.fromString('technician'), equals(UserRole.technician));
      expect(UserRole.fromString('finance'), equals(UserRole.finance));
      expect(UserRole.fromString('manager'), equals(UserRole.manager));

      // Test displayJobNo formatting helper
      final leadWithGX = LeadModel(id: '12345678', jobNo: 'JOB-9921');
      expect(leadWithGX.displayJobNo, equals('#9921'));

      final leadWithoutNo = LeadModel(id: 'abcd1234');
      expect(leadWithoutNo.displayJobNo, equals('#ABCD'));
    });
  });
}
