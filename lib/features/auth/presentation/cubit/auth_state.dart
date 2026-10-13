import 'package:equatable/equatable.dart';
import '../../data/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  final String? rememberedEmail;
  final String? rememberedPassword;
  const Unauthenticated({this.rememberedEmail, this.rememberedPassword});
  @override
  List<Object?> get props => [rememberedEmail, rememberedPassword];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

class PasswordResetSent extends AuthState {
  final String email;
  const PasswordResetSent(this.email);
  @override
  List<Object?> get props => [email];
}
