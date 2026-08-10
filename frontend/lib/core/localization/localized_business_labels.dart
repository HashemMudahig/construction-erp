import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

String localizedExpenseCategory(BuildContext context, String value) =>
    context.tr('expense_category_$value');

String localizedPaymentMethod(BuildContext context, String value) =>
    context.tr('payment_method_$value');

String localizedMilestoneStatus(BuildContext context, String value) =>
    context.tr('milestone_status_$value');
