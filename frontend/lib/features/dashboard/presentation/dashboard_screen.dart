import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as ui;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'dashboard_providers.dart';
import '../domain/dashboard_models.dart';
import '../../../core/localization/app_localizations.dart';

String _formatYer(int amount, String languageCode) {
  // Preserve the established accounting display contract: Western digits are
  // used for YER amounts in both UI languages.
  return NumberFormat.decimalPattern('en').format(amount);
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final projectsAsync = ref.watch(dashboardProjectsProvider);
    final financeAsync = ref.watch(dashboardFinanceProvider);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildAppBar(now, theme),
          SliverToBoxAdapter(child: _buildProfitCard(context, summaryAsync)),
          SliverToBoxAdapter(child: _buildKpiRow(context, summaryAsync)),
          SliverToBoxAdapter(
              child: _buildActivitySection(context, projectsAsync)),
          SliverToBoxAdapter(
              child: _buildFinancialCards(context, financeAsync)),
          SliverToBoxAdapter(child: _buildQuickActions(context)),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(DateTime now, ThemeData theme) {
    final locale = ref.watch(localeProvider);
    final dateStr = DateFormat('EEEE, d MMMM yyyy',
            locale.languageCode == 'ar' ? 'ar_SA' : 'en_US')
        .format(now);

    return SliverAppBar(
      floating: true,
      backgroundColor: const Color(0xFF1E293B),
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateStr,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('welcome_engineer'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
        ],
      ),
      actions: [
        _buildActionButton(Icons.notifications_outlined, badge: true),
        // Language switcher button (AR/EN toggle)
        TextButton(
          onPressed: () => ref.read(localeProvider.notifier).toggleLocale(),
          child: Text(
            locale.languageCode == 'en' ? 'عربي' : 'EN',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildActionButton(IconData icon,
      {bool badge = false, VoidCallback? onPressed}) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          IconButton(
            icon: Icon(icon, color: Colors.white, size: 22),
            onPressed: onPressed ?? () {},
          ),
          if (badge)
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProfitCard(
      BuildContext context, AsyncValue<dynamic> summaryAsync) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: summaryAsync.when(
        loading: () => const SizedBox(
            height: 120,
            child:
                Center(child: CircularProgressIndicator(color: Colors.white))),
        error: (_, __) => Text(
            locale.languageCode == 'ar'
                ? 'خطأ في تحميل البيانات'
                : 'Error loading data',
            style: const TextStyle(color: Colors.white)),
        data: (s) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.trending_up,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      locale.languageCode == 'ar'
                          ? 'صافي التدفق النقدي'
                          : 'Net cash flow',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _formatYer(s.netCashFlowYer, locale.languageCode),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 36,
                ),
              ),
              Text(
                'YER',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 70,
                child: CustomPaint(
                  painter: _SparklinePainter(),
                  size: Size.infinite,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, AsyncValue<dynamic> summaryAsync) {
    final locale = ref.watch(localeProvider);
    return summaryAsync.when(
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => SizedBox(
          height: 100,
          child: Center(
              child: Text(locale.languageCode == 'ar'
                  ? 'خطأ في التحميل'
                  : 'Error loading'))),
      data: (s) {
        final kpis = [
          _KpiData(
            title: context.tr('projects'),
            value: '${s.activeProjectCount + s.completedProjectCount}',
            icon: Icons.folder,
            color: const Color(0xFF3B82F6),
            trend: '',
            trendUp: true,
          ),
          _KpiData(
            title: context.tr('completed'),
            value: '${s.completedProjectCount}',
            icon: Icons.check_circle,
            color: const Color(0xFF10B981),
            trend: '',
            trendUp: true,
          ),
          _KpiData(
            title: context.tr('active'),
            value: '${s.activeProjectCount}',
            icon: Icons.analytics,
            color: const Color(0xFFF59E0B),
            trend: '',
            trendUp: false,
          ),
          _KpiData(
            title: locale.languageCode == 'ar' ? 'معلقة' : 'Pending',
            value: '${s.activeClientCount}',
            icon: Icons.schedule,
            color: const Color(0xFF8B5CF6),
            trend: '',
            trendUp: true,
          ),
        ];
        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kpis.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _KpiCard(kpi: kpis[i]),
          ),
        );
      },
    );
  }

  Widget _buildActivitySection(BuildContext context,
      AsyncValue<List<DashboardProjectOverview>> projectsAsync) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  locale.languageCode == 'ar'
                      ? 'نظرة عامة على المشاريع'
                      : 'Project overview',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/projects'),
                child: Text(context.tr('view_all')),
              ),
            ],
          ),
          const SizedBox(height: 16),
          projectsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(locale.languageCode == 'ar'
                ? 'خطأ في التحميل'
                : 'Error loading'),
            data: (projects) => projects.isEmpty
                ? Text(locale.languageCode == 'ar'
                    ? 'لا توجد مشاريع. سجل النشاط غير متاح حاليًا.'
                    : 'No projects. Activity history is not currently available.')
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: projects.take(4).length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, i) =>
                        _ActivityCard(project: projects[i], theme: theme),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCards(BuildContext context,
      AsyncValue<List<DashboardFinanceMonth>> financeAsync) {
    return Column(
      children: [
        _buildFinancialSummary(context),
        const SizedBox(height: 16),
        _buildMonthlyChart(context, financeAsync),
      ],
    );
  }

  Widget _buildFinancialSummary(BuildContext context) {
    final locale = ref.watch(localeProvider);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ref.watch(dashboardSummaryProvider).when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Text(locale.languageCode == 'ar'
                ? 'تعذر قراءة البيانات المحلية'
                : 'Unable to read local data'),
            data: (summary) => LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth < 560
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(spacing: 12, runSpacing: 12, children: [
                  SizedBox(
                      width: width,
                      child: _FinancialCard(
                        title: context.tr('total_expenses'),
                        value: _formatYer(
                            summary.totalExpensesYer, locale.languageCode),
                        currency: 'YER',
                        trend: '',
                        trendUp: false,
                        icon: Icons.receipt_long,
                        color: const Color(0xFFEF4444),
                      )),
                  SizedBox(
                      width: width,
                      child: _FinancialCard(
                        title: context.tr('total_collected'),
                        value: _formatYer(
                            summary.totalPaymentsYer, locale.languageCode),
                        currency: 'YER',
                        trend: '',
                        trendUp: true,
                        icon: Icons.attach_money,
                        color: const Color(0xFF10B981),
                      )),
                  SizedBox(
                      width: width,
                      child: _FinancialCard(
                        title: locale.languageCode == 'ar'
                            ? 'صافي التدفق النقدي'
                            : 'Net cash flow',
                        value: _formatYer(
                            summary.netCashFlowYer, locale.languageCode),
                        currency: 'YER',
                        trend: '',
                        trendUp: summary.netCashFlowYer >= 0,
                        icon: Icons.account_balance_wallet,
                        color: summary.netCashFlowYer >= 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      )),
                ]);
              },
            ),
          ),
    );
  }

  Widget _buildMonthlyChart(BuildContext context,
      AsyncValue<List<DashboardFinanceMonth>> financeAsync) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale.languageCode == 'ar'
                    ? 'الأداء الشهري ٢٠٢٦'
                    : 'Monthly Performance 2026',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _buildLegendDot(const Color(0xFF3B82F6),
                      locale.languageCode == 'ar' ? 'إيرادات' : 'Revenue'),
                  _buildLegendDot(const Color(0xFFEF4444),
                      locale.languageCode == 'ar' ? 'مصروفات' : 'Expenses'),
                  _buildLegendDot(const Color(0xFF10B981),
                      locale.languageCode == 'ar' ? 'أرباح' : 'Profit'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          financeAsync.when(
            loading: () => const SizedBox(
                height: 200, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => SizedBox(
                height: 200,
                child: Center(
                    child: Text(locale.languageCode == 'ar'
                        ? 'خطأ في التحميل'
                        : 'Error loading'))),
            data: (finance) => SizedBox(
              height: 220,
              child: _InteractiveLineChart(months: finance),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);
    final actions = [
      _QuickActionData(
        title: context.tr('reports'),
        icon: Icons.bar_chart,
        color: const Color(0xFFF59E0B),
        onTap: () => context.go('/reports'),
      ),
      _QuickActionData(
        title: locale.languageCode == 'ar' ? 'دفعة' : 'Payment',
        icon: Icons.payment,
        color: const Color(0xFF10B981),
        onTap: () {},
      ),
      _QuickActionData(
        title: locale.languageCode == 'ar' ? 'مصروف' : 'Expense',
        icon: Icons.receipt_long,
        color: const Color(0xFFEF4444),
        onTap: () {},
      ),
      _QuickActionData(
        title: context.tr('new_project'),
        icon: Icons.add,
        color: const Color(0xFF3B82F6),
        onTap: () => context.go('/projects/new'),
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('quick_actions'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _QuickActionCard(action: actions[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;
  final bool trendUp;
  _KpiData(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color,
      required this.trend,
      required this.trendUp});
}

class _KpiCard extends StatelessWidget {
  final _KpiData kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: kpi.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(kpi.icon, color: kpi.color, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: kpi.trendUp
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      kpi.trendUp ? Icons.trending_up : Icons.trending_down,
                      color: kpi.trendUp
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B),
                      size: 10,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      kpi.trend,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: Color(0xFF166534)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            kpi.value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1E293B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            kpi.title,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final DashboardProjectOverview project;
  final ThemeData theme;
  const _ActivityCard({required this.project, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder, color: Colors.deepOrange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.projectName,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  project.clientName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'مكتمل',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF166534),
                  fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _FinancialCard extends StatelessWidget {
  final String title;
  final String value;
  final String currency;
  final String trend;
  final bool trendUp;
  final IconData icon;
  final Color color;

  const _FinancialCard({
    required this.title,
    required this.value,
    required this.currency,
    required this.trend,
    required this.trendUp,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendUp
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.trending_up : Icons.trending_down,
                      color: trendUp
                          ? const Color(0xFF166534)
                          : const Color(0xFF991B1B),
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      trend,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: Color(0xFF166534)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Color(0xFF1E293B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '$currency  $title',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _QuickActionData {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _QuickActionData(
      {required this.title,
      required this.icon,
      required this.color,
      required this.onTap});
}

class _QuickActionCard extends StatelessWidget {
  final _QuickActionData action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: action.color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              action.title,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.2, size.height * 0.65),
      Offset(size.width * 0.3, size.height * 0.5),
      Offset(size.width * 0.4, size.height * 0.55),
      Offset(size.width * 0.5, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.45),
      Offset(size.width * 0.7, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.35),
      Offset(size.width * 0.9, size.height * 0.2),
      Offset(size.width, size.height * 0.25),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);

    final fillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InteractiveLineChart extends StatefulWidget {
  final List<DashboardFinanceMonth> months;
  const _InteractiveLineChart({required this.months});

  @override
  State<_InteractiveLineChart> createState() => _InteractiveLineChartState();
}

class _InteractiveLineChartState extends State<_InteractiveLineChart> {
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    final maxVal = widget.months.fold<int>(1, (m, p) {
      final bigger = p.totalPaymentsYer > p.totalExpensesYer
          ? p.totalPaymentsYer
          : p.totalExpensesYer;
      return bigger > m ? bigger : m;
    });
    final maxDouble = maxVal.abs().toDouble();
    final chartMax = maxDouble == 0 ? 1.0 : maxDouble;

    return GestureDetector(
      onPanUpdate: (details) {
        final renderBox = context.findRenderObject() as RenderBox;
        final x = details.localPosition.dx;
        final barWidth = renderBox.size.width / (widget.months.length * 1.5);
        final index = ((x - barWidth * 0.25) / (barWidth * 1.5)).round();
        if (index >= 0 && index < widget.months.length) {
          setState(() => _hoveredIndex = index);
        }
      },
      onPanEnd: (_) => setState(() => _hoveredIndex = null),
      child: Stack(
        children: [
          CustomPaint(
            painter: _MultiLineChartPainter(
              months: widget.months,
              maxVal: chartMax,
              hoveredIndex: _hoveredIndex,
            ),
            size: Size.infinite,
          ),
          if (_hoveredIndex != null)
            _buildTooltip(widget.months[_hoveredIndex!]),
        ],
      ),
    );
  }

  Widget _buildTooltip(DashboardFinanceMonth point) {
    return Positioned(
      left: MediaQuery.of(context).size.width / 2 - 60,
      top: 20,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              point.canonicalKey,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            _buildTooltipRow(
                const Color(0xFF3B82F6), 'ايرادات', point.totalPaymentsYer),
            const SizedBox(height: 4),
            _buildTooltipRow(
                const Color(0xFFEF4444), 'مصروفات', point.totalExpensesYer),
            const SizedBox(height: 4),
            _buildTooltipRow(
                const Color(0xFF10B981), 'صافي التدفق', point.netCashFlowYer),
          ],
        ),
      ),
    );
  }

  Widget _buildTooltipRow(Color color, String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(width: 4),
        Text(
          NumberFormat.decimalPattern().format(value),
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Color(0xFF1E293B)),
        ),
      ],
    );
  }
}

class _MultiLineChartPainter extends CustomPainter {
  final List<DashboardFinanceMonth> months;
  final double maxVal;
  final int? hoveredIndex;

  _MultiLineChartPainter(
      {required this.months, required this.maxVal, this.hoveredIndex});

  @override
  void paint(Canvas canvas, Size size) {
    if (months.isEmpty) return;

    final barWidth = size.width / (months.length * 1.5);
    final baseHeight = size.height * 0.85;

    for (var i = 0; i < months.length; i++) {
      final m = months[i];
      final x = i * barWidth * 1.5 + barWidth * 0.25;
      final isHovered = i == hoveredIndex;

      final incomeH =
          (m.totalPaymentsYer.abs().toDouble() / maxVal) * baseHeight;
      final expenseH =
          (m.totalExpensesYer.abs().toDouble() / maxVal) * baseHeight;
      final profitH = incomeH - expenseH;

      final incomePaint = Paint()
        ..color = isHovered
            ? const Color(0xFF3B82F6)
            : const Color(0xFF3B82F6).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final expensePaint = Paint()
        ..color = isHovered
            ? const Color(0xFFEF4444)
            : const Color(0xFFEF4444).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      final profitPaint = Paint()
        ..color = isHovered
            ? const Color(0xFF10B981)
            : const Color(0xFF10B981).withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      if (incomeH > 0) {
        canvas.drawRect(
            Rect.fromLTWH(x, baseHeight - incomeH, barWidth * 0.4, incomeH),
            incomePaint);
      }
      if (expenseH > 0) {
        canvas.drawRect(
            Rect.fromLTWH(x + barWidth * 0.5, baseHeight - expenseH,
                barWidth * 0.4, expenseH),
            expensePaint);
      }
      if (profitH > 0) {
        canvas.drawRect(
            Rect.fromLTWH(
                x + barWidth, baseHeight - profitH, barWidth * 0.4, profitH),
            profitPaint);
      }

      if (isHovered) {
        final dotPaint = Paint()
          ..color = const Color(0xFF1E293B)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
            Offset(x + barWidth * 0.2, baseHeight - incomeH), 5, dotPaint);
        canvas.drawCircle(
            Offset(x + barWidth * 0.7, baseHeight - expenseH), 5, dotPaint);
        canvas.drawCircle(
            Offset(x + barWidth * 1.2, baseHeight - profitH), 5, dotPaint);
      }
    }

    final monthLabels = [
      'يناير',
      'فبراير',
      'مارس',
      'ابريل',
      'مايو',
      'يونيو',
      'يوليو',
      'اغسطس',
      'سبتمبر',
      'اكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    final textPainter = TextPainter(textDirection: ui.TextDirection.rtl);
    for (var i = 0; i < months.length && i < 12; i++) {
      final x = i * barWidth * 1.5 + barWidth * 0.75;
      textPainter.text = TextSpan(
        text: monthLabels[i % 12],
        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
      );
      textPainter.layout();
      textPainter.paint(
          canvas, Offset(x - textPainter.width / 2, baseHeight + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _MultiLineChartPainter old) =>
      old.months != months || old.hoveredIndex != hoveredIndex;
}
