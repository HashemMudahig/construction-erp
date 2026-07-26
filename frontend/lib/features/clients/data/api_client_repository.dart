import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';
import '../domain/client_entity.dart';
import '../domain/client_repository_interface.dart';
import 'client_dto.dart';

/// Preserved remote (FastAPI) client repository implementation.
///
/// This adapter remains in the codebase for future remote access or
/// synchronization. It is NOT the active runtime implementation.
///
/// The active runtime uses [LocalClientRepository] via Drift/SQLite.
///
/// Preserved endpoints:
/// - GET /clients — list with search, skip, limit
/// - GET /clients/{id} — get by ID
/// - POST /clients — create
/// - PUT /clients/{id} — update
/// - DELETE /clients/{id} — delete (server enforces CLIENT_HAS_PROJECTS)
class ApiClientRepository implements ClientRepositoryInterface {
  ApiClientRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<ClientEntity>> list({
    String? search,
    bool includeArchived = false,
  }) async {
    final res = await _dio.get(Endpoints.clients, queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'skip': 0,
      'limit': 50,
    });
    final list = res.data as List;
    return list
        .map((e) => ClientDto.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  }

  @override
  Future<ClientEntity?> getById(String id) async {
    final res = await _dio.get(Endpoints.client(id));
    return ClientDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<ClientEntity> create({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    final dto = ClientCreateDto(
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
    );
    final res = await _dio.post(Endpoints.clients, data: dto.toJson());
    return ClientDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<ClientEntity> update({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? archived,
  }) async {
    final dto = ClientUpdateDto(
      name: name,
      phone: phone,
      email: email,
      address: address,
      notes: notes,
      archived: archived,
    );
    final res = await _dio.put(Endpoints.client(id), data: dto.toJson());
    return ClientDto.fromJson(res.data as Map<String, dynamic>).toEntity();
  }

  @override
  Future<void> archive(String id) async {
    await _dio.put(Endpoints.client(id),
        data: ClientUpdateDto(archived: true).toJson());
  }

  @override
  Future<void> restore(String id) async {
    await _dio.put(Endpoints.client(id),
        data: ClientUpdateDto(archived: false).toJson());
  }

  @override
  Future<void> deleteIfEligible(String id) async {
    await _dio.delete(Endpoints.client(id));
  }

  @override
  Future<bool> hasProjects(String id) async {
    // The remote API does not expose a direct hasProjects endpoint.
    // Projects can be listed with client_id filter.
    // For preservation purposes, we return false as a safe default.
    // The local repository performs an actual database query.
    return false;
  }
}

/// Preserved remote provider — not used in local runtime.
///
/// Kept for future remote adapter use. The active runtime uses
/// [localClientRepositoryProvider].
final apiClientRepositoryProvider = Provider<ApiClientRepository>((ref) {
  return ApiClientRepository(ref.watch(dioProvider));
});
