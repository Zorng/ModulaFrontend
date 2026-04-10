import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:modular_pos/core/logging/app_log.dart';
import 'package:modular_pos/core/network/api_contract.dart';
import 'package:modular_pos/features/auth/data/auth_repository.dart';
import 'package:modular_pos/features/auth/domain/phone_input.dart';
import 'package:modular_pos/features/auth/ui/viewmodels/login_controller.dart';

class ForgotPasswordState {
  static const Object _unset = Object();

  const ForgotPasswordState({
    this.isLoading = false,
    this.error,
    this.errorCode,
    this.errorStatusCode,
    this.phone,
    this.otpExpiresInMinutes,
  });

  final bool isLoading;
  final String? error;
  final String? errorCode;
  final int? errorStatusCode;
  final String? phone;
  final int? otpExpiresInMinutes;

  ForgotPasswordState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? errorCode = _unset,
    Object? errorStatusCode = _unset,
    Object? phone = _unset,
    Object? otpExpiresInMinutes = _unset,
  }) {
    return ForgotPasswordState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      errorCode: identical(errorCode, _unset)
          ? this.errorCode
          : errorCode as String?,
      errorStatusCode: identical(errorStatusCode, _unset)
          ? this.errorStatusCode
          : errorStatusCode as int?,
      phone: identical(phone, _unset) ? this.phone : phone as String?,
      otpExpiresInMinutes: identical(otpExpiresInMinutes, _unset)
          ? this.otpExpiresInMinutes
          : otpExpiresInMinutes as int?,
    );
  }
}

final forgotPasswordControllerProvider =
    NotifierProvider<ForgotPasswordController, ForgotPasswordState>(
      ForgotPasswordController.new,
    );

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  AuthRepository get _repository => ref.read(authRepositoryProvider);

  @override
  ForgotPasswordState build() => const ForgotPasswordState();

  Future<bool> requestResetOtp({required String phone}) async {
    final normalizedPhone = normalizePhoneInput(phone);
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
      phone: normalizedPhone,
    );

    try {
      final result = await _repository.requestPasswordReset(
        phone: normalizedPhone,
      );
      state = state.copyWith(
        isLoading: false,
        phone: normalizedPhone,
        otpExpiresInMinutes: result.expiresInMinutes,
      );
      return true;
    } catch (error, stackTrace) {
      _setError(
        error,
        stackTrace,
        fallbackMessage: 'Failed to send password reset OTP.',
      );
      return false;
    }
  }

  Future<bool> confirmReset({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    final normalizedPhone = normalizePhoneInput(phone);
    state = state.copyWith(
      isLoading: true,
      error: null,
      errorCode: null,
      errorStatusCode: null,
      phone: normalizedPhone,
    );

    try {
      final result = await _repository.confirmPasswordReset(
        phone: normalizedPhone,
        otp: otp.trim(),
        newPassword: newPassword,
      );
      if (!result.reset) {
        state = state.copyWith(
          isLoading: false,
          error: 'Password reset failed.',
          errorCode: 'PASSWORD_RESET_FAILED',
          errorStatusCode: 400,
        );
        return false;
      }

      await ref.read(loginControllerProvider.notifier).logout();
      state = const ForgotPasswordState();
      return true;
    } catch (error, stackTrace) {
      _setError(
        error,
        stackTrace,
        fallbackMessage: 'Failed to reset password.',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null, errorCode: null, errorStatusCode: null);
  }

  void setPhoneIfEmpty(String phone) {
    final normalizedPhone = normalizePhoneInput(phone);
    if (normalizedPhone.isEmpty || (state.phone ?? '').trim().isNotEmpty) {
      return;
    }
    state = state.copyWith(phone: normalizedPhone);
  }

  void _setError(
    Object error,
    StackTrace stackTrace, {
    required String fallbackMessage,
  }) {
    AppLog.e(fallbackMessage, error: error, stackTrace: stackTrace);
    if (error is ApiClientException) {
      state = state.copyWith(
        isLoading: false,
        error: error.message,
        errorCode: error.code,
        errorStatusCode: error.statusCode,
      );
      return;
    }
    state = state.copyWith(isLoading: false, error: fallbackMessage);
  }
}
