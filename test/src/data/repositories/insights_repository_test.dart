import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:trocado/src/domain/either/either.dart';

import 'package:trocado/src/data/repositories/insights_repository.dart';

import 'package:trocado/src/domain/failures/failure.dart';
import 'package:trocado/src/domain/enums/insight/insight_type_enum.dart';
import 'package:trocado/src/domain/enums/scope/financial_scope_enum.dart';
import 'package:trocado/src/domain/enums/insight/insight_severity_enum.dart';
import 'package:trocado/src/domain/repositories/interface_insights_repository.dart';

import 'package:trocado/src/infrastructure/clients/http/http_client.dart';
import 'package:trocado/src/infrastructure/clients/http/requests/requests.dart';
import 'package:trocado/src/infrastructure/datasources/remote/remote_insights_data_source.dart';

import '../../../mocks/mocks.dart';

const _successJson = {
  'data': {
    'insights': [
      {
        'severity': 'danger',
        'title': 'Estourou',
        'description': 'Usou 146%.',
        'type': 'budget_utilization',
        'data': {'budget_pct': 145.61},
      },
      {
        'severity': 'info',
        'type': 'top_category',
        'title': 'Categoria em destaque',
        'description': 'Housing em 56%.',
        'data': {'category': 'housing', 'pct': 55.98},
      },
    ],
    'has_enough_data': true,
    'generated_at': '2026-04-22T18:24:36.544845+00:00',
  },
};

void main() {
  late IHttpClient client;
  late IInsightsRepository repository;

  setUp(() {
    client = MockHttpClient();
    repository = InsightsRepository(
      dataSource: RemoteInsightsDataSource(client: client),
    );

    registerFallbackValue(const Requests('/'));
  });

  group('findAll', () {
    test('returns Right with InsightsBundleModel on success', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

      expect(data.isRight, isTrue);
      expect(data.right.hasEnoughData, isTrue);
      expect(data.right.insights, hasLength(2));
      expect(data.right.insights.first.data['budget_pct'], 145.61);
      expect(data.right.insights.first.severity, InsightSeverityEnum.danger);
      expect(data.right.insights.first.type, InsightTypeEnum.budgetUtilization);
    });

    test('returns Right with empty list when backend returns empty', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Right({
          'data': {
            'insights': [],
            'has_enough_data': false,
            'generated_at': '2026-04-22T18:24:36.544845+00:00',
          },
        }),
      );

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

      expect(data.isRight, isTrue);
      expect(data.right.insights, isEmpty);
      expect(data.right.hasEnoughData, isFalse);
    });

    test('maps unknown type and severity to unknown enums', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => Right(<String, dynamic>{
          'data': {
            'insights': [
              <String, dynamic>{
                'title': 'titulo',
                'description': 'desc',
                'severity': 'critical',
                'type': 'brand_new_type',
                'data': <String, dynamic>{},
              },
            ],
            'has_enough_data': true,
            'generated_at': '2026-04-22T18:24:36.544845+00:00',
          },
        }),
      );

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

      expect(data.isRight, isTrue);
      expect(data.right.insights.first.type, InsightTypeEnum.unknown);
      expect(data.right.insights.first.severity, InsightSeverityEnum.unknown);
    });

    test('returns Left NetworkFailure on network error', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'network_error',
              'message': 'Network error',
              'field': 'non_field_errors',
            },
          ],
        }),
      );

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<NetworkFailure>());
    });

    test('returns Left ServerFailure on server error', () async {
      when(() => client.get(parameter: any(named: 'parameter'))).thenAnswer(
        (_) async => const Left({
          'errors': [
            {
              'code': 'server_error',
              'field': 'non_field_errors',
              'message': 'Internal server error',
            },
          ],
        }),
      );

      final data = await repository.findAll(scope: FinancialScopeEnum.mine);

      expect(data.isLeft, isTrue);
      expect(data.left, isA<ServerFailure>());
    });

    test('uses /insights/shared path when scope is couple', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      await repository.findAll(scope: FinancialScopeEnum.couple);

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/insights/shared');
    });

    test('uses /insights path when scope is mine', () async {
      when(
        () => client.get(parameter: any(named: 'parameter')),
      ).thenAnswer((_) async => const Right(_successJson));

      await repository.findAll(scope: FinancialScopeEnum.mine);

      final captured =
          verify(
                () => client.get(parameter: captureAny(named: 'parameter')),
              ).captured.single
              as Requests;

      expect(captured.path, '/api/v1/insights');
    });
  });
}
