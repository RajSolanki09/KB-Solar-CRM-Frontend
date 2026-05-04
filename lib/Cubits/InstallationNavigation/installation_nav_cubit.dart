// lib/Cubits/InstallationNavigation/installation_nav_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'installation_nav_state.dart';

class InstallationNavCubit extends Cubit<InstallationNavPage> {
  InstallationNavCubit() : super(InstallationNavPage.dashboard);

  String? _myInstallationsProjectType;

  String? get myInstallationsProjectType => _myInstallationsProjectType;

  void openMyInstallations({String? projectType}) {
    _myInstallationsProjectType = projectType?.toLowerCase();
    emit(InstallationNavPage.myInstallations);
  }

  void clearMyInstallationsFilter() {
    _myInstallationsProjectType = null;
  }

  void changePage(InstallationNavPage page) {
    if (page != InstallationNavPage.myInstallations) {
      _myInstallationsProjectType = null;
    }
    emit(page);
  }
}
