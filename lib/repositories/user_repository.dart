import '../models/address.dart';
import '../core/storage_service.dart';

class UserProfileData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String selectedCity;
  final String avatarUrl;

  const UserProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.selectedCity = 'Bahawalpur',
    this.avatarUrl = '',
  });

  UserProfileData copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? selectedCity,
    String? avatarUrl,
  }) {
    return UserProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      selectedCity: selectedCity ?? this.selectedCity,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'selectedCity': selectedCity,
    'avatarUrl': avatarUrl,
  };

  factory UserProfileData.fromMap(Map<String, dynamic> map) {
    return UserProfileData(
      id: map['id'] ?? 'usr_101',
      name: map['name'] ?? 'Umair',
      email: map['email'] ?? 'umair@example.com',
      phone: map['phone'] ?? '+92 301 7894561',
      selectedCity: map['selectedCity'] ?? 'Bahawalpur',
      avatarUrl: map['avatarUrl'] ?? '',
    );
  }
}

abstract class UserRepository {
  UserProfileData getUserProfile();
  void updateUserProfile(UserProfileData profile);
  List<Address> getAddresses();
  void saveAddresses(List<Address> addresses);
}

class LocalUserRepository implements UserRepository {
  final LocalStorageService _storage;

  LocalUserRepository(this._storage);

  @override
  UserProfileData getUserProfile() {
    return UserProfileData(
      id: _storage.getString('user_id') ?? 'usr_101',
      name: _storage.getString('user_name') ?? 'Umair',
      email: _storage.getString('user_email') ?? 'umair@example.com',
      phone: _storage.getString('user_phone') ?? '+92 301 7894561',
      selectedCity: _storage.getString('user_city') ?? 'Bahawalpur',
      avatarUrl: _storage.getString('user_avatar') ?? '',
    );
  }

  @override
  void updateUserProfile(UserProfileData profile) {
    _storage.saveString('user_id', profile.id);
    _storage.saveString('user_name', profile.name);
    _storage.saveString('user_email', profile.email);
    _storage.saveString('user_phone', profile.phone);
    _storage.saveString('user_city', profile.selectedCity);
    _storage.saveString('user_avatar', profile.avatarUrl);
  }

  @override
  List<Address> getAddresses() {
    final data = _storage.getJson('addresses_v2');
    if (data != null && data is List && data.isNotEmpty) {
      try {
        return data.map((e) => Address.fromMap(Map<String, dynamic>.from(e))).toList();
      } catch (_) {}
    }

    // Check legacy key
    final legacyData = _storage.getJson('addresses');
    if (legacyData != null && legacyData is List && legacyData.isNotEmpty) {
      try {
        final legacyAddresses = legacyData.map((e) => Address.fromMap(Map<String, dynamic>.from(e))).toList();
        saveAddresses(legacyAddresses);
        return legacyAddresses;
      } catch (_) {}
    }

    // Default authentic Pakistani addresses
    saveAddresses(defaultPakistaniAddresses);
    return defaultPakistaniAddresses;
  }

  @override
  void saveAddresses(List<Address> addresses) {
    _storage.saveJson('addresses_v2', addresses.map((a) => a.toMap()).toList());
  }
}
