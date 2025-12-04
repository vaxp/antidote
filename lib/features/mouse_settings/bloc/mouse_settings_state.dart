import 'package:equatable/equatable.dart';

/// Status of mouse settings
enum MouseSettingsStatus { initial, loading, loaded, error }

/// State class for mouse settings
class MouseSettingsState extends Equatable {
  final MouseSettingsStatus status;
  final int selectedTab; // 0 = Mouse, 1 = Touchpad

  // Mouse settings
  final String primaryButton; // 'left' or 'right'
  final double mousePointerSpeed;
  final bool mouseAcceleration;
  final String scrollDirection; // 'traditional' or 'natural'

  // Touchpad settings
  final bool touchpadEnabled;
  final bool disableWhileTyping;
  final double touchpadPointerSpeed;
  final String secondaryClick; // 'two-finger' or 'corner'
  final bool tapToClick;

  final String? errorMessage;

  const MouseSettingsState({
    this.status = MouseSettingsStatus.initial,
    this.selectedTab = 0,
    this.primaryButton = 'left',
    this.mousePointerSpeed = 0.5,
    this.mouseAcceleration = true,
    this.scrollDirection = 'traditional',
    this.touchpadEnabled = true,
    this.disableWhileTyping = true,
    this.touchpadPointerSpeed = 0.5,
    this.secondaryClick = 'two-finger',
    this.tapToClick = true,
    this.errorMessage,
  });

  /// Creates a copy of this state with the given fields replaced
  MouseSettingsState copyWith({
    MouseSettingsStatus? status,
    int? selectedTab,
    String? primaryButton,
    double? mousePointerSpeed,
    bool? mouseAcceleration,
    String? scrollDirection,
    bool? touchpadEnabled,
    bool? disableWhileTyping,
    double? touchpadPointerSpeed,
    String? secondaryClick,
    bool? tapToClick,
    String? errorMessage,
  }) {
    return MouseSettingsState(
      status: status ?? this.status,
      selectedTab: selectedTab ?? this.selectedTab,
      primaryButton: primaryButton ?? this.primaryButton,
      mousePointerSpeed: mousePointerSpeed ?? this.mousePointerSpeed,
      mouseAcceleration: mouseAcceleration ?? this.mouseAcceleration,
      scrollDirection: scrollDirection ?? this.scrollDirection,
      touchpadEnabled: touchpadEnabled ?? this.touchpadEnabled,
      disableWhileTyping: disableWhileTyping ?? this.disableWhileTyping,
      touchpadPointerSpeed: touchpadPointerSpeed ?? this.touchpadPointerSpeed,
      secondaryClick: secondaryClick ?? this.secondaryClick,
      tapToClick: tapToClick ?? this.tapToClick,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedTab,
    primaryButton,
    mousePointerSpeed,
    mouseAcceleration,
    scrollDirection,
    touchpadEnabled,
    disableWhileTyping,
    touchpadPointerSpeed,
    secondaryClick,
    tapToClick,
    errorMessage,
  ];
}
