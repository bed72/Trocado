import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';
import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/screens/authentication/sign_in/validators/sign_in_form_validator.dart';

part 'validators_provider.g.dart';

@Riverpod()
SignInFormValidator signInFormValidator(Ref _) => const SignInFormValidator(
  emailValidation: EmailValidation(),
  passwordValidation: PasswordValidation(),
);
