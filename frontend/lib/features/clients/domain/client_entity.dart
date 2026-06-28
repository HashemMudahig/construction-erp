/// Client domain entity (immutable).
class ClientEntity {
  ClientEntity({
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
  final DateTime createdAt;
  final DateTime updatedAt;

  ClientEntity copyWith({
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    bool? archived,
  }) =>
      ClientEntity(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        address: address ?? this.address,
        notes: notes ?? this.notes,
        archived: archived ?? this.archived,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      other is ClientEntity && other.id == id;
  @override
  int get hashCode => id.hashCode;
}