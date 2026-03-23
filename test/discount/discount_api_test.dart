import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/core/network/idempotency_key_store.dart';
import 'package:modular_pos/features/discount/data/discount_api.dart';
import 'package:modular_pos/features/discount/domain/models/discount_eligibility.dart';
import 'package:modular_pos/features/discount/domain/models/discount_rule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_schedule.dart';
import 'package:modular_pos/features/discount/domain/models/discount_scope.dart';
import 'package:modular_pos/features/discount/domain/models/discount_status.dart';

class _MockDio extends Mock implements Dio {}

class _FakeOptions extends Fake implements Options {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeOptions());
  });

  group('DiscountApi', () {
    test(
      'getDiscountRules forwards status scope and search query params',
      () async {
        final dio = _MockDio();
        when(
          () => dio.get<dynamic>(
            any(),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(path: '/v0/discount/rules'),
            data: {
              'success': true,
              'data': {
                'items': [
                  {
                    'id': 'disc-1',
                    'tenantId': 'tenant-1',
                    'branchId': 'branch-1',
                    'name': 'Coffee 10%',
                    'percentage': 10,
                    'scope': 'ITEM',
                    'status': 'ACTIVE',
                    'itemIds': ['item-1'],
                    'schedule': {
                      'startAt': '2026-03-20T00:00:00.000Z',
                      'endAt': '2026-03-21T00:00:00.000Z',
                    },
                    'stackingPolicy': 'MULTIPLICATIVE',
                    'createdAt': '2026-03-19T00:00:00.000Z',
                    'updatedAt': '2026-03-19T00:00:00.000Z',
                  },
                ],
                'limit': 20,
                'offset': 0,
                'total': 1,
                'hasMore': false,
              },
            },
          ),
        );

        final api = DiscountApi(dio);
        final rows = await api.getDiscountRules(
          status: 'active',
          scope: 'item',
          branchId: 'branch-1',
          search: 'coffee',
          limit: 20,
          offset: 0,
        );

        verify(
          () => dio.get<dynamic>(
            '/v0/discount/rules',
            queryParameters: {
              'status': 'active',
              'scope': 'item',
              'branchId': 'branch-1',
              'search': 'coffee',
              'limit': 20,
              'offset': 0,
            },
          ),
        ).called(1);
        expect(rows, hasLength(1));
        expect(rows.single.id, 'disc-1');
        expect(rows.single.status, 'ACTIVE');
      },
    );

    test('createDiscountRule includes idempotency metadata', () async {
      final dio = _MockDio();
      when(
        () => dio.post<dynamic>(
          any(),
          data: any(named: 'data'),
          options: any(named: 'options'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: '/v0/discount/rules'),
          data: {
            'success': true,
            'data': {
              'id': 'disc-1',
              'tenantId': 'tenant-1',
              'branchId': 'branch-1',
              'name': 'Coffee 10%',
              'percentage': 10,
              'scope': 'ITEM',
              'status': 'INACTIVE',
              'itemIds': ['item-1'],
              'schedule': {
                'startAt': '2026-03-20T00:00:00.000Z',
                'endAt': '2026-03-21T00:00:00.000Z',
              },
              'stackingPolicy': 'MULTIPLICATIVE',
              'createdAt': '2026-03-19T00:00:00.000Z',
              'updatedAt': '2026-03-19T00:00:00.000Z',
            },
          },
        ),
      );

      final api = DiscountApi(dio);
      final rule = DiscountRule(
        id: '',
        tenantId: 'tenant-1',
        branchId: 'branch-1',
        name: 'Coffee 10%',
        percentage: 10,
        scope: DiscountScopes.item,
        status: DiscountStatuses.inactive,
        itemIds: const ['item-1'],
        schedule: DiscountSchedule(
          startAt: DateTime.utc(2026, 3, 20),
          endAt: DateTime.utc(2026, 3, 21),
        ),
      );

      await api.createDiscountRule(rule: rule);

      final expectedPayload = {
        'name': 'Coffee 10%',
        'branchId': 'branch-1',
        'percentage': 10.0,
        'scope': 'ITEM',
        'itemIds': ['item-1'],
        'schedule': {
          'startAt': '2026-03-20T00:00:00.000Z',
          'endAt': '2026-03-21T00:00:00.000Z',
        },
        'confirmOverlap': false,
      };

      verify(
        () => dio.post<dynamic>(
          '/v0/discount/rules',
          data: expectedPayload,
          options: any(
            named: 'options',
            that: isA<Options>().having(
              (o) => o.extra?[idempotencyRequestExtraKey],
              'idempotencyRequest',
              isA<IdempotencyRequest>()
                  .having(
                    (r) => r.actionKey,
                    'actionKey',
                    'discount.rules.create',
                  )
                  .having((r) => r.payload, 'payload', expectedPayload),
            ),
          ),
        ),
      ).called(1);
    });

    test(
      'updateDiscountRuleStatus uses a fresh idempotency intent for repeated toggles',
      () async {
        final dio = _MockDio();
        final requests = <Options?>[];
        when(
          () => dio.post<dynamic>(any(), options: any(named: 'options')),
        ).thenAnswer((invocation) async {
          requests.add(invocation.namedArguments[#options] as Options?);
          return Response<dynamic>(
            requestOptions: RequestOptions(
              path: '/v0/discount/rules/disc-1/activate',
            ),
            data: {
              'success': true,
              'data': {
                'id': 'disc-1',
                'tenantId': 'tenant-1',
                'branchId': 'branch-1',
                'name': 'Coffee 10%',
                'percentage': 10,
                'scope': 'ITEM',
                'status': 'ACTIVE',
                'itemIds': ['item-1'],
                'schedule': {
                  'startAt': '2026-03-20T00:00:00.000Z',
                  'endAt': '2026-03-21T00:00:00.000Z',
                },
                'stackingPolicy': 'MULTIPLICATIVE',
                'createdAt': '2026-03-19T00:00:00.000Z',
                'updatedAt': '2026-03-19T00:00:00.000Z',
              },
            },
          );
        });

        final api = DiscountApi(dio);
        await api.updateDiscountRuleStatus(
          ruleId: 'disc-1',
          status: DiscountStatuses.active,
        );
        await api.updateDiscountRuleStatus(
          ruleId: 'disc-1',
          status: DiscountStatuses.active,
        );

        expect(requests, hasLength(2));
        final firstRequest =
            requests.first!.extra?[idempotencyRequestExtraKey]
                as IdempotencyRequest;
        final secondRequest =
            requests.last!.extra?[idempotencyRequestExtraKey]
                as IdempotencyRequest;
        expect(firstRequest.actionKey, 'discount.rules.activate');
        expect(secondRequest.actionKey, 'discount.rules.activate');
        expect(firstRequest.intentId, isNotEmpty);
        expect(secondRequest.intentId, isNotEmpty);
        expect(secondRequest.intentId, isNot(firstRequest.intentId));
      },
    );

    test(
      'resolveDiscountEligibility posts branch occurredAt and lines',
      () async {
        final dio = _MockDio();
        when(
          () => dio.post<dynamic>(any(), data: any(named: 'data')),
        ).thenAnswer(
          (_) async => Response<dynamic>(
            requestOptions: RequestOptions(
              path: '/v0/discount/eligibility/resolve',
            ),
            data: {
              'success': true,
              'data': {
                'rules': [
                  {
                    'ruleId': 'disc-1',
                    'percentage': 10,
                    'scope': 'ITEM',
                    'itemIds': ['item-1'],
                    'stackingPolicy': 'MULTIPLICATIVE',
                  },
                ],
              },
            },
          ),
        );

        final api = DiscountApi(dio);
        final occurredAt = DateTime.utc(2026, 3, 22, 3, 15);
        final rows = await api.resolveDiscountEligibility(
          branchId: 'branch-1',
          occurredAt: occurredAt,
          lines: const [
            DiscountEligibilityLineInput(menuItemId: 'item-1', quantity: 2),
            DiscountEligibilityLineInput(menuItemId: 'item-2', quantity: 1),
          ],
        );

        verify(
          () => dio.post<dynamic>(
            '/v0/discount/eligibility/resolve',
            data: {
              'branchId': 'branch-1',
              'occurredAt': '2026-03-22T03:15:00.000Z',
              'lines': [
                {'menuItemId': 'item-1', 'quantity': 2},
                {'menuItemId': 'item-2', 'quantity': 1},
              ],
            },
          ),
        ).called(1);
        expect(rows, hasLength(1));
        expect(rows.single.ruleId, 'disc-1');
      },
    );
  });
}
