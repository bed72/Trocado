import 'package:trocado/src/infrastructure/clients/http/responses/failure/failure_item_response.dart';

final class FailureResponse {
  final List<FailureItemResponse> errors;

  const FailureResponse({required this.errors});

  factory FailureResponse.fromJson(Map<String, dynamic> json) =>
      FailureResponse(
        errors: (json['errors'] as List)
            .map(
              (error) =>
                  FailureItemResponse.fromJson(error as Map<String, dynamic>),
            )
            .toList(),
      );
}
