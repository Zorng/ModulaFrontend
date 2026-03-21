import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:modular_pos/features/menu/data/menu_api.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  setUpAll(() {
    dotenv.testLoad();
  });

  group('MenuApi.fetchMenuItems read lane', () {
    test('branch lane uses /items and never sends branchId override', () async {
      final dio = _MockDio();
      when(
        () => dio.get<dynamic>(
          '/v0/menu/items',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          data: {
            'success': true,
            'data': {
              'items': [
                {
                  'id': 'item-1',
                  'tenantId': 'tenant-1',
                  'name': 'Latte',
                  'categoryId': 'cat-1',
                  'basePrice': 2.5,
                  'status': 'ACTIVE',
                  'visibleBranchIds': ['branch-1'],
                  'modifierGroupIds': ['group-1'],
                },
              ],
            },
          },
          requestOptions: RequestOptions(path: '/v0/menu/items'),
        ),
      );

      final api = MenuApi.real(dio);
      final items = await api.fetchMenuItems(
        includeAllBranches: false,
        status: 'active',
        categoryId: 'cat-1',
        search: 'latte',
        limit: 50,
        offset: 0,
        branchId: 'branch-1',
      );

      expect(items, hasLength(1));
      expect(items.first.id, 'item-1');

      final captured =
          verify(
                () => dio.get<dynamic>(
                  '/v0/menu/items',
                  queryParameters: captureAny(named: 'queryParameters'),
                ),
              ).captured.single
              as Map<String, dynamic>;

      expect(captured['status'], 'ACTIVE');
      expect(captured['categoryId'], 'cat-1');
      expect(captured['search'], 'latte');
      expect(captured['limit'], 50);
      expect(captured['offset'], 0);
      expect(captured.containsKey('branchId'), isFalse);
    });

    test(
      'management lane uses /items/all and sends branchId as filter',
      () async {
        final dio = _MockDio();
        when(
          () => dio.get<dynamic>(
            '/v0/menu/items/all',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response<dynamic>(
            data: {
              'success': true,
              'data': {
                'items': [
                  {
                    'id': 'item-1',
                    'tenantId': 'tenant-1',
                    'name': 'Latte',
                    'categoryId': 'cat-1',
                    'basePrice': 2.5,
                    'status': 'ACTIVE',
                    'visibleBranchIds': ['branch-1', 'branch-2'],
                    'modifierGroupIds': ['group-1'],
                  },
                ],
              },
            },
            requestOptions: RequestOptions(path: '/v0/menu/items/all'),
          ),
        );

        final api = MenuApi.real(dio);
        final items = await api.fetchMenuItems(
          includeAllBranches: true,
          status: 'all',
          categoryId: 'cat-1',
          search: 'latte',
          limit: 25,
          offset: 25,
          branchId: 'branch-2',
        );

        expect(items, hasLength(1));
        expect(items.first.visibleBranchIds, ['branch-1', 'branch-2']);

        final captured =
            verify(
                  () => dio.get<dynamic>(
                    '/v0/menu/items/all',
                    queryParameters: captureAny(named: 'queryParameters'),
                  ),
                ).captured.single
                as Map<String, dynamic>;

        expect(captured['status'], 'all');
        expect(captured['categoryId'], 'cat-1');
        expect(captured['search'], 'latte');
        expect(captured['limit'], 25);
        expect(captured['offset'], 25);
        expect(captured['branchId'], 'branch-2');
      },
    );
  });

  group('MenuApi.fetchBranches', () {
    test('loads branch options from /v0/auth/context/branches', () async {
      final dio = _MockDio();
      when(() => dio.get<dynamic>('/v0/auth/context/branches')).thenAnswer(
        (_) async => Response<dynamic>(
          data: {
            'success': true,
            'data': {
              'state': 'BRANCH_SELECTION_REQUIRED',
              'tenantId': 'tenant-1',
              'selectedBranchId': null,
              'branches': [
                {'branchId': 'branch-1', 'branchName': 'Main'},
                {'branchId': 'branch-2', 'branchName': 'Downtown'},
              ],
            },
          },
          requestOptions: RequestOptions(path: '/v0/auth/context/branches'),
        ),
      );

      final api = MenuApi.real(dio);
      final branches = await api.fetchBranches();

      expect(branches, hasLength(2));
      expect(branches.first.id, 'branch-1');
      expect(branches.first.name, 'Main');
      expect(branches.last.id, 'branch-2');
      expect(branches.last.name, 'Downtown');

      verify(() => dio.get<dynamic>('/v0/auth/context/branches')).called(1);
    });
  });
}
