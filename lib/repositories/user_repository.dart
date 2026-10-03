import '../models/address.dart';
import '../core/storage_service.dart';

class UserProfileData {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String selectedCity;

  const UserProfileData({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.selectedCity = 'Lahore',
  });

  UserProfileData copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? selectedCity,
  }) {
    return UserProfileData(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      selectedCity: selectedCity ?? this.selectedCity,
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
      phone: _storage.getString('user_phone') ?? '+92 300 1234567',
      selectedCity: _storage.getString('user_city') ?? 'Lahore',
    );
  }

  @override
  void updateUserProfile(UserProfileData profile) {
    _storage.saveString('user_id', profile.id);
    _storage.saveString('user_name', profile.name);
    _storage.saveString('user_email', profile.email);
    _storage.saveString('user_phone', profile.phone);
    _storage.saveString('user_city', profile.selectedCity);
  }

  @override
  List<Address> getAddresses() {
    final data = _storage.getJson('addresses');
    if (data != null && data is List && data.isNotEmpty) {
      return data.map((e) => Address.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return const [
      Address(
        id: 'addr_default',
        name: 'Umair',
        street: 'House 14-B, Street 5, Sector F-7/2',
        city: 'Islamabad',
        state: 'ICT',
        zipCode: '44000',
        country: 'Pakistan',
        isDefault: true,
      ),
    ];
  }

  @override
  void saveAddresses(List<Address> addresses) {
    _storage.saveJson('addresses', addresses.map((a) => a.toJson()).toList());
  }
}
