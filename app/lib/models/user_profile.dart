import 'package:flutter/material.dart';

class UserProfile {
  final String id;
  final String name;
  final String handle;
  final String location;
  final String role;
  final List<String> specialties;
  final int pieceCount;
  final int soldCount;
  final int followerCount;
  final bool verified;
  final Color avatarColor;
  final Color bannerColor;
  final String bio;

  const UserProfile({
    required this.id,
    required this.name,
    required this.handle,
    required this.location,
    required this.role,
    required this.specialties,
    required this.pieceCount,
    required this.soldCount,
    required this.followerCount,
    required this.verified,
    required this.avatarColor,
    required this.bannerColor,
    this.bio = '',
  });
}

UserProfile? findProfileByName(String name) =>
    mockUserProfiles.where((p) => p.name == name).firstOrNull;

UserProfile findProfileById(String id) =>
    mockUserProfiles.firstWhere((p) => p.id == id);

const mockUserProfiles = <UserProfile>[
  // ── Designers from mockProducts ────────────────────────────
  UserProfile(
    id: 'marta-sala',
    name: 'Marta Sala',
    handle: '@martasala',
    location: 'Barcelona, ES',
    role: 'Ceramic artist',
    specialties: ['Ceramic', 'Sculpture'],
    pieceCount: 19,
    soldCount: 12,
    followerCount: 1640,
    verified: true,
    avatarColor: Color(0xFFBEB0A0),
    bannerColor: Color(0xFFA89888),
    bio: 'Barcelona-based ceramic artist working with stoneware and '
        'Mediterranean earth tones. Each piece is hand-thrown, embracing '
        'the beauty of asymmetry and the subtle imperfections of the '
        'handmade process. Studio visits by appointment.',
  ),
  UserProfile(
    id: 'atelier-nm',
    name: 'Atelier NM',
    handle: '@ateliernm',
    location: 'Madrid, ES',
    role: 'Furniture studio',
    specialties: ['Furniture', 'Textiles'],
    pieceCount: 34,
    soldCount: 21,
    followerCount: 2870,
    verified: true,
    avatarColor: Color(0xFFCBC2B4),
    bannerColor: Color(0xFFB5A898),
    bio: 'A Madrid-based design studio focused on slow furniture — pieces '
        'built to last, crafted from natural materials. We believe in '
        'honest construction, removable covers, and designs that age '
        'with grace.',
  ),
  UserProfile(
    id: 'studio-vera',
    name: 'Studio Vèra',
    handle: '@studiovera',
    location: 'Valencia, ES',
    role: 'Lighting designer',
    specialties: ['Lighting', 'Decor'],
    pieceCount: 27,
    soldCount: 18,
    followerCount: 3210,
    verified: true,
    avatarColor: Color(0xFFA8997E),
    bannerColor: Color(0xFF8A7D6A),
    bio: 'Sculptural lighting and decorative objects from Valencia. '
        'Every lamp is cast using lost-wax technique, finished by hand, '
        'and paired with natural linen shades. Light as atmosphere.',
  ),
  UserProfile(
    id: 'jordi-canudas',
    name: 'Jordi Canudas',
    handle: '@jcanudas',
    location: 'Girona, ES',
    role: 'Furniture designer',
    specialties: ['Furniture', 'Sculpture'],
    pieceCount: 11,
    soldCount: 7,
    followerCount: 890,
    verified: false,
    avatarColor: Color(0xFF9A8C7B),
    bannerColor: Color(0xFFBAAD9A),
    bio: 'Minimal furniture in solid wood, designed in Girona. '
        'Precision joinery, no visible hardware, no unnecessary detail. '
        'Objects made to age gracefully alongside the things they hold.',
  ),
  UserProfile(
    id: 'clara-boj',
    name: 'Clara Boj',
    handle: '@claraboj',
    location: 'Barcelona, ES',
    role: 'Ceramic artist',
    specialties: ['Ceramic', 'Painting'],
    pieceCount: 23,
    soldCount: 15,
    followerCount: 1450,
    verified: true,
    avatarColor: Color(0xFFD0C5B5),
    bannerColor: Color(0xFFB8AB99),
    bio: 'Reactive glazes, wide forms, and soft tonal variations. '
        'Working from a shared studio in the Poblenou district of Barcelona. '
        'Food-safe, dishwasher-friendly, made to be used every day.',
  ),
  UserProfile(
    id: 'teixidors',
    name: 'Teixidors',
    handle: '@teixidors',
    location: 'Terrassa, ES',
    role: 'Textile workshop',
    specialties: ['Textiles', 'Decor', 'Furniture'],
    pieceCount: 42,
    soldCount: 31,
    followerCount: 5620,
    verified: true,
    avatarColor: Color(0xFFC5B9A5),
    bannerColor: Color(0xFFAEA08C),
    bio: 'A social workshop in Terrassa, hand-weaving merino wool and '
        'cashmere on traditional looms since 1983. Soft, breathable, '
        'and finished with care. Every throw tells a story of craft '
        'and community.',
  ),
  UserProfile(
    id: 'viabizzuno',
    name: 'Viabizzuno',
    handle: '@viabizzuno',
    location: 'Milan, IT',
    role: 'Lighting studio',
    specialties: ['Lighting', 'Sculpture'],
    pieceCount: 56,
    soldCount: 39,
    followerCount: 8340,
    verified: true,
    avatarColor: Color(0xFFB3A594),
    bannerColor: Color(0xFF9E9080),
    bio: 'Mouth-blown glass and brushed brass, designed in Milan. '
        'Translucent amber tones that cast warm, diffused light. '
        'Each pendant is a small act of patience and precision.',
  ),
  UserProfile(
    id: 'apparatu',
    name: 'Apparatu',
    handle: '@apparatu',
    location: 'Seville, ES',
    role: 'Ceramic studio',
    specialties: ['Ceramic', 'Decor'],
    pieceCount: 15,
    soldCount: 8,
    followerCount: 720,
    verified: false,
    avatarColor: Color(0xFFCABEAE),
    bannerColor: Color(0xFFB0A492),
    bio: 'Hand-painted terracotta inspired by pre-industrial Mediterranean '
        'pottery traditions. Organic forms, earthy pigments, and a deep '
        'respect for the slow rhythms of the kiln.',
  ),

  // ── Search-only users ──────────────────────────────────────
  UserProfile(
    id: 'elena-marti',
    name: 'Elena Martí',
    handle: '@elenamarti',
    location: 'Barcelona, ES',
    role: 'Ceramic artist',
    specialties: ['Ceramic', 'Art'],
    pieceCount: 8,
    soldCount: 3,
    followerCount: 410,
    verified: false,
    avatarColor: Color(0xFFB8543C),
    bannerColor: Color(0xFFA04530),
    bio: 'Emerging ceramic artist exploring the intersection of traditional '
        'technique and contemporary form. Based in the Sant Andreu '
        'neighbourhood of Barcelona.',
  ),
  UserProfile(
    id: 'pau-vives',
    name: 'Pau Vives',
    handle: '@pauvives',
    location: 'Valencia, ES',
    role: 'Textile designer',
    specialties: ['Textiles', 'Painting'],
    pieceCount: 6,
    soldCount: 2,
    followerCount: 280,
    verified: false,
    avatarColor: Color(0xFF9A8C7B),
    bannerColor: Color(0xFF7A6C5B),
    bio: 'Natural dyes, hand-woven textiles, and painted fabric from '
        'a small workshop in the Cabanyal district of Valencia.',
  ),
  UserProfile(
    id: 'laia-font',
    name: 'Laia Font',
    handle: '@laiafont',
    location: 'Madrid, ES',
    role: 'Interior architect',
    specialties: ['Furniture', 'Lighting', 'Decor'],
    pieceCount: 31,
    soldCount: 22,
    followerCount: 3890,
    verified: true,
    avatarColor: Color(0xFF2E2520),
    bannerColor: Color(0xFF4A3F38),
    bio: 'Interior architect curating and designing functional objects '
        'for considered living spaces. Based in Madrid, working across '
        'furniture, lighting, and decorative accessories.',
  ),
  UserProfile(
    id: 'nuria-coll',
    name: 'Nuria Coll',
    handle: '@nuriacoll',
    location: 'Seville, ES',
    role: 'Curator',
    specialties: ['Art', 'Curation'],
    pieceCount: 0,
    soldCount: 0,
    followerCount: 1200,
    verified: false,
    avatarColor: Color(0xFFB3A594),
    bannerColor: Color(0xFF9E9080),
    bio: 'Independent curator and writer based in Seville, specialising '
        'in contemporary craft and design from the Mediterranean region.',
  ),
  UserProfile(
    id: 'marc-esteve',
    name: 'Marc Esteve',
    handle: '@marcesteve',
    location: 'Terrassa, ES',
    role: 'Sculptor',
    specialties: ['Sculpture', 'Ceramic'],
    pieceCount: 14,
    soldCount: 9,
    followerCount: 960,
    verified: false,
    avatarColor: Color(0xFF8A7D6A),
    bannerColor: Color(0xFF6A5D4A),
    bio: 'Stone and ceramic sculptor working from a converted industrial '
        'space in Terrassa. Large-scale commissions and intimate objects.',
  ),
  UserProfile(
    id: 'anna-riera',
    name: 'Anna Riera',
    handle: '@annariera',
    location: 'Milan, IT',
    role: 'Lighting designer',
    specialties: ['Lighting', 'Glass'],
    pieceCount: 18,
    soldCount: 11,
    followerCount: 2140,
    verified: true,
    avatarColor: Color(0xFFC2B5A2),
    bannerColor: Color(0xFFA89888),
    bio: 'Glass and brass lighting designed between Milan and Murano. '
        'Every piece begins as a sketch, becomes a mould, and ends '
        'as light.',
  ),
];
