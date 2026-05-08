import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:trocado/src/presentation/validators/email_validation.dart';
import 'package:trocado/src/presentation/validators/password_validation.dart';

import 'package:trocado/src/presentation/ui/budget/validators/budget_form_validator.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_value_validation.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_date_range_validation.dart';
import 'package:trocado/src/presentation/ui/budget/validators/budget_description_validation.dart';

import 'package:trocado/src/presentation/ui/expense/validators/expense_form_validator.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_date_validation.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_value_validation.dart';
import 'package:trocado/src/presentation/ui/expense/validators/expense_description_validation.dart';

import 'package:trocado/src/presentation/ui/profile/name/validators/name_validation.dart';
import 'package:trocado/src/presentation/ui/profile/name/validators/profile_name_form_validator.dart';
import 'package:trocado/src/presentation/ui/profile/purge/validators/profile_purge_form_validator.dart';
import 'package:trocado/src/presentation/ui/profile/password/validators/profile_password_form_validator.dart';

import 'package:trocado/src/presentation/ui/authentication/sign_up/validators/terms_validation.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_up/validators/sign_up_form_validator.dart';
import 'package:trocado/src/presentation/ui/authentication/sign_in/validators/sign_in_form_validator.dart';
import 'package:trocado/src/presentation/ui/authentication/forgot_password/validators/forgot_password_form_validator.dart';
import 'package:trocado/src/presentation/ui/authentication/password_reset_confirm/validators/password_reset_confirm_form_validator.dart';

part 'validators_provider.g.dart';

@Riverpod()
SignInFormValidator signInFormValidator(Ref _) => const SignInFormValidator(
  emailValidation: EmailValidation(),
  passwordValidation: PasswordValidation(),
);

@Riverpod()
SignUpFormValidator signUpFormValidator(Ref _) => const SignUpFormValidator(
  emailValidation: EmailValidation(),
  termsValidation: TermsValidation(),
  passwordValidation: PasswordValidation(),
);

@Riverpod()
ForgotPasswordFormValidator forgotPasswordFormValidator(Ref _) =>
    const ForgotPasswordFormValidator(emailValidation: EmailValidation());

@Riverpod()
PasswordResetConfirmFormValidator passwordResetConfirmFormValidator(Ref _) =>
    const PasswordResetConfirmFormValidator(
      passwordValidation: PasswordValidation(),
    );

@Riverpod()
BudgetFormValidator budgetFormValidator(Ref _) => const BudgetFormValidator(
  valueValidation: BudgetValueValidation(),
  dateRangeValidation: BudgetDateRangeValidation(),
  descriptionValidation: BudgetDescriptionValidation(),
);

@Riverpod()
ExpenseFormValidator expenseFormValidator(Ref _) => const ExpenseFormValidator(
  dateValidation: ExpenseDateValidation(),
  valueValidation: ExpenseValueValidation(),
  descriptionValidation: ExpenseDescriptionValidation(),
);

@Riverpod()
ProfileNameFormValidator profileNameFormValidator(Ref _) =>
    const ProfileNameFormValidator(nameValidation: NameValidation());

@Riverpod()
ProfilePasswordFormValidator profilePasswordFormValidator(Ref _) =>
    const ProfilePasswordFormValidator(
      passwordValidation: PasswordValidation(),
    );

@Riverpod()
ProfilePurgeFormValidator profilePurgeFormValidator(Ref _) =>
    const ProfilePurgeFormValidator(passwordValidation: PasswordValidation());
