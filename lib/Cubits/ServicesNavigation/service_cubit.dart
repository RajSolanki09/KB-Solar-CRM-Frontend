import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_project/Cubits/ServicesNavigation/service_state.dart';

class ServiceNavCubit extends Cubit<ServiceNavPage> {
  ServiceNavCubit() : super(ServiceNavPage.dashboard);

  void changePage(ServiceNavPage page) => emit(page);
}
