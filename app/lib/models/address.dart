class Address {
  final int? id;
  final String label;
  final String fullName;
  final String street;
  final String number;
  final String? details;
  final String city;
  final String postalCode;
  final String country;
  final String phone;
  final bool isDefault;

  const Address({
    this.id,
    required this.label,
    required this.fullName,
    required this.street,
    required this.number,
    this.details,
    required this.city,
    required this.postalCode,
    required this.country,
    required this.phone,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) => Address(
        id: json['id'] as int?,
        label: json['label'] as String? ?? '',
        fullName: json['full_name'] as String? ?? '',
        street: json['street'] as String? ?? '',
        number: json['number'] as String? ?? '',
        details: json['details'] as String?,
        city: json['city'] as String? ?? '',
        postalCode: json['postal_code'] as String? ?? '',
        country: json['country'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        isDefault: json['is_default'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'full_name': fullName,
        'street': street,
        'number': number,
        if (details != null) 'details': details,
        'city': city,
        'postal_code': postalCode,
        'country': country,
        'phone': phone,
      };

  Address copyWith({bool? isDefault}) => Address(
        id: id,
        label: label,
        fullName: fullName,
        street: street,
        number: number,
        details: details,
        city: city,
        postalCode: postalCode,
        country: country,
        phone: phone,
        isDefault: isDefault ?? this.isDefault,
      );
}
