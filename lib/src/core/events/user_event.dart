sealed class UserEvent {}

class UserJumpToPage extends UserEvent {
  final int page;
  UserJumpToPage(this.page);
}

class UserZoom extends UserEvent {
  final double zoom;
  UserZoom(this.zoom);
}
