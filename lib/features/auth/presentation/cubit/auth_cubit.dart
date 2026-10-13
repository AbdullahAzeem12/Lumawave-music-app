import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  StreamSubscription? _userSub;

  AuthRepository get authRepository => _authRepository;

  AuthCubit(this._authRepository) : super(AuthInitial()) {
    _init();
  }

  void _init() {
    _userSub = _authRepository.userStream.listen((user) async {
      if (user != null) {
        emit(Authenticated(user));
      } else {
        final rememberedEmail = await _authRepository.getRememberedEmail();
        String? rememberedPassword;
        if (rememberedEmail != null && rememberedEmail.isNotEmpty) {
          rememberedPassword =
              await _authRepository.getSavedPasswordForEmail(rememberedEmail);
        }
        emit(Unauthenticated(
          rememberedEmail: rememberedEmail,
          rememberedPassword: rememberedPassword,
        ));
      }
    });
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.signInWithEmail(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      final rememberedEmail = await _authRepository.getRememberedEmail();
      String? rememberedPassword;
      if (rememberedEmail != null) {
        rememberedPassword =
            await _authRepository.getSavedPasswordForEmail(rememberedEmail);
      }
      emit(Unauthenticated(
        rememberedEmail: rememberedEmail,
        rememberedPassword: rememberedPassword,
      ));
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(AuthLoading());
    try {
      await _authRepository.registerWithEmail(
        fullName: fullName,
        email: email,
        password: password,
      );
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      final rememberedEmail = await _authRepository.getRememberedEmail();
      String? rememberedPassword;
      if (rememberedEmail != null) {
        rememberedPassword =
            await _authRepository.getSavedPasswordForEmail(rememberedEmail);
      }
      emit(Unauthenticated(
        rememberedEmail: rememberedEmail,
        rememberedPassword: rememberedPassword,
      ));
    }
  }

  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _authRepository.resendConfirmationEmail(email);
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<bool> checkEmailConfirmationStatus() async {
    return await _authRepository.checkAndSyncEmailVerification();
  }

  Future<void> verifyEmailOtp(String email, String token) async {
    emit(AuthLoading());
    try {
      await _authRepository.verifyEmailOtp(email, token);
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> enterWithUnconfirmedEmail(String email) async {
    emit(AuthLoading());
    try {
      await _authRepository.createUnconfirmedSession(email);
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> sendPasswordReset(String email) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordReset(email);
      emit(PasswordResetSent(email));
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> updateProfilePicture(Uint8List imageBytes, {String extension = 'jpg'}) async {
    try {
      await _authRepository.updateProfilePicture(imageBytes, extension: extension);
      final current = _authRepository.currentUser;
      if (current != null) {
        emit(Authenticated(current));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      final current = _authRepository.currentUser;
      if (current != null) {
        emit(Authenticated(current));
      }
    }
  }

  Future<void> removeProfilePicture() async {
    try {
      await _authRepository.removeProfilePicture();
      final current = _authRepository.currentUser;
      if (current != null) {
        emit(Authenticated(current));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      final current = _authRepository.currentUser;
      if (current != null) {
        emit(Authenticated(current));
      }
    }
  }

  Future<void> updateProfilePictureUrl(String photoUrl) async {
    try {
      await _authRepository.updateProfilePictureUrl(photoUrl);
      final current = _authRepository.currentUser;
      if (current != null) {
        emit(Authenticated(current));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
      final current = _authRepository.currentUser;
      if (current != null) {
        emit(Authenticated(current));
      }
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }

  @override
  Future<void> close() {
    _userSub?.cancel();
    return super.close();
  }
}
