import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF0B5EA8);
  static const primaryDark = Color(0xFF07477F);
  static const primarySoft = Color(0xFFE6F1FA);
  static const secondary = Color(0xFF00A884);
  static const secondarySoft = Color(0xFFE2F7F2);

  static const background = Color(0xFFF7F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF0F4F8);
  static const border = Color(0xFFDDE4EC);
  static const divider = Color(0xFFE8EDF3);

  static const textPrimary = Color(0xFF152536);
  static const textSecondary = Color(0xFF53677B);
  static const textMuted = Color(0xFF7B8C9D);
  static const onPrimary = Color(0xFFFFFFFF);

  static const success = Color(0xFF18864B);
  static const successSoft = Color(0xFFE5F5EC);
  static const warning = Color(0xFFE09800);
  static const warningSoft = Color(0xFFFFF4D6);
  static const error = Color(0xFFC53B3B);
  static const errorSoft = Color(0xFFFCE8E8);
  static const info = Color(0xFF2176C7);
  static const infoSoft = Color(0xFFE7F1FB);

  static const vendor = Color(0xFF246BCE);
  static const garbage = Color(0xFF238B57);
  static const water = Color(0xFF078EB8);
  static const roads = Color(0xFFE07C16);
  static const animals = Color(0xFF8056C7);
  static const drainage = Color(0xFF3E4DB4);
  static const streetlights = Color(0xFFD59800);
  static const publicSpaces = Color(0xFF00897B);
  static const encroachment = Color(0xFFD5534C);
  static const other = Color(0xFF64748B);
}

abstract final class AppSpacing {
  static const double none = 0;
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
  static const double huge = 48;
  static const double page = 20;
  static const double section = 28;
  static const double minTouchTarget = 48;
}

abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 18;
  static const double xl = 24;
  static const double pill = 999;
}

abstract final class AppShadows {
  static const card = <BoxShadow>[
    BoxShadow(color: Color(0x0F0D263F), blurRadius: 18, offset: Offset(0, 5)),
  ];

  static const raised = <BoxShadow>[
    BoxShadow(color: Color(0x1A0D263F), blurRadius: 24, offset: Offset(0, 9)),
  ];
}

abstract final class AppTypography {
  static const fontFamily = 'Roboto';

  static const display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.7,
  );

  static const headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.35,
  );

  static const titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.35,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );
}

abstract final class AppIcons {
  static const home = Icons.home_rounded;
  static const services = Icons.grid_view_rounded;
  static const requests = Icons.assignment_rounded;
  static const notifications = Icons.notifications_rounded;
  static const profile = Icons.person_rounded;
  static const location = Icons.location_on_rounded;
  static const camera = Icons.photo_camera_rounded;
  static const gallery = Icons.photo_library_rounded;
  static const document = Icons.description_rounded;
  static const search = Icons.search_rounded;
}
