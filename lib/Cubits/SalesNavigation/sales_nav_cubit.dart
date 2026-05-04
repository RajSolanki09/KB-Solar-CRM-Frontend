import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/SalesNavigation/sales_nav_state.dart';



class SalesNavCubit extends Cubit<SalesNavPage> {
  SalesNavCubit() : super(SalesNavPage.dashboard);

  void changePage(SalesNavPage page) => emit(page);
}
