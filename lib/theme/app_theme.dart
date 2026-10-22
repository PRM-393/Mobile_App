import 'package:flutter/material.dart';

// Bang mau dung chung cho toan ung dung (design system "Voucher Teal")
class AppColors {
  AppColors._();

  static const primary = Color(0xFF087F6B);
  static const primaryDark = Color(0xFF045D50);
  static const primarySoft = Color(0xFFE5F4EF);
  static const secondary = Color(0xFFFFB547);
  static const secondarySoft = Color(0xFFFFF3DF);
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFE6F6EC);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFDECEC);
  static const background = Color(0xFFF4F7F5);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFDDE7E3);
  static const textPrimary = Color(0xFF12221E);
  static const textSecondary = Color(0xFF60736D);
}

class AppSpacing {
  AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

// Ban kinh bo goc theo design system: card 20, control 16, pill 999
class AppRadius {
  AppRadius._();

  static const control = 16.0;
  static const card = 20.0;
  static const lgSheet = 28.0;
  static const pill = 999.0;
}

// Gradient dung cho the tong quan (vi voucher, header ca nhan)
const appHeaderGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.primary, AppColors.primaryDark],
);

// Shadow rat nhe cho card noi tren nen #F4F7F5
const appCardShadow = [
  BoxShadow(
    color: Color(0x14102A24),
    blurRadius: 18,
    offset: Offset(0, 6),
  ),
];

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.danger,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );
  return base.copyWith(
    textTheme: base.textTheme
        .apply(
          bodyColor: AppColors.textPrimary,
          displayColor: AppColors.textPrimary,
        )
        .copyWith(
          headlineSmall: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          // Phai co mau: bodyMedium la kieu chu mac dinh cua moi Text, thieu mau thi chu bi trang tren nen trang
          bodyMedium: const TextStyle(fontSize: 14, height: 1.45, color: AppColors.textPrimary),
          bodySmall: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: const CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        side: BorderSide(color: AppColors.border),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: TextStyle(color: AppColors.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        borderSide: BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        borderSide: BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        borderSide: BorderSide(color: AppColors.danger, width: 1.6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        borderSide: BorderSide.none,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: AppColors.primaryDark,
        side: const BorderSide(color: AppColors.border),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: AppColors.primaryDark,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.primaryDark,
      textColor: AppColors.textPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.textSecondary,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.border,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : AppColors.textSecondary,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.primary
            : Colors.transparent,
      ),
      side: const BorderSide(color: AppColors.textSecondary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.control)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.lgSheet),
        ),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
      ),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.primarySoft,
      elevation: 8,
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
      ),
      iconTheme: WidgetStatePropertyAll(IconThemeData(size: 24)),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      selectedColor: AppColors.primarySoft,
      checkmarkColor: AppColors.primaryDark,
      // Mau chu ro rang ca khi chua chon (mac dinh bi trang tren nen sang)
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      secondaryLabelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
      ),
    ),
  );
}
