import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../../core/constants/app_colors.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark =
        theme.mode == ThemeMode.dark ||
        (theme.mode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';

    return IconButton(
      icon: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
        color: AppColors.primary,
      ),
      tooltip: isAr ? 'تغيير الوضع' : 'Toggle theme',
      onPressed: () => theme.setMode(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}
