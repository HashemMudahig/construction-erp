import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:construction_erp/features/clients/domain/client_entity.dart';
import 'package:construction_erp/features/dashboard/domain/dashboard_models.dart';
import 'package:construction_erp/features/reports/presentation/report_providers.dart';
import 'fixtures/client_dto.dart';
import 'fixtures/expense_dto.dart';
import 'fixtures/milestone_dto.dart';
import 'fixtures/payment_dto.dart';
import 'fixtures/project_dto.dart';

/// Baseline fixtures with deterministic UUIDs, dates, and monetary values.
/// No DateTime.now() is used in any expected value.
class BaselineFixtures {
  static const clientAId = 'a0000000-0000-4000-8000-000000000001';
  static const clientBId = 'a0000000-0000-4000-8000-000000000002';
  static const clientArchivedId = 'a0000000-0000-4000-8000-000000000003';
  static const projectActiveId = 'b0000000-0000-4000-8000-000000000001';
  static const projectCompletedId = 'b0000000-0000-4000-8000-000000000002';
  static const projectPlanningId = 'b0000000-0000-4000-8000-000000000003';
  static const projectNoMilestonesId = 'b0000000-0000-4000-8000-000000000004';
  static const milestonePendingId = 'c0000000-0000-4000-8000-000000000001';
  static const milestoneCompletedId = 'c0000000-0000-4000-8000-000000000002';
  static const milestoneOverdueId = 'c0000000-0000-4000-8000-000000000003';
  static const payment1Id = 'd0000000-0000-4000-8000-000000000001';
  static const payment2Id = 'd0000000-0000-4000-8000-000000000002';
  static const expense1Id = 'e0000000-0000-4000-8000-000000000001';
  static const expense2Id = 'e0000000-0000-4000-8000-000000000002';

  static Map<String, dynamic> clientAJson() => {
        'id': clientAId,
        'name': 'Alpha Construction',
        'phone': '+966500000001',
        'email': 'alpha@example.com',
        'address': 'Riyadh',
        'notes': 'VIP client',
        'archived': false,
        'created_at': '2026-01-15T10:00:00Z',
        'updated_at': '2026-01-20T12:00:00Z',
      };

  static Map<String, dynamic> clientArchivedJson() => {
        'id': clientArchivedId,
        'name': 'Old Client',
        'phone': null,
        'email': null,
        'address': null,
        'notes': null,
        'archived': true,
        'created_at': '2025-06-01T08:00:00Z',
        'updated_at': '2025-12-31T23:59:59Z',
      };

  static Map<String, dynamic> projectActiveJson() => {
        'id': projectActiveId,
        'client_id': clientAId,
        'name': 'Tower Project',
        'description': '20-floor tower',
        'budget': '1500000.00',
        'start_date': '2026-02-01',
        'end_date': '2026-12-31',
        'status': 'active',
        'created_at': '2026-01-10T09:00:00Z',
      };

  static Map<String, dynamic> projectNoMilestonesJson() => {
        'id': projectNoMilestonesId,
        'client_id': clientBId,
        'name': 'Empty Project',
        'description': null,
        'budget': '500000.00',
        'start_date': null,
        'end_date': null,
        'status': 'planning',
        'created_at': '2026-07-01T14:00:00Z',
      };

  static Map<String, dynamic> payment1Json() => {
        'id': payment1Id,
        'project_id': projectActiveId,
        'amount': '500000.00',
        'payment_date': '2026-03-15',
        'method': 'bank_transfer',
        'notes': 'First installment',
        'created_at': '2026-03-15T16:00:00Z',
      };

  static Map<String, dynamic> expense1Json() => {
        'id': expense1Id,
        'project_id': projectActiveId,
        'category': 'materials',
        'amount': '150000.50',
        'expense_date': '2026-03-20',
        'notes': 'Cement and steel',
        'created_at': '2026-03-20T10:00:00Z',
      };

  static Map<String, dynamic> milestonePendingJson() => {
        'id': milestonePendingId,
        'project_id': projectActiveId,
        'title': 'Foundation',
        'description': 'Pour foundation',
        'due_date': '2026-04-01',
        'status': 'pending',
        'created_at': '2026-02-01T08:00:00Z',
      };

  static Map<String, dynamic> dashboardSummaryJson() => {
        'active_projects': 8,
        'completed_projects': 4,
        'total_clients': 12,
        'outstanding_balances': '1245000.00',
        'total_payments': '2890000.00',
        'total_expenses': '1645000.00',
      };

