import 'package:flutter_bloc/flutter_bloc.dart';
import 'admin_nav_state.dart';

class AdminNavCubit extends Cubit<AdminNavPage> {
  AdminNavCubit() : super(AdminNavPage.dashboard);

  void changePage(AdminNavPage page) {
    if (state != page) {
      emit(page);
    }
  }
}
