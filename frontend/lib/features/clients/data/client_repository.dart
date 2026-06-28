import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/endpoints.dart';
import '../../../core/network/dio_provider.dart';
import 'client_dto.dart';

class ClientRepository {
  ClientRepository(this._dio);
  final Dio _dio;

  Future<List<ClientDto>> list({String? search, int skip = 0, int limit = 50}) async {
    final res = await _dio.get(Endpoints.clients, queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      'skip': skip,
      'limit': limit,
    });
    final list = res.data as List;
    return list.map((e) => ClientDto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ClientDto> get(String id) async {
    final res = await _dio.get(Endpoints.client(id));
    return ClientDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ClientDto> create(ClientCreateDto dto) async {
    final res = await _dio.post(Endpoints.clients, data: dto.toJson());
    return ClientDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<ClientDto> update(String id, ClientUpdateDto dto) async {
    final res = await _dio.put(Endpoints.client(id), data: dto.toJson());
    return ClientDto.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) async {
    await _dio.delete(Endpoints.client(id));
  }
}

final clientRepositoryProvider = Provider<ClientRepository>((ref) {
  return ClientRepository(ref.watch(dioProvider));
});