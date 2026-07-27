import 'package:flutter/material.dart';

export '../../features/settings/presentation/settings_provider.dart'
    show LocaleNotifier, localeProvider;

// Helper extension on BuildContext to quickly access translations
extension LocalizationContext on BuildContext {
  String tr(String key) {
    return AppLocalizations.of(this).translate(key);
  }

  bool get isRtl {
    return Directionality.of(this) == TextDirection.rtl;
  }
}

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppLocalizations(locale);
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General/Navbar
      'app_title': 'Construction ERP',
      'dashboard': 'Dashboard',
      'clients': 'Clients',
      'projects': 'Projects',
      'reports': 'Reports',
      'settings': 'Settings',
      'language': 'Language',
      'arabic': 'العربية',
      'english': 'English',
      'toggle_language': 'عربي',

      // Dashboard
      'welcome_engineer': 'Eng. Ahmed Al-Omari',
      'total_net_profit': 'Total Net Profit',
      'currency': 'SAR',
      'active': 'Active',
      'completed': 'Completed',
      'recent_activity': 'Recent Activity',
      'view_all': 'View All',
      'quick_actions': 'Quick Actions',
      'new_project': 'New Project',
      'new_client': 'New Client',
      'record_expense': 'Record Expense',
      'record_payment': 'Record Payment',
      'total_projects': 'Total Projects',
      'financial_cards_title': 'Financial Overview',

      // Clients Screen
      'search_clients': 'Search clients...',
      'add_client': 'Add Client',
      'edit_client': 'Edit Client',
      'client_details': 'Client Details',
      'client_name': 'Client Name',
      'phone': 'Phone Number',
      'company': 'Company Name',
      'save': 'Save',
      'cancel': 'Cancel',
      'no_clients': 'No clients found',
      'saving': 'Saving...',
      'delete_client': 'Delete Client',
      'confirm_delete_client': 'Are you sure you want to delete this client?',
      'delete': 'Delete',

      // Projects Screen
      'search_projects': 'Search projects...',
      'add_project': 'Add Project',
      'edit_project': 'Edit Project',
      'project_details': 'Project Details',
      'project_name': 'Project Name',
      'budget': 'Budget',
      'description': 'Description',
      'start_date': 'Start Date',
      'end_date': 'End Date',
      'select_client': 'Select Client',
      'status': 'Status',
      'no_projects': 'No projects found',
      'financials': 'Financials',
      'milestones': 'Milestones',
      'payments': 'Payments',
      'expenses': 'Expenses',
      'add_milestone': 'Add Milestone',
      'add_payment': 'Add Payment',
      'add_expense': 'Add Expense',
      'progress': 'Progress',
      'collected': 'Collected',
      'remaining': 'Remaining',

      // Milestones / Payments / Expenses Dialogs & Labels
      'title': 'Title',
      'amount': 'Amount',
      'date': 'Date',
      'due_date': 'Due Date',
      'status_completed': 'Completed',
      'status_pending': 'Pending',
      'notes': 'Notes',
      'category': 'Category',

      // Reports Screen
      'financial_summary': 'Financial Summary',
      'total_budget': 'Total Budget',
      'total_expenses': 'Total Expenses',
      'total_collected': 'Total Collected',
      'profitability_rate': 'Profitability Rate',
      'cash_flow_over_time': 'Cash Flow Over Time',
      'no_reports_data': 'No financial data available',
      'generate': 'Generate Report',
      'report_type': 'Report Type',
      'project_status_report': 'Project Status',
      'financial_report': 'Financial',
      'expense_report': 'Expenses',
      'all_projects': 'All Projects',
      'all_statuses': 'All Statuses',
      'filter_start': 'From',
      'filter_end': 'To',
      'report_hint': 'Choose a report type and filters, then tap Generate.',
      'income': 'Income',
      'net': 'Net',
      'grand_total': 'Grand Total',
      'by_category': 'By Category',
      'by_project': 'By Project',
      'export': 'Export',
      'no_data': 'No data for the selected filters.',
      'retry': 'Retry',
      'balance': 'Balance',
      'profit_margin': 'Profit Margin',
      'total_payments': 'Total Payments',
      'milestones_progress': 'Milestones',

      // Project Detail
      'project_detail': 'Project Detail',
      'profitability': 'Profitability',
      'tab_milestones': 'Milestones',
      'tab_payments': 'Payments',
      'tab_expenses': 'Expenses',
      'no_milestones': 'No milestones yet',
      'no_payments': 'No payments yet',
      'no_expenses': 'No expenses yet',
      'total': 'Total',
      'due': 'Due',
      'edit': 'Edit',
    },
    'ar': {
      // General/Navbar
      'app_title': 'نظام إدارة المشاريع',
      'dashboard': 'لوحة التحكم',
      'clients': 'العملاء',
      'projects': 'المشاريع',
      'reports': 'التقارير',
      'settings': 'الإعدادات',
      'language': 'اللغة',
      'arabic': 'العربية',
      'english': 'English',
      'toggle_language': 'English',

      // Dashboard
      'welcome_engineer': 'م. أحمد العمري',
      'total_net_profit': 'صافي الأرباح الإجمالية',
      'currency': 'ريال',
      'active': 'نشط',
      'completed': 'مكتمل',
      'recent_activity': 'آخر الأنشطة',
      'view_all': 'عرض الكل',
      'quick_actions': 'إجراءات سريعة',
      'new_project': 'مشروع جديد',
      'new_client': 'عميل جديد',
      'record_expense': 'تسجيل مصروف',
      'record_payment': 'تسجيل دفعة',
      'total_projects': 'إجمالي المشاريع',
      'financial_cards_title': 'الملخص المالي العام',

      // Clients Screen
      'search_clients': 'البحث عن العملاء...',
      'add_client': 'إضافة عميل',
      'edit_client': 'تعديل عميل',
      'client_details': 'تفاصيل العميل',
      'client_name': 'اسم العميل',
      'phone': 'رقم الهاتف',
      'company': 'اسم الشركة',
      'save': 'حفظ',
      'cancel': 'إلغاء',
      'no_clients': 'لم يتم العثور على عملاء',
      'saving': 'جاري الحفظ...',
      'delete_client': 'حذف العميل',
      'confirm_delete_client': 'هل أنت متأكد من رغبتك في حذف هذا العميل؟',
      'delete': 'حذف',

      // Projects Screen
      'search_projects': 'البحث عن المشاريع...',
      'add_project': 'إضافة مشروع',
      'edit_project': 'تعديل مشروع',
      'project_details': 'تفاصيل المشروع',
      'project_name': 'اسم المشروع',
      'budget': 'الميزانية',
      'description': 'الوصف',
      'start_date': 'تاريخ البدء',
      'end_date': 'تاريخ الانتهاء',
      'select_client': 'اختر العميل',
      'status': 'الحالة',
      'no_projects': 'لم يتم العثور على مشاريع',
      'financials': 'المالية',
      'milestones': 'المراحل والمحطات',
      'payments': 'المدفوعات والمقبوضات',
      'expenses': 'المصروفات',
      'add_milestone': 'إضافة مرحلة',
      'add_payment': 'إضافة دفعة مقبوضة',
      'add_expense': 'إضافة مصروف',
      'progress': 'نسبة الإنجاز',
      'collected': 'المحصل',
      'remaining': 'المتبقي',

      // Milestones / Payments / Expenses Dialogs & Labels
      'title': 'العنوان',
      'amount': 'المبلغ',
      'date': 'التاريخ',
      'due_date': 'تاريخ الاستحقاق',
      'status_completed': 'مكتمل',
      'status_pending': 'معلق',
      'notes': 'الملاحظات',
      'category': 'الفئة',

      // Reports Screen
      'financial_summary': 'الملخص المالي العام',
      'total_budget': 'إجمالي الميزانيات',
      'total_expenses': 'إجمالي المصروفات',
      'total_collected': 'إجمالي المقبوضات',
      'profitability_rate': 'معدل الربحية',
      'cash_flow_over_time': 'التدفقات النقدية مع الوقت',
      'no_reports_data': 'لا توجد بيانات مالية متاحة',
      'generate': 'إنشاء التقرير',
      'report_type': 'نوع التقرير',
      'project_status_report': 'حالة المشاريع',
      'financial_report': 'المالية',
      'expense_report': 'المصروفات',
      'all_projects': 'جميع المشاريع',
      'all_statuses': 'جميع الحالات',
      'filter_start': 'من',
      'filter_end': 'إلى',
      'report_hint': 'اختر نوع التقرير والفلاتر، ثم اضغط إنشاء.',
      'income': 'الدخل',
      'net': 'الصافي',
      'grand_total': 'الإجمالي الكلي',
      'by_category': 'حسب الفئة',
      'by_project': 'حسب المشروع',
      'export': 'تصدير',
      'no_data': 'لا توجد بيانات للفلاتر المختارة.',
      'retry': 'إعادة المحاولة',
      'balance': 'الرصيد',
      'profit_margin': 'هامش الربح',
      'total_payments': 'إجمالي المدفوعات',
      'milestones_progress': 'المراحل',

      // Project Detail
      'project_detail': 'تفاصيل المشروع',
      'profitability': 'الربحية',
      'tab_milestones': 'المراحل',
      'tab_payments': 'المدفوعات',
      'tab_expenses': 'المصروفات',
      'no_milestones': 'لا توجد مراحل بعد',
      'no_payments': 'لا توجد مدفوعات بعد',
      'no_expenses': 'لا توجد مصروفات بعد',
      'total': 'الإجمالي',
      'due': 'الاستحقاق',
      'edit': 'تعديل',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }
}
