import 'package:construction_erp/features/clients/domain/client_entity.dart';

/// DTO mirroring the backend Client schema.
class ClientDto {
  ClientDto({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.archived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool archived;
  final String createdAt;
  final String updatedAt;

  factory ClientDto.fromJson(Map<String, dynamic> json) => ClientDto(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        address: json['address'] as String?,
        notes: json['notes'] as String?,
        archived: json['archived'] as bool? ?? false,
        createdAt: json['created_at'] as String,
        updatedAt: json['updated_at'] as String,
      );

  ClientEntity toEntity() => ClientEntity(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        archived: archived,
        createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
        updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
      );
}

class ClientCreateDto {
  ClientCreateDto({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.archived = false,
  });
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool archived;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
        'archived': archived,
      };
}

class ClientUpdateDto {
  ClientUpdateDto({
    this.name,
    this.phone,
    this.email,
    this.address,
    this.notes,
    this.archived,
  });
  final String? name;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final bool? archived;

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{};
    if (name != null) m['name'] = name;
    if (phone != null) m['phone'] = phone;
    if (email != null) m['email'] = email;
    if (address != null) m['address'] = address;
    if (notes != null) m['notes'] = notes;
    if (archived != null) m['archived'] = archived;
    return m;
  }
}
