class Address {
  final String id;
  final String name;
  final String phone;
  final String houseFlat;
  final String streetArea;
  final String city;
  final String province;
  final String postalCode;
  final String? landmark;
  final String country;
  final bool isDefault;

  const Address({
    required this.id,
    required this.name,
    this.phone = '+92 300 1234567',
    this.houseFlat = '',
    this.streetArea = '',
    required this.city,
    this.province = 'Punjab',
    this.postalCode = '54000',
    this.landmark,
    this.country = 'Pakistan',
    this.isDefault = false,
    String? street,
    String? state,
    String? zipCode,
  }) : _legacyStreet = street,
       _legacyState = state,
       _legacyZipCode = zipCode;

  final String? _legacyStreet;
  final String? _legacyState;
  final String? _legacyZipCode;

  // Backward compatibility getters
  String get street {
    final legacy = _legacyStreet;
    if (legacy != null && legacy.isNotEmpty) return legacy;
    if (houseFlat.isNotEmpty && streetArea.isNotEmpty) {
      return '$houseFlat, $streetArea';
    }
    return houseFlat.isNotEmpty ? houseFlat : streetArea;
  }

  String get state => _legacyState ?? province;
  String get zipCode => _legacyZipCode ?? postalCode;

  String get formattedAddress {
    final parts = <String>[];
    if (houseFlat.isNotEmpty) parts.add(houseFlat);
    if (streetArea.isNotEmpty) parts.add(streetArea);
    if (landmark != null && landmark!.trim().isNotEmpty) parts.add('Near $landmark');
    if (city.isNotEmpty) parts.add(city);
    if (province.isNotEmpty) parts.add(province);
    if (postalCode.isNotEmpty) parts.add(postalCode);
    parts.add(country);
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'phone': phone,
    'houseFlat': houseFlat,
    'streetArea': streetArea,
    'city': city,
    'province': province,
    'postalCode': postalCode,
    'landmark': landmark,
    'country': country,
    'isDefault': isDefault,
    // Legacy support
    'street': street,
    'state': state,
    'zipCode': zipCode,
  };

  Map<String, dynamic> toJson() => toMap();

  factory Address.fromMap(Map<String, dynamic> map) {
    final legacyStreet = map['street'] as String?;
    final house = (map['houseFlat'] as String?) ?? '';
    final area = (map['streetArea'] as String?) ?? '';
    
    // Parse legacy street if new fields empty
    String resolvedHouse = house;
    String resolvedArea = area;
    if (resolvedHouse.isEmpty && resolvedArea.isEmpty && legacyStreet != null) {
      final parts = legacyStreet.split(',');
      if (parts.length > 1) {
        resolvedHouse = parts.first.trim();
        resolvedArea = parts.sublist(1).join(',').trim();
      } else {
        resolvedArea = legacyStreet.trim();
      }
    }

    return Address(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: (map['phone'] as String?) ?? '+92 300 1234567',
      houseFlat: resolvedHouse,
      streetArea: resolvedArea,
      city: (map['city'] as String?) ?? 'Lahore',
      province: (map['province'] as String?) ?? (map['state'] as String?) ?? 'Punjab',
      postalCode: (map['postalCode'] as String?) ?? (map['zipCode'] as String?) ?? '54000',
      landmark: map['landmark'] as String?,
      country: (map['country'] as String?) ?? 'Pakistan',
      isDefault: (map['isDefault'] as bool?) ?? false,
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) => Address.fromMap(json);

  Address copyWith({
    String? id,
    String? name,
    String? phone,
    String? houseFlat,
    String? streetArea,
    String? city,
    String? province,
    String? postalCode,
    String? landmark,
    String? country,
    bool? isDefault,
    String? street,
    String? state,
    String? zipCode,
  }) {
    return Address(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      houseFlat: houseFlat ?? this.houseFlat,
      streetArea: streetArea ?? this.streetArea,
      city: city ?? this.city,
      province: province ?? this.province,
      postalCode: postalCode ?? this.postalCode,
      landmark: landmark ?? this.landmark,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      street: street ?? _legacyStreet,
      state: state ?? _legacyState,
      zipCode: zipCode ?? _legacyZipCode,
    );
  }
}

// Realistic Pakistani Initial Demo Addresses
const List<Address> defaultPakistaniAddresses = [
  Address(
    id: 'addr_bwp_01',
    name: 'Umair',
    phone: '+92 301 7894561',
    houseFlat: 'House 42-A, Street 3',
    streetArea: 'Model Town A',
    city: 'Bahawalpur',
    province: 'Punjab',
    postalCode: '63100',
    landmark: 'Near Victoria Hospital',
    country: 'Pakistan',
    isDefault: true,
  ),
  Address(
    id: 'addr_lhr_02',
    name: 'Umair (Lahore Office)',
    phone: '+92 300 1234567',
    houseFlat: 'Plot 18, Block B-3',
    streetArea: 'M.M. Alam Road, Gulberg III',
    city: 'Lahore',
    province: 'Punjab',
    postalCode: '54660',
    landmark: 'Behind Packages Mall',
    country: 'Pakistan',
    isDefault: false,
  ),
  Address(
    id: 'addr_isb_03',
    name: 'Umair (Islamabad Residence)',
    phone: '+92 333 5556677',
    houseFlat: 'House 14-B, Street 5',
    streetArea: 'Sector F-7/2',
    city: 'Islamabad',
    province: 'ICT',
    postalCode: '44000',
    landmark: 'Near Jinnah Super Market',
    country: 'Pakistan',
    isDefault: false,
  ),
];
