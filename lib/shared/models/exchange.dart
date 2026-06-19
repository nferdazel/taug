import 'package:equatable/equatable.dart';

final class Exchange extends Equatable {
  final int id;
  final String code;
  final String name;
  final String country;
  final String timezone;
  final String currency;
  final String? marketOpen;
  final String? marketClose;
  final bool isActive;

  const Exchange({
    required this.id,
    required this.code,
    required this.name,
    required this.country,
    required this.timezone,
    required this.currency,
    this.marketOpen,
    this.marketClose,
    this.isActive = true,
  });

  factory Exchange.fromJson(Map<String, dynamic> json) {
    return Exchange(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      country: json['country'] as String? ?? '',
      timezone: json['timezone'] as String? ?? 'UTC',
      currency: json['currency'] as String? ?? 'USD',
      marketOpen: json['market_open'] as String?,
      marketClose: json['market_close'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'country': country,
      'timezone': timezone,
      'currency': currency,
      'market_open': marketOpen,
      'market_close': marketClose,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        code,
        name,
        country,
        timezone,
        currency,
        marketOpen,
        marketClose,
        isActive,
      ];
}
