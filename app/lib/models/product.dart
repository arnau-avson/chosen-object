import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String designer;
  final String price;
  final String tag; // 'Sell', 'Buy', 'Rent', 'Buy or Rent'
  final String year;
  final List<Color> images; // placeholder colors (will become URLs)
  final String description;
  final String? category;
  final String? condition;
  final String? materials;
  final String? dimensions;
  final String? location;
  final String? edition; // e.g. 'AP 2 / 4'
  final String? suite; // e.g. 'Suite Verano'
  final String? weight;
  final List<String> tags; // e.g. ['Contemporary', 'Mediterranean']
  final bool verified;
  final String? oldPrice; // previous price for strikethrough display
  final int stock; // not shown to buyers
  final String? costPrice; // cost price for margin calc — never shown to buyers

  const Product({
    required this.id,
    required this.name,
    required this.designer,
    required this.price,
    required this.tag,
    required this.year,
    required this.images,
    this.description = '',
    this.category,
    this.condition,
    this.materials,
    this.dimensions,
    this.location,
    this.edition,
    this.suite,
    this.weight,
    this.tags = const [],
    this.verified = false,
    this.oldPrice,
    this.stock = 1,
    this.costPrice,
  });
}

final mockProducts = <Product>[
  Product(
    id: 'curved-vessel',
    name: 'Curved Vessel',
    designer: 'Marta Sala',
    price: '€340',
    tag: 'Sell',
    year: '2024',
    images: [Color(0xFFBEB0A0), Color(0xFFA89888), Color(0xFFD4C8B8)],
    description:
        'A hand-thrown stoneware vessel with a gentle asymmetric curve. '
        'Finished with a warm matte glaze inspired by Mediterranean earth tones. '
        'Each piece is unique due to the handmade process.',
    category: 'Ceramic',
    condition: 'New',
    materials: 'Stoneware · Matte glaze',
    dimensions: 'H 28 × Ø 18 cm',
    weight: '1.2 kg',
    location: 'Barcelona, ES',
    edition: '1 / 12',
    suite: 'Suite Mediterráneo',
    tags: ['Contemporary', 'Mediterranean', 'Handmade', 'Ceramic'],
    verified: true,
    costPrice: '€180',
  ),
  Product(
    id: 'linen-armchair',
    name: 'Linen Armchair',
    designer: 'Atelier NM',
    price: '€1,200',
    tag: 'Buy or Rent',
    year: '2025',
    images: [Color(0xFFCBC2B4), Color(0xFFB5A898)],
    description:
        'A solid oak frame armchair upholstered in natural Belgian linen. '
        'Designed for slow living — deep seat, low back, effortless comfort. '
        'Removable cover for easy care.',
    category: 'Furniture',
    condition: 'Like new',
    materials: 'Oak · Linen',
    dimensions: 'H 78 × W 72 × D 70 cm',
    weight: '14 kg',
    location: 'Madrid, ES',
    tags: ['Contemporary', 'Minimalist', 'Furniture'],
    verified: true,
    costPrice: '€650',
  ),
  Product(
    id: 'bronze-table-lamp',
    name: 'Bronze Table Lamp',
    designer: 'Studio Vèra',
    price: '€480',
    tag: 'Sell',
    year: '2023',
    images: [Color(0xFFA8997E), Color(0xFFC2B5A2), Color(0xFF8A7D6A)],
    description:
        'A sculptural table lamp in patinated brass with a hand-sewn linen shade. '
        'The base is cast using a lost-wax technique, giving each lamp subtle surface variations.',
    category: 'Lighting',
    condition: 'New',
    materials: 'Brass · Linen shade',
    dimensions: 'H 42 × Ø 22 cm',
    weight: '2.8 kg',
    location: 'Valencia, ES',
    edition: 'AP 3 / 8',
    suite: 'Suite Verano',
    tags: ['Mid-century', 'Sculptural', 'Lighting'],
    verified: true,
    costPrice: '€220',
  ),
  Product(
    id: 'walnut-side-table',
    name: 'Walnut Side Table',
    designer: 'Jordi Canudas',
    price: '€720',
    tag: 'Rent',
    year: '2026',
    images: [Color(0xFF9A8C7B), Color(0xFFBAAD9A)],
    description:
        'A minimal side table in solid walnut with hand-oiled finish. '
        'Precision joinery, no visible hardware. '
        'Designed to age gracefully alongside the objects it holds.',
    category: 'Furniture',
    condition: 'New',
    materials: 'Solid walnut',
    dimensions: 'H 52 × W 45 × D 45 cm',
    weight: '6.5 kg',
    location: 'Girona, ES',
    tags: ['Minimalist', 'Nordic', 'Furniture'],
    verified: false,
    costPrice: '€340',
  ),
  Product(
    id: 'stoneware-bowl',
    name: 'Stoneware Bowl',
    designer: 'Clara Boj',
    price: '€190',
    tag: 'Buy',
    year: '2025',
    images: [Color(0xFFD0C5B5), Color(0xFFB8AB99), Color(0xFFE0D6C4)],
    description:
        'A wide stoneware bowl with a reactive glaze that pools in soft tonal variations. '
        'Perfect as a centrepiece or for everyday use. '
        'Food-safe and dishwasher-friendly.',
    category: 'Ceramic',
    condition: 'New',
    materials: 'Stoneware · Reactive glaze',
    dimensions: 'H 12 × Ø 24 cm',
    weight: '0.9 kg',
    location: 'Barcelona, ES',
    edition: '5 / 20',
    tags: ['Contemporary', 'Handmade', 'Ceramic'],
    verified: true,
    costPrice: '€60',
  ),
  Product(
    id: 'woven-throw',
    name: 'Woven Throw',
    designer: 'Teixidors',
    price: '€260',
    tag: 'Buy or Rent',
    year: '2024',
    images: [Color(0xFFC5B9A5), Color(0xFFAEA08C)],
    description:
        'A merino wool and cashmere blend throw, hand-woven on traditional looms. '
        'Soft, breathable, and finished with a delicate fringe detail. '
        'Made in a social workshop in Terrassa.',
    category: 'Textiles',
    condition: 'New',
    materials: 'Merino wool · Cashmere',
    dimensions: '180 × 130 cm',
    weight: '0.4 kg',
    location: 'Terrassa, ES',
    tags: ['Artisanal', 'Mediterranean', 'Textiles'],
    verified: true,
    costPrice: '€110',
  ),
  Product(
    id: 'glass-pendant',
    name: 'Glass Pendant',
    designer: 'Viabizzuno',
    price: '€560',
    tag: 'Sell',
    year: '2026',
    images: [Color(0xFFB3A594), Color(0xFFD6CCC0), Color(0xFF9E9080)],
    description:
        'A mouth-blown glass pendant light with a brushed brass canopy. '
        'The translucent amber glass casts a warm, diffused glow. '
        'Includes 2 m fabric cable and ceiling rose.',
    category: 'Lighting',
    condition: 'New',
    materials: 'Mouth-blown glass · Brass',
    dimensions: 'H 30 × Ø 25 cm',
    weight: '1.5 kg',
    location: 'Milan, IT',
    edition: 'AP 1 / 6',
    tags: ['Contemporary', 'Italian', 'Lighting'],
    verified: true,
    costPrice: '€280',
  ),
  Product(
    id: 'ceramic-vase',
    name: 'Ceramic Vase',
    designer: 'Apparatu',
    price: '€280',
    tag: 'Rent',
    year: '2023',
    images: [Color(0xFFCABEAE), Color(0xFFB0A492)],
    description:
        'A hand-painted terracotta vase with organic forms and earthy pigments. '
        'Inspired by pre-industrial Mediterranean pottery traditions. '
        'Not watertight — use with a glass insert for fresh flowers.',
    category: 'Ceramic',
    condition: 'Vintage',
    materials: 'Terracotta · Hand-painted',
    dimensions: 'H 35 × Ø 16 cm',
    weight: '2.1 kg',
    location: 'Seville, ES',
    suite: 'Suite Andalucía',
    tags: ['Vintage', 'Mediterranean', 'Ceramic'],
    verified: false,
    costPrice: '€90',
  ),
];
