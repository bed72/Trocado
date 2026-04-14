import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';
import 'package:trocado/src/presentation/validators/password_validation.dart';
import 'package:trocado/src/presentation/validators/terms_validation.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/validators/sign_in_form_validator.dart';
import 'package:trocado/src/presentation/screens/authentication/sign_up/validators/sign_up_form_validator.dart';
import 'package:trocado/src/presentation/screens/authentication/forgot_password/validators/forgot_password_form_validator.dart';

part 'validators_provider.g.dart';

@Riverpod()
SignInFormValidator signInFormValidator(Ref _) => const SignInFormValidator(
  emailValidation: EmailValidation(),
  passwordValidation: PasswordValidation(),
);

@Riverpod()
SignUpFormValidator signUpFormValidator(Ref _) => const SignUpFormValidator(
  emailValidation: EmailValidation(),
  passwordValidation: PasswordValidation(),
  termsValidation: TermsValidation(),
);

@Riverpod()
ForgotPasswordFormValidator forgotPasswordFormValidator(Ref _) =>
    const ForgotPasswordFormValidator(emailValidation: EmailValidation());