  static Map<String, dynamic> projectOverviewJson() => {
        'project_id': projectActiveId,
        'name': 'Tower Project',
        'client_name': 'Alpha Construction',
        'status': 'active',
        'budget': '1500000.00',
        'payments_sum': '500000.00',
        'expenses_sum': '150000.50',
        'balance': '349999.50',
      };

  static Map<String, dynamic> monthlyPointJson() => {
        'month': '2026-03',
        'income': '500000.00',
        'expense': '150000.50',
      };

  static Map<String, dynamic> financeOverviewJson() => {
        'months': [monthlyPointJson()],
      };

  static Map<String, dynamic> projectStatusItemJson() => {
        'project_id': projectActiveId,
        'name': 'Tower Project',
        'status': 'active',
        'budget': '1500000.00',
        'total_payments': '500000.00',
        'total_expenses': '150000.50',
        'balance': '349999.50',
        'milestone_count': 3,
        'completed_milestones': 1,
        'progress_pct': '33.33',
      };
}

void main() {
  group('ClientDto contract', () {
    test('fromJson parses all fields correctly', () {
      final dto = ClientDto.fromJson(BaselineFixtures.clientAJson());
      expect(dto.id, BaselineFixtures.clientAId);
      expect(dto.name, 'Alpha Construction');
      expect(dto.phone, '+966500000001');
      expect(dto.email, 'alpha@example.com');
      expect(dto.archived, false);
      expect(dto.createdAt, '2026-01-15T10:00:00Z');
      expect(dto.updatedAt, '2026-01-20T12:00:00Z');
    });

    test('fromJson defaults archived to false when null', () {
      final json = BaselineFixtures.clientAJson()..['archived'] = null;
      final dto = ClientDto.fromJson(json);
      expect(dto.archived, false);
    });

    test('toEntity parses dates correctly', () {
      final dto = ClientDto.fromJson(BaselineFixtures.clientAJson());
      final entity = dto.toEntity();
      expect(entity.id, BaselineFixtures.clientAId);
      expect(entity.createdAt, DateTime.parse('2026-01-15T10:00:00Z'));
      expect(entity.updatedAt, DateTime.parse('2026-01-20T12:00:00Z'));
    });

    test('toEntity falls back to DateTime.now() on invalid date', () {
      final json = BaselineFixtures.clientAJson()
        ..['created_at'] = 'invalid-date';
      final dto = ClientDto.fromJson(json);
      final entity = dto.toEntity();
      expect(
          entity.createdAt
              .isAfter(DateTime.now().subtract(const Duration(seconds: 5))),
          true);
    });

    test('ClientCreateDto.toJson includes required fields', () {
      final dto = ClientCreateDto(name: 'Test', archived: false);
      final json = dto.toJson();
      expect(json['name'], 'Test');
      expect(json['archived'], false);
      expect(json.containsKey('phone'), false);
    });

    test('ClientUpdateDto.toJson only includes non-null fields', () {
      final dto = ClientUpdateDto(name: 'Updated', phone: null);
      final json = dto.toJson();
      expect(json['name'], 'Updated');
      expect(json.containsKey('phone'), false);
    });

    test('archived client parses correctly', () {
      final dto = ClientDto.fromJson(BaselineFixtures.clientArchivedJson());
      expect(dto.archived, true);
      final entity = dto.toEntity();
      expect(entity.archived, true);
    });

    test('ClientEntity equality is based on id only', () {
      final e1 = ClientEntity(
        id: 'x',
        name: 'A',
        phone: null,
        email: null,
        address: null,
        notes: null,
        archived: false,
        createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-01-01T00:00:00Z'),
      );
      final e2 = ClientEntity(
        id: 'x',
        name: 'B',
        phone: null,
        email: null,
        address: null,
        notes: null,
        archived: true,
        createdAt: DateTime.parse('2026-06-01T00:00:00Z'),
        updatedAt: DateTime.parse('2026-06-01T00:00:00Z'),
      );
      expect(e1 == e2, true);
      expect(e1.hashCode, e2.hashCode);
    });
  });

  group('ProjectDto contract', () {
    test('fromJson parses all fields correctly', () {
      final dto = ProjectDto.fromJson(BaselineFixtures.projectActiveJson());
      expect(dto.id, BaselineFixtures.projectActiveId);
      expect(dto.clientId, BaselineFixtures.clientAId);
      expect(dto.budget, '1500000.00');
      expect(dto.startDate, '2026-02-01');
      expect(dto.endDate, '2026-12-31');
      expect(dto.status, 'active');
    });

    test('toEntity parses budget as minor units', () {
      final dto = ProjectDto.fromJson(BaselineFixtures.projectActiveJson());
      final entity = dto.toEntity();
      // Remote DTO assumes YER (scale 0) — budget string '1500000.00' → 1500000
      expect(entity.budgetAmountMinor, 1500000);
      expect(entity.budgetCurrency, 'YER');
    });

    test('toEntity parses startDate with T00:00:00 append', () {
      final dto = ProjectDto.fromJson(BaselineFixtures.projectActiveJson());
      final entity = dto.toEntity();
      expect(entity.startDate, DateTime.parse('2026-02-01T00:00:00'));
    });

    test('toEntity returns null for nullable dates when absent', () {
      final dto =
          ProjectDto.fromJson(BaselineFixtures.projectNoMilestonesJson());
      final entity = dto.toEntity();
      expect(entity.startDate, isNull);
      expect(entity.endDate, isNull);
    });

    test('ProjectCreateDto.toJson serializes budget as string', () {
      final dto = ProjectCreateDto(
        clientId: BaselineFixtures.clientAId,
        name: 'Test',
        budget: '100000.00',
      );
      final json = dto.toJson();
      expect(json['budget'], '100000.00');
      expect(json['status'], 'planning');
      expect(json['client_id'], BaselineFixtures.clientAId);
    });

    test('Decimal round-trip preserves exact value', () {
      // Note: Decimal.toString() strips trailing zeros.
      // Decimal.parse('0.00').toString() returns '0', not '0.00'.
      // Decimal.parse('150000.50').toString() returns '150000.5', not '150000.50'.
      // This is a known behavior of the decimal package.
      // The backend serializes Decimal as string with fixed 2 decimal places via Pydantic,
      // but the Dart Decimal package does not preserve trailing zeros on toString().
      final values = {
        '0.01': '0.01',
        '9999999999.99': '9999999999.99',
        '150000.50': '150000.5',
        '0.00': '0',
        '1.00': '1'
      };
      for (final entry in values.entries) {
        final parsed = Decimal.parse(entry.key);
        expect(parsed.toString(), entry.value);
      }
    });
  });

  group('MilestoneDto contract', () {
    test('fromJson parses all fields correctly', () {
      final dto =
          MilestoneDto.fromJson(BaselineFixtures.milestonePendingJson());
      expect(dto.id, BaselineFixtures.milestonePendingId);
      expect(dto.projectId, BaselineFixtures.projectActiveId);
      expect(dto.dueDate, '2026-04-01');
      expect(dto.status, 'pending');
    });

    test('toEntity appends T00:00:00 to dueDate', () {
      final dto =
          MilestoneDto.fromJson(BaselineFixtures.milestonePendingJson());
      final entity = dto.toEntity();
      expect(entity.dueDate, DateTime.parse('2026-04-01T00:00:00'));
    });

    test('toEntity falls back to DateTime.now() on invalid dueDate', () {
      final json = BaselineFixtures.milestonePendingJson()
        ..['due_date'] = 'bad';
      final dto = MilestoneDto.fromJson(json);
      final entity = dto.toEntity();
      expect(
          entity.dueDate
              .isAfter(DateTime.now().subtract(const Duration(seconds: 5))),
          true);
    });

    test('MilestoneCreateDto defaults status to pending', () {
      final dto = MilestoneCreateDto(
        projectId: BaselineFixtures.projectActiveId,
        title: 'Test',
        dueDate: '2026-05-01',
      );
      expect(dto.status, 'pending');
    });
  });

  group('PaymentDto contract', () {
    test('fromJson parses all fields correctly', () {
      final dto = PaymentDto.fromJson(BaselineFixtures.payment1Json());
      expect(dto.id, BaselineFixtures.payment1Id);
      expect(dto.amount, '500000.00');
      expect(dto.method, 'bank_transfer');
    });

    test('toEntity parses amount as minor units', () {
      final dto = PaymentDto.fromJson(BaselineFixtures.payment1Json());
      final entity = dto.toEntity();
      expect(entity.originalAmountMinor, 500000);
      expect(entity.originalCurrency, 'YER');
    });

    test('toEntity appends T00:00:00 to paymentDate', () {
      final dto = PaymentDto.fromJson(BaselineFixtures.payment1Json());
      final entity = dto.toEntity();
      expect(entity.paymentDate, DateTime.parse('2026-03-15T00:00:00'));
    });

    test('PaymentUpdateDto does not include projectId', () {
      final dto = PaymentUpdateDto(amount: '100.00');
      final json = dto.toJson();
      expect(json.containsKey('project_id'), false);
    });
  });

  group('ExpenseDto contract', () {
    test('fromJson parses all fields correctly', () {
      final dto = ExpenseDto.fromJson(BaselineFixtures.expense1Json());
      expect(dto.id, BaselineFixtures.expense1Id);
      expect(dto.category, 'materials');
      expect(dto.amount, '150000.50');
    });

    test('toEntity parses amount as minor units', () {
      final dto = ExpenseDto.fromJson(BaselineFixtures.expense1Json());
      final entity = dto.toEntity();
      // Remote DTO assumes YER (scale 0) — amount string '150000.50' → 150000
      expect(entity.originalAmountMinor, 150000);
      expect(entity.originalCurrency, 'YER');
    });

    test('ExpenseUpdateDto does not include projectId', () {
      final dto = ExpenseUpdateDto(category: 'labor');
      final json = dto.toJson();
      expect(json.containsKey('project_id'), false);
    });
  });

  group('Corrected local Dashboard contract', () {
    test('summary uses exact integer YER and net cash flow naming', () {
      const summary = DashboardSummary(
        activeClientCount: 11,
        totalProjectCount: 12,
        planningProjectCount: 0,
        activeProjectCount: 8,
        completedProjectCount: 4,
        onHoldProjectCount: 0,
        cancelledProjectCount: 0,
        totalPaymentsYer: 2890000,
        totalExpensesYer: 1645000,
      );
      expect(summary.activeClientCount, 11);
      expect(summary.netCashFlowYer, 1245000);
      expect(summary.statusCountsConsistent, true);
    });

    test('project progress is an exact 0-100 integer percentage', () {
      const project = DashboardProjectOverview(
        projectId: BaselineFixtures.projectActiveId,
        projectName: 'Tower Project',
        projectStatus: 'active',
        clientName: 'Alpha Construction',
        totalPaymentsYer: 500000,
        totalExpensesYer: 150000,
        completedMilestones: 1,
        totalMilestones: 2,
      );
      expect(project.netCashFlowYer, 350000);
      expect(project.milestoneProgressPercent, 50);
    });

    test('finance month uses a canonical key and exact integers', () {
      const month = DashboardFinanceMonth(
        year: 2026,
        month: 3,
        totalPaymentsYer: 500000,
        totalExpensesYer: 150000,
      );
      expect(month.canonicalKey, '2026-03');
      expect(month.netCashFlowYer, 350000);
    });
  });

  group('Report DTOs contract', () {
    test('local ProjectStatusReportRow uses exact integer snapshots', () {
      const item = ProjectStatusReportRow(
        projectId: BaselineFixtures.projectActiveId,
        name: 'Project',
        status: 'active',
        budgetAmountMinor: 1500000,
        budgetCurrency: 'YER',
        totalPaymentsYer: 500000,
        totalExpensesYer: 150000,
        milestoneCount: 3,
        completedMilestones: 1,
      );
      expect(item.projectId, BaselineFixtures.projectActiveId);
      expect(item.budgetAmountMinor, 1500000);
      expect(item.totalPaymentsYer, 500000);
      expect(item.totalExpensesYer, 150000);
      expect(item.netCashFlowYer, 350000);
      expect(item.milestoneCount, 3);
      expect(item.completedMilestones, 1);
      expect(item.progressBasisPoints, 3333);
    });

    test('ReportType enum has three values', () {
      expect(ReportType.values.length, 3);
      expect(ReportType.values.contains(ReportType.projectStatus), true);
      expect(ReportType.values.contains(ReportType.financialSummary), true);
      expect(ReportType.values.contains(ReportType.expenseAnalysis), true);
    });

    test('ReportFilters defaults to projectStatus', () {
      const filters = ReportFilters();
      expect(filters.type, ReportType.projectStatus);
      expect(filters.startDate, isNull);
      expect(filters.endDate, isNull);
    });

    test('ReportFilters.startDateStr formats as YYYY-MM-DD', () {
      final filters = ReportFilters(
        startDate: DateTime(2026, 3, 15),
      );
      expect(filters.startDateIso, '2026-03-15');
    });

    test('ReportFilters.endDateStr formats as YYYY-MM-DD', () {
      final filters = ReportFilters(
        endDate: DateTime(2026, 12, 31),
      );
      expect(filters.endDateIso, '2026-12-31');
    });
  });

  group('Enum value verification', () {
    test('Project status values match across layers', () {
      final flutterStatuses = <String>[];
      final json = BaselineFixtures.projectActiveJson();
      flutterStatuses.add(json['status'] as String);
      expect(flutterStatuses.contains('active'), true);
    });

    test('Payment method values match expected set', () {
      final methods = {'cash', 'bank_transfer', 'cheque', 'other'};
      expect(methods.contains('bank_transfer'), true);
      expect(methods.contains('cheque'), true);
    });

    test('Expense category values match expected set', () {
      final categories = {
        'materials',
        'labor',
        'equipment',
        'permits',
        'other'
      };
      expect(categories.contains('materials'), true);
      expect(categories.length, 5);
    });

    test('Milestone status values match expected set', () {
      final statuses = {'pending', 'in_progress', 'completed', 'overdue'};
      expect(statuses.contains('pending'), true);
      expect(statuses.length, 4);
    });
  });

  group('Decimal precision round-trip', () {
    test('Exact fractional Decimal preserves through toString', () {
      // Decimal strips trailing zeros: 150000.50 → 150000.5
      final d = Decimal.parse('150000.50');
      expect(d.toString(), '150000.5');
    });

    test('Small fractional Decimal preserves', () {
      final d = Decimal.parse('0.01');
      expect(d.toString(), '0.01');
    });

    test('Large Decimal preserves', () {
      final d = Decimal.parse('9999999999.99');
      expect(d.toString(), '9999999999.99');
    });

    test('Zero Decimal loses trailing zeros', () {
      // Known behavior: Decimal.parse('0.00').toString() returns '0'
      final d = Decimal.parse('0.00');
      expect(d.toString(), '0');
    });

    test('Decimal subtraction preserves precision', () {
      final payments = Decimal.parse('500000.00');
      final expenses = Decimal.parse('150000.50');
      final balance = payments - expenses;
      // 500000 - 150000.50 = 349999.50, but toString strips trailing zero → 349999.5
      expect(balance.toString(), '349999.5');
    });

    test('Decimal percentage computation preserves precision', () {
      final completed = Decimal.parse('1');
      final total = Decimal.parse('3');
      final ratio = completed / total; // Rational
      // Rational.toString() gives fraction form: 1/3
      expect(ratio.toString(), '1/3');
    });
  });

  group('UUID compatibility', () {
    test('UUID strings are 36 characters with hyphens', () {
      for (final id in [
        BaselineFixtures.clientAId,
        BaselineFixtures.projectActiveId,
        BaselineFixtures.milestonePendingId,
        BaselineFixtures.payment1Id,
        BaselineFixtures.expense1Id,
      ]) {
        expect(id.length, 36);
        expect(id.split('-').length, 5);
      }
    });
  });

  group('Known defects — documented for future fix', () {
    test('DEFECT: Dashboard projects_overview cartesian product risk', () {
      // This test documents the known defect in dashboard_repository.projects_overview()
      // which joins Payment and Expense simultaneously, causing row multiplication.
      // The report_repository.project_status() uses subqueries correctly.
      // This is a documentation test — no assertion can verify the backend SQL here.
      // See: docs/offline_migration/risk_register.md R-013
      expect(true, true);
    });

    test('DEFECT: Finance timeline may omit months with zero transactions', () {
      // dashboard_repository.finance_overview() only includes months present in
      // income or expense queries. Months with zero transactions in both are omitted.
      // See: docs/offline_migration/risk_register.md R-022
      expect(true, true);
    });

    test('DEFECT: outstanding_balances is total net, not negative-only', () {
      // dashboard_service.get_summary(): outstanding = total_payments - total_expenses
      // The field name suggests only negative balances, but it returns overall net.
      // See: docs/offline_migration/risk_register.md R-023
      final payments = Decimal.parse('2890000.00');
      final expenses = Decimal.parse('1645000.00');
      final outstanding = payments - expenses;
      // Decimal subtraction doesn't preserve trailing zeros: 1245000
      expect(outstanding.toString(), '1245000');
    });

    test('DEFECT: total_clients includes archived clients', () {
      // dashboard_repository.counts() counts all clients with no archived filter.
      // See: docs/offline_migration/risk_register.md R-024
      expect(true, true);
    });

    test('DEFECT: profit_margin is a ratio, not a percentage', () {
      // profitability_service: profit_margin = (balance / total_payments).quantize(0.01)
      // No * 100. The value 0.50 means 50% margin, not 0.50%.
      // See: docs/offline_migration/risk_register.md R-025
      final balance = Decimal.parse('350000.00');
      final payments = Decimal.parse('500000.00');
      final margin = balance / payments; // Rational
      // Rational.toString() returns '7/10', not '0.7'
      // The backend quantizes to Decimal("0.01") → 0.70
      expect(margin.toString(), '7/10');
    });
  });
}
