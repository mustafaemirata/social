  //auth states

  import 'package:social/features/auth/domain/entities/app_user.dart';

  abstract class AuthStates {}

  //initial
  class AuthInitial extends AuthStates {}

  //loading
  class AuthLoading extends AuthStates {}

  //authenticated
  class Authenticated extends AuthStates {
    final AppUser user;
    Authenticated(this.user);
  }

  //unathenticated
  class UnAuthenticated extends AuthStates {}

  //errors
  class AuthError extends AuthStates {
    final String message;
    AuthError(this.message);
  }
