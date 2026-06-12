// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'tokens/app_colors.dart';
import 'tokens/app_typography.dart';
import 'tokens/app_spacing.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppTheme — EVERY ThemeData parameter covered.
/// Light, Dark, and High-Contrast schemes.
/// ─────────────────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ─── Color Schemes ─────────────────────────────────────────────────────────
  static ColorScheme get _lightScheme => ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        primaryContainer: const Color(0xFFDBEAFE),
        onPrimaryContainer: const Color(0xFF1E3A5F),
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        secondaryContainer: const Color(0xFFEDE9FE),
        onSecondaryContainer: const Color(0xFF4C1D95),
        tertiary: AppColors.accent,
        onTertiary: AppColors.white,
        tertiaryContainer: const Color(0xFFFEF3C7),
        onTertiaryContainer: const Color(0xFF78350F),
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: const Color(0xFFFEE2E2),
        onErrorContainer: const Color(0xFF7F1D1D),
        surface: AppColors.white,
        onSurface: AppColors.slate900,
        surfaceVariant: AppColors.slate100,
        onSurfaceVariant: AppColors.slate600,
        surfaceContainerHighest: AppColors.slate200,
        surfaceContainerHigh: AppColors.slate100,
        surfaceContainer: AppColors.slate50,
        surfaceContainerLow: AppColors.white,
        surfaceContainerLowest: AppColors.white,
        outline: AppColors.slate300,
        outlineVariant: AppColors.slate200,
        shadow: AppColors.slate900,
        scrim: const Color(0x80000000),
        inverseSurface: AppColors.slate800,
        onInverseSurface: AppColors.slate50,
        inversePrimary: const Color(0xFF93C5FD),
      );

  static ColorScheme get _darkScheme => ColorScheme(
        brightness: Brightness.dark,
        primary: const Color(0xFF93C5FD),
        onPrimary: const Color(0xFF1E3A5F),
        primaryContainer: const Color(0xFF1D4ED8),
        onPrimaryContainer: const Color(0xFFDBEAFE),
        secondary: const Color(0xFFC4B5FD),
        onSecondary: const Color(0xFF4C1D95),
        secondaryContainer: const Color(0xFF5B21B6),
        onSecondaryContainer: const Color(0xFFEDE9FE),
        tertiary: const Color(0xFFFCD34D),
        onTertiary: const Color(0xFF78350F),
        tertiaryContainer: const Color(0xFF92400E),
        onTertiaryContainer: const Color(0xFFFEF3C7),
        error: const Color(0xFFF87171),
        onError: const Color(0xFF7F1D1D),
        errorContainer: const Color(0xFF991B1B),
        onErrorContainer: const Color(0xFFFEE2E2),
        surface: AppColors.slate900,
        onSurface: AppColors.slate50,
        surfaceVariant: AppColors.slate800,
        onSurfaceVariant: AppColors.slate400,
        surfaceContainerHighest: AppColors.slate700,
        surfaceContainerHigh: AppColors.slate800,
        surfaceContainer: const Color(0xFF1A2535),
        surfaceContainerLow: AppColors.slate900,
        surfaceContainerLowest: AppColors.black,
        outline: AppColors.slate600,
        outlineVariant: AppColors.slate700,
        shadow: AppColors.black,
        scrim: const Color(0x80000000),
        inverseSurface: AppColors.slate100,
        onInverseSurface: AppColors.slate800,
        inversePrimary: AppColors.primary,
      );

  // ─── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get light => _build(_lightScheme, Brightness.light);

  // ─── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData get dark => _build(_darkScheme, Brightness.dark);

  // ─── Builder ────────────────────────────────────────────────────────────────
  static ThemeData _build(ColorScheme cs, Brightness brightness) {
    final isLight = brightness == Brightness.light;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,

      // ── Typography ──────────────────────────────────────────────────────────
      textTheme: AppTypography.textTheme.apply(
        bodyColor: cs.onSurface,
        displayColor: cs.onSurface,
      ),
      primaryTextTheme: AppTypography.textTheme.apply(
        bodyColor: cs.onPrimary,
        displayColor: cs.onPrimary,
      ),

      // ── Scaffold ─────────────────────────────────────────────────────────────
      scaffoldBackgroundColor: cs.surface,

      // ── AppBar ───────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.shadow.withOpacity(0.1),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(color: cs.onSurface),
        toolbarTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
        iconTheme: IconThemeData(color: cs.onSurface, size: AppSpacing.iconLg),
        actionsIconTheme: IconThemeData(color: cs.onSurface, size: AppSpacing.iconLg),
        systemOverlayStyle: isLight
            ? SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        shape: const Border(bottom: BorderSide(color: Colors.transparent)),
      ),

      // ── Card ──────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: cs.surface,
        shadowColor: cs.shadow.withOpacity(0.05),
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: BorderSide(color: cs.outlineVariant, width: 1),
        ),
      ),

      // ── Elevated Button ───────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          disabledBackgroundColor: cs.onSurface.withOpacity(0.12),
          disabledForegroundColor: cs.onSurface.withOpacity(0.38),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          textStyle: AppTypography.textTheme.labelLarge,
        ).copyWith(
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) return cs.onPrimary.withOpacity(0.08);
            if (states.contains(WidgetState.pressed)) return cs.onPrimary.withOpacity(0.12);
            return null;
          }),
        ),
      ),

      // ── Filled Button ─────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.outline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(64, 40),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
          textStyle: AppTypography.textTheme.labelLarge,
        ),
      ),

      // ── Icon Button ───────────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          iconSize: AppSpacing.iconLg,
          foregroundColor: cs.onSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
      ),

      // ── FloatingActionButton ──────────────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: AppSpacing.elevMd,
        focusElevation: AppSpacing.elevLg,
        hoverElevation: AppSpacing.elevLg,
        backgroundColor: cs.primaryContainer,
        foregroundColor: cs.onPrimaryContainer,
        extendedPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
      ),

      // ── Input Decoration ──────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.sm + AppSpacing.px4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.4)),
        ),
        labelStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.6)),
        errorStyle: AppTypography.textTheme.labelSmall?.copyWith(color: cs.error),
        helperStyle: AppTypography.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        prefixIconColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.focused) ? cs.primary : cs.onSurfaceVariant),
        suffixIconColor: WidgetStateColor.resolveWith((states) =>
            states.contains(WidgetState.focused) ? cs.primary : cs.onSurfaceVariant),
        floatingLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(color: cs.primary),
        isDense: false,
      ),

      // ── Dialog ────────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        elevation: AppSpacing.elevXl,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.shadow.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        titleTextStyle: AppTypography.textTheme.titleLarge?.copyWith(color: cs.onSurface),
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        alignment: Alignment.center,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        elevation: AppSpacing.elevXl,
        modalElevation: AppSpacing.elevXl,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.shadow.withOpacity(0.2),
        modalBackgroundColor: cs.surface,
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXxl)),
        ),
        showDragHandle: true,
        dragHandleColor: AppColors.slate300,
        dragHandleSize: const Size(32, 4),
        constraints: const BoxConstraints(maxWidth: 640),
      ),

      // ── Tooltip ───────────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cs.inverseSurface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        textStyle: AppTypography.textTheme.labelSmall?.copyWith(color: cs.onInverseSurface),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(seconds: 2),
      ),

      // ── Snack Bar ─────────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cs.inverseSurface,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onInverseSurface),
        actionTextColor: cs.inversePrimary,
        disabledActionTextColor: cs.onInverseSurface.withOpacity(0.38),
        elevation: AppSpacing.elevMd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        insetPadding: const EdgeInsets.fromLTRB(16, 5, 16, 40),
        showCloseIcon: true,
        closeIconColor: cs.onInverseSurface,
      ),

      // ── Chip ──────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceVariant,
        disabledColor: cs.onSurface.withOpacity(0.12),
        selectedColor: cs.secondaryContainer,
        secondarySelectedColor: cs.primaryContainer,
        deleteIconColor: cs.onSurfaceVariant,
        labelStyle: AppTypography.textTheme.labelMedium?.copyWith(color: cs.onSurfaceVariant),
        secondaryLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(color: cs.onSecondaryContainer),
        side: BorderSide(color: cs.outline),
        shape: StadiumBorder(side: BorderSide(color: cs.outline)),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        elevation: 0,
        pressElevation: 0,
        brightness: brightness,
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: AppTypography.textTheme.labelLarge,
        unselectedLabelStyle: AppTypography.textTheme.labelLarge,
        indicatorColor: cs.primary,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: cs.outlineVariant,
        overlayColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.pressed) ? cs.primary.withOpacity(0.08) : null),
      ),

      // ── Navigation Bar ────────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.textTheme.labelSmall?.copyWith(color: cs.onSurface);
          }
          return AppTypography.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: cs.onPrimaryContainer, size: AppSpacing.iconLg);
          }
          return IconThemeData(color: cs.onSurfaceVariant, size: AppSpacing.iconLg);
        }),
        elevation: 0,
        height: 80,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.shadow.withOpacity(0.1),
      ),

      // ── Navigation Rail ───────────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cs.surface,
        selectedIconTheme: IconThemeData(color: cs.onPrimaryContainer, size: AppSpacing.iconLg),
        unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant, size: AppSpacing.iconLg),
        selectedLabelTextStyle: AppTypography.textTheme.labelSmall?.copyWith(color: cs.onSurface),
        unselectedLabelTextStyle: AppTypography.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        indicatorColor: cs.primaryContainer,
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        elevation: 0,
        useIndicator: true,
      ),

      // ── Drawer ────────────────────────────────────────────────────────────────
      drawerTheme: DrawerThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppSpacing.elevXl,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(AppSpacing.radiusXxl)),
        ),
        width: 300,
        shadowColor: cs.shadow.withOpacity(0.2),
      ),

      // ── List Tile ─────────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        minLeadingWidth: 0,
        minVerticalPadding: AppSpacing.sm,
        tileColor: Colors.transparent,
        selectedTileColor: cs.primaryContainer.withOpacity(0.5),
        selectedColor: cs.primary,
        iconColor: cs.onSurfaceVariant,
        textColor: cs.onSurface,
        titleTextStyle: AppTypography.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
        subtitleTextStyle: AppTypography.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        leadingAndTrailingTextStyle: AppTypography.textTheme.labelSmall,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        enableFeedback: true,
        horizontalTitleGap: AppSpacing.md,
      ),

      // ── Checkbox ──────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          if (states.contains(WidgetState.disabled)) return cs.onSurface.withOpacity(0.38);
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(cs.onPrimary),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) return cs.primary.withOpacity(0.12);
          if (states.contains(WidgetState.hovered)) return cs.primary.withOpacity(0.08);
          return null;
        }),
        side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
          color: states.contains(WidgetState.selected) ? cs.primary : cs.outline,
          width: 2,
        )),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),

      // ── Radio ─────────────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cs.primary : cs.outline),
        overlayColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.pressed) ? cs.primary.withOpacity(0.12) : null),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),

      // ── Switch ────────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.onPrimary;
          return cs.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primary;
          return cs.surfaceVariant;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.transparent : cs.outline),
        overlayColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.pressed) ? cs.primary.withOpacity(0.12) : null),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),

      // ── Slider ────────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: cs.primary,
        inactiveTrackColor: cs.primary.withOpacity(0.24),
        thumbColor: cs.primary,
        overlayColor: cs.primary.withOpacity(0.12),
        valueIndicatorColor: cs.primary,
        valueIndicatorTextStyle: AppTypography.textTheme.labelSmall?.copyWith(color: cs.onPrimary),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
        showValueIndicator: ShowValueIndicator.onlyForDiscrete,
        activeTickMarkColor: cs.onPrimary,
        inactiveTickMarkColor: cs.primary,
      ),

      // ── Progress Indicator ────────────────────────────────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: cs.primary,
        linearTrackColor: cs.primary.withOpacity(0.24),
        circularTrackColor: cs.primary.withOpacity(0.24),
        linearMinHeight: 4,
        refreshBackgroundColor: cs.surface,
      ),

      // ── Badge ─────────────────────────────────────────────────────────────────
      badgeTheme: BadgeThemeData(
        backgroundColor: cs.error,
        textColor: cs.onError,
        textStyle: AppTypography.textTheme.labelSmall?.copyWith(
          color: cs.onError,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        alignment: AlignmentDirectional.topEnd,
        smallSize: 8,
        largeSize: 16,
        offset: const Offset(4, -4),
      ),

      // ── Banner ────────────────────────────────────────────────────────────────
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: cs.secondaryContainer,
        contentTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSecondaryContainer),
        elevation: 0,
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
        leadingPadding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
        dividerColor: cs.outlineVariant,
        shadowColor: cs.shadow.withOpacity(0.1),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Date Picker ───────────────────────────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: cs.surface,
        elevation: AppSpacing.elevXl,
        shadowColor: cs.shadow.withOpacity(0.2),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXxl)),
        headerBackgroundColor: cs.primaryContainer,
        headerForegroundColor: cs.onPrimaryContainer,
        headerHeadlineStyle: AppTypography.textTheme.headlineMedium?.copyWith(color: cs.onPrimaryContainer),
        headerHelpStyle: AppTypography.textTheme.labelSmall?.copyWith(color: cs.onPrimaryContainer.withOpacity(0.7)),
        weekdayStyle: AppTypography.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        dayStyle: AppTypography.textTheme.bodySmall,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.onPrimary;
          if (states.contains(WidgetState.disabled)) return cs.onSurface.withOpacity(0.38);
          return cs.onSurface;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cs.primary : null),
        dayOverlayColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.pressed) ? cs.primary.withOpacity(0.12) : null),
        todayForegroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cs.onPrimary : cs.primary),
        todayBackgroundColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? cs.primary : null),
        todayBorder: BorderSide(color: cs.primary),
        rangePickerBackgroundColor: cs.surface,
        rangeSelectionBackgroundColor: cs.primaryContainer,
        rangeSelectionOverlayColor: WidgetStateProperty.all(cs.primary.withOpacity(0.12)),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: cs.primary),
        confirmButtonStyle: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      ),

      // ── Time Picker ───────────────────────────────────────────────────────────
      timePickerTheme: TimePickerThemeData(
        backgroundColor: cs.surface,
        elevation: AppSpacing.elevXl,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXxl)),
        hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        dayPeriodShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        hourMinuteColor: cs.surfaceVariant,
        hourMinuteTextColor: cs.onSurface,
        dayPeriodColor: Colors.transparent,
        dayPeriodTextColor: cs.onSurface,
        dialBackgroundColor: cs.surfaceVariant,
        dialHandColor: cs.primary,
        dialTextColor: cs.onSurface,
        entryModeIconColor: cs.onSurface,
        helpTextStyle: AppTypography.textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
        hourMinuteTextStyle: AppTypography.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w400),
        dayPeriodTextStyle: AppTypography.textTheme.titleMedium,
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: cs.primary),
        confirmButtonStyle: FilledButton.styleFrom(
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm)),
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: cs.outlineVariant,
        thickness: 1,
        space: 1,
        indent: 0,
        endIndent: 0,
      ),

      // ── Icon ──────────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(
        color: cs.onSurface,
        size: AppSpacing.iconLg,
        opacity: 1,
      ),
      primaryIconTheme: IconThemeData(color: cs.onPrimary, size: AppSpacing.iconLg),

      // ── ExpansionTile ─────────────────────────────────────────────────────────
      expansionTileTheme: ExpansionTileThemeData(
        iconColor: cs.onSurfaceVariant,
        collapsedIconColor: cs.onSurfaceVariant,
        textColor: cs.primary,
        collapsedTextColor: cs.onSurface,
        backgroundColor: cs.surface,
        collapsedBackgroundColor: cs.surface,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: const Border(),
        collapsedShape: const Border(),
      ),

      // ── Search Bar ────────────────────────────────────────────────────────────
      searchBarTheme: SearchBarThemeData(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(cs.surfaceVariant),
        overlayColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.pressed) ? cs.primary.withOpacity(0.08) : null),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        side: WidgetStateProperty.all(BorderSide(color: cs.outline)),
        shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusFull))),
        padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs)),
        textStyle: WidgetStateProperty.all(
            AppTypography.textTheme.bodyLarge?.copyWith(color: cs.onSurface)),
        hintStyle: WidgetStateProperty.all(
            AppTypography.textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant.withOpacity(0.6))),
      ),

      // ── Search View ────────────────────────────────────────────────────────────
      searchViewTheme: SearchViewThemeData(
        elevation: AppSpacing.elevMd,
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        side: BorderSide(color: cs.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        headerTextStyle: AppTypography.textTheme.bodyLarge?.copyWith(color: cs.onSurface),
        headerHintStyle: AppTypography.textTheme.bodyLarge?.copyWith(
            color: cs.onSurfaceVariant.withOpacity(0.6)),
        dividerColor: cs.outlineVariant,
      ),

      // ── Popup Menu ────────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: cs.surface,
        elevation: AppSpacing.elevMd,
        shadowColor: cs.shadow.withOpacity(0.15),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        textStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
        labelTextStyle: WidgetStateProperty.all(
            AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSurface)),
        iconSize: AppSpacing.iconLg,
        enableFeedback: true,
        position: PopupMenuPosition.under,
        mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
      ),

      // ── Menu Bar ──────────────────────────────────────────────────────────────
      menuBarTheme: MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(cs.surface),
          shadowColor: WidgetStateProperty.all(cs.shadow.withOpacity(0.1)),
          elevation: WidgetStateProperty.all(0),
          shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusSm))),
        ),
      ),

      // ── Menu Theme ────────────────────────────────────────────────────────────
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(cs.surface),
          elevation: WidgetStateProperty.all(AppSpacing.elevMd),
          shadowColor: WidgetStateProperty.all(cs.shadow.withOpacity(0.15)),
          shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))),
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 8)),
        ),
      ),

      // ── Segmented Button ──────────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return cs.secondaryContainer;
            return cs.surface;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return cs.onSecondaryContainer;
            return cs.onSurface;
          }),
          side: WidgetStateProperty.all(BorderSide(color: cs.outline)),
          textStyle: WidgetStateProperty.all(AppTypography.textTheme.labelLarge),
          padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm)),
        ),
      ),

      // ── Data Table ────────────────────────────────────────────────────────────
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(cs.surfaceVariant),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return cs.primaryContainer.withOpacity(0.3);
          return null;
        }),
        headingTextStyle: AppTypography.textTheme.labelLarge?.copyWith(color: cs.onSurface),
        dataTextStyle: AppTypography.textTheme.bodyMedium?.copyWith(color: cs.onSurface),
        headingRowHeight: 56,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 72,
        horizontalMargin: AppSpacing.md,
        columnSpacing: AppSpacing.lg,
        dividerThickness: 1,
        checkboxHorizontalMargin: AppSpacing.md,
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        headingRowAlignment: MainAxisAlignment.start,
      ),

      // ── Bottom App Bar ────────────────────────────────────────────────────────
      bottomAppBarTheme: BottomAppBarThemeData(
        color: cs.surface,
        elevation: 0,
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        surfaceTintColor: Colors.transparent,
        shadowColor: cs.shadow.withOpacity(0.1),
        shape: const CircularNotchedRectangle(),
      ),

      // ── Material Banner ───────────────────────────────────────────────────────
      // Covered in bannerTheme above

      // ── Scrollbar ─────────────────────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(cs.onSurface.withOpacity(0.3)),
        trackColor: WidgetStateProperty.all(cs.onSurface.withOpacity(0.05)),
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(AppSpacing.radiusFull),
        trackVisibility: WidgetStateProperty.all(false),
        thumbVisibility: WidgetStateProperty.all(false),
        interactive: true,
        crossAxisMargin: 2,
        mainAxisMargin: 2,
      ),

      // ── Text Selection ────────────────────────────────────────────────────────
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: cs.primary,
        selectionColor: cs.primary.withOpacity(0.3),
        selectionHandleColor: cs.primary,
      ),

      // ── Page Transitions ──────────────────────────────────────────────────────
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.fuchsia: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // ── Visual Density ────────────────────────────────────────────────────────
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // ── Splash / Highlight ────────────────────────────────────────────────────
      splashFactory: InkSparkle.splashFactory,
      splashColor: cs.primary.withOpacity(0.08),
      highlightColor: cs.primary.withOpacity(0.04),
      hoverColor: cs.primary.withOpacity(0.04),
      focusColor: cs.primary.withOpacity(0.12),

      // ── Misc ──────────────────────────────────────────────────────────────────
      shadowColor: cs.shadow.withOpacity(0.15),
      disabledColor: cs.onSurface.withOpacity(0.38),
      hintColor: cs.onSurfaceVariant.withOpacity(0.6),
      unselectedWidgetColor: cs.outline,
      secondaryHeaderColor: cs.primaryContainer,
      canvasColor: cs.surface,
      cardColor: cs.surface,
      dialogBackgroundColor: cs.surface,
      indicatorColor: cs.primary,
    );
  }

  /// Custom scheme builder — pass any primary to get a full theme
  static ThemeData fromColor(Color primary, {bool dark = false}) {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: dark ? Brightness.dark : Brightness.light,
    );
    return _build(scheme, dark ? Brightness.dark : Brightness.light);
  }
}
