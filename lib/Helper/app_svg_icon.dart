import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgAssets {
  static const String _root = 'assets/svg';

  // — Original icons —
  static const String dashboard = '$_root/layout-dashboard.svg';
  static const String sun = '$_root/sun.svg';
  static const String cog = '$_root/cog.svg';
  static const String chartNoAxisCombined = '$_root/chart-no-axes-combined.svg';
  static const String userRound = '$_root/user-round.svg';
  static const String userRoundCog = '$_root/user-round-cog.svg';
  static const String users = '$_root/users.svg';
  static const String logOut = '$_root/log-out.svg';
  static const String history = '$_root/history.svg';
  static const String calendarDays = '$_root/calendar-days.svg';
  static const String handshake = '$_root/handshake.svg';
  static const String circleCheckBig = '$_root/circle-check-big.svg';
  static const String triangleAlert = '$_root/triangle-alert.svg';
  static const String search = '$_root/search.svg';
  static const String x = '$_root/x.svg';
  static const String droplet = '$_root/droplet.svg';
  static const String hammer = '$_root/hammer.svg';
  static const String clipboardList = '$_root/clipboard-list.svg';
  static const String refreshCw = '$_root/refresh-cw.svg';
  static const String indianRupee = '$_root/indian-rupee.svg';

  // — Navigation / UI —
  static const String chevronLeft = '$_root/chevron-left.svg';
  static const String chevronRight = '$_root/chevron-right.svg';
  static const String chevronDown = '$_root/chevron-down.svg';
  static const String chevronUp = '$_root/chevron-up.svg';
  static const String check = '$_root/check.svg';
  static const String arrowRight = '$_root/arrow-right.svg';
  static const String plus = '$_root/plus.svg';
  static const String filter = '$_root/filter.svg';

  // — Contact / Profile —
  static const String phone = '$_root/phone.svg';
  static const String mapPin = '$_root/map-pin.svg';
  static const String mail = '$_root/mail.svg';
  static const String lock = '$_root/lock.svg';
  static const String eye = '$_root/eye.svg';
  static const String eyeOff = '$_root/eye-off.svg';
  static const String shield = '$_root/shield.svg';
  static const String idCard = '$_root/id-card.svg';
  static const String userPlus = '$_root/user-plus.svg';
  static const String building2 = '$_root/building-2.svg';
  static const String trendingUp = '$_root/trending-up.svg';
  static const String trash2 = '$_root/trash-2.svg';
  static const String keyRound = '$_root/key-round.svg';
  static const String pencil = '$_root/pencil.svg';

  // — Status / Installation —
  static const String circle = '$_root/circle.svg';
  static const String zap = '$_root/zap.svg';
  static const String trophy = '$_root/trophy.svg';
  static const String gauge = '$_root/gauge.svg';
  static const String flaskConical = '$_root/flask-conical.svg';

  // — Camera / Photo —
  static const String camera = '$_root/camera.svg';
  static const String images = '$_root/images.svg';
  static const String imagePlus = '$_root/image-plus.svg';
  static const String imageOff = '$_root/image-off.svg';

  // — Misc —
  static const String fileText = '$_root/file-text.svg';
  static const String play = '$_root/play.svg';
  static const String clock = '$_root/clock.svg';
  static const String messageSquarePlus = '$_root/message-square-plus.svg';
  static const String calendarCheck = '$_root/calendar-check.svg';
  static const String wifiOff = '$_root/wifi-off.svg';
  static const String home = '$_root/home.svg';
  static const String megaphone = '$_root/megaphone.svg';
  static const String leaf = '$_root/leaf.svg';
  static const String maximize = '$_root/maximize.svg';
  static const String calendarX = '$_root/calendar-x.svg';
  static const String thermometer = '$_root/thermometer.svg';
  static const String sunMedium = '$_root/sun-medium.svg';
  static const String activity = '$_root/activity.svg';
  static const String circleQuestionMark = '$_root/circle-question-mark.svg';
  static const String packagePlus = '$_root/package-plus.svg';
  static const String download = '$_root/download.svg';
  static const String layoutList = '$_root/layout-list.svg';

}

class AppSvgIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Color? color;
  final BoxFit fit;

  const AppSvgIcon(
    this.assetPath, {
    super.key,
    this.size = 18,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}
