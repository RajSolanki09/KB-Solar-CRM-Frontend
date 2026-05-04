enum AdminNavPage { dashboard, leads, service, reports, profile }

class AdminNavState {
  final AdminNavPage currentPage;

  const AdminNavState({required this.currentPage});

  AdminNavState copyWith({AdminNavPage? currentPage}) {
    return AdminNavState(currentPage: currentPage ?? this.currentPage);
  }
}
