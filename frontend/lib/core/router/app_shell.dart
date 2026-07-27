import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/settings/presentation/settings_screen.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isMobile = MediaQuery.of(context).size.width < 600;

    int section;
    if (location.startsWith('/projects')) {
      section = 2;
    } else if (location.startsWith('/clients')) {
      section = 1;
    } else if (location.startsWith('/reports')) {
      section = 3;
    } else {
      section = 0;
    }

    final navItems = [
      _NavItem(
          icon: Icons.dashboard, label: context.tr('dashboard'), path: '/'),
      _NavItem(
          icon: Icons.people, label: context.tr('clients'), path: '/clients'),
      _NavItem(
          icon: Icons.folder, label: context.tr('projects'), path: '/projects'),
      _NavItem(
          icon: Icons.assessment,
          label: context.tr('reports'),
          path: '/reports'),
      _NavItem(
          icon: Icons.settings_outlined,
          label: context.tr('settings'),
          path: ''),
    ];

    if (isMobile) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: section,
          onDestinationSelected: (i) {
            if (i == navItems.length - 1) {
              _showSettings(context);
            } else {
              context.go(navItems[i].path);
            }
          },
          destinations: navItems
              .map((item) => NavigationDestination(
                    icon: Icon(item.icon, size: 24),
                    label: item.label,
                  ))
              .toList(),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            selectedIndex: section,
            onNavigate: (i) => context.go(navItems[i].path),
            onSettings: () => _showSettings(context),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String path;
  _NavItem({required this.icon, required this.label, required this.path});
}

class _Sidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onNavigate;
  final VoidCallback onSettings;

  const _Sidebar({
    required this.selectedIndex,
    required this.onNavigate,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(localeProvider);

    final navItems = [
      _NavItem(
          icon: Icons.dashboard, label: context.tr('dashboard'), path: '/'),
      _NavItem(
          icon: Icons.people, label: context.tr('clients'), path: '/clients'),
      _NavItem(
          icon: Icons.folder, label: context.tr('projects'), path: '/projects'),
      _NavItem(
          icon: Icons.assessment,
          label: context.tr('reports'),
          path: '/reports'),
    ];

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.construction,
                      color: AppTheme.primaryColor, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Construction ERP',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Management System',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          ...navItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = selectedIndex == index;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: InkWell(
                onTap: () => onNavigate(index),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.icon,
                        size: 22,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : theme.colorScheme.onSurface
                                .withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        item.label,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: onSettings,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.settings_outlined, size: 20),
                    const SizedBox(width: 12),
                    Text(context.tr('settings')),
                  ],
                ),
              ),
            ),
          ),
          // Language Switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: InkWell(
              onTap: () => ref.read(localeProvider.notifier).toggleLocale(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.language, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      locale.languageCode == 'en' ? 'العربية' : 'English',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storage_outlined,
                  size: 20,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    locale.languageCode == 'ar'
                        ? 'البيانات محفوظة على هذا الجهاز'
                        : 'Data is stored on this device',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

Future<void> _showSettings(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.92,
      child: SettingsScreen(),
    ),
  );
}
