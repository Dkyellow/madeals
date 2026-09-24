import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../core/constants/mock_data.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isGuest;
  final String phoneNumber;
  final String countryCode;
  final String otpCode;
  final bool isOtpSent;
  final int resendCountdown;
  final UserProfile currentUser;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isGuest = false,
    this.phoneNumber = '774128990',
    this.countryCode = '+263',
    this.otpCode = '',
    this.isOtpSent = false,
    this.resendCountdown = 42,
    required this.currentUser,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isGuest,
    String? phoneNumber,
    String? countryCode,
    String? otpCode,
    bool? isOtpSent,
    int? resendCountdown,
    UserProfile? currentUser,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      otpCode: otpCode ?? this.otpCode,
      isOtpSent: isOtpSent ?? this.isOtpSent,
      resendCountdown: resendCountdown ?? this.resendCountdown,
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState(currentUser: MockData.currentUser));

  void setPhoneNumber(String number) {
    state = state.copyWith(phoneNumber: number);
  }

  void setCountryCode(String code) {
    state = state.copyWith(countryCode: code);
  }

  void setOtpCode(String code) {
    state = state.copyWith(otpCode: code);
  }

  void sendOtp() {
    state = state.copyWith(
      isOtpSent: true,
      resendCountdown: 42,
      isLoading: false,
    );
  }

  void tickCountdown() {
    if (state.resendCountdown > 0) {
      state = state.copyWith(resendCountdown: state.resendCountdown - 1);
    }
  }

  void resendOtp() {
    state = state.copyWith(resendCountdown: 42);
  }

  bool verifyOtp(String code) {
    // Demo verification logic
    if (code.length == 6 || code == '123456' || code.isNotEmpty) {
      state = state.copyWith(
        isAuthenticated: true,
        isGuest: false,
        currentUser: state.currentUser.copyWith(isPhoneVerified: true),
      );
      return true;
    }
    return false;
  }

  void continueAsGuest() {
    state = state.copyWith(
      isAuthenticated: false,
      isGuest: true,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
