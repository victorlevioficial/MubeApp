// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../../constants/app_constants.dart' as app_constants;
import '../../constants/firestore_constants.dart';
import '../../features/auth/domain/user_type.dart';
import '../domain/app_config.dart';
import 'app_config_repository.dart';

part 'app_seeder.g.dart';

/// Data seeder for generating 150+ realistic, diverse test profiles in Firestore.
///
/// Creates:
/// - Professionals (60%): Multiple categories (Cantor, Instrumentista, Crew, DJ)
/// - Bands (25%): Various genres and looking-for configurations
/// - Studios (15%): Recording, Rehearsal, Mastering studios
///
/// All profiles are located in Rio de Janeiro with unique photos and rich bios in Portuguese.
class AppSeeder {
  AppSeeder(this._firestore, this._configRepo);

  final FirebaseFirestore _firestore;
  final AppConfigRepository _configRepo;
  final _random = Random();
  final _uuid = const Uuid();

  // ============================================================================
  // PHOTO URLs - 160+ unique musician/studio photos from Unsplash
  // ============================================================================
  static const _photoUrls = [
    // Musicians / Performance (60 photos)
    'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1516924962500-2b4b3b99ea02?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1524650359799-842906ca1c06?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1501612780327-45045538702b?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1594623930572-300a3011d9ae?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1465847899084-d164df4dedc6?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1485579149621-3123dd979885?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1571974599782-87624638275e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1558584674-ab74f5f4c839?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1544428256-f2e1b0a87f09?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1526142684086-7ebd69df27a5?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1460723237483-7a6dc9d0b212?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1507838153414-b4b713384a76?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1415201364774-f6f0bb35f28f?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1574154894072-16a2f0cc4e1a?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1493676304819-0d7a8d026dcf?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1518609878373-06d740f60d8b?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1525201548942-d8732f6617a0?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1511192336575-5a79af67a629?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1488376739361-ed24c9beb6d0?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1499415479124-43c32433a620?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1504898770365-14faca6a7320?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1571115764595-644a1f56a55c?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1446057032654-9d8885db76c6?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1519892300165-cb5542fb47c7?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1484876065684-b683cf17d276?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1558618666-fcd25c85cd64?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1576514129883-2f31a88cf9ef?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1549834125-82d3c48159a3?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1511367461989-f85a21fda167?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1487180144351-b8472da7d491?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1535712593684-0efd191312bb?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1453396450673-3fe83d714f8c?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1460661419201-fd4cecdf8a8b?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1506091850677-f8b0d860d64e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1528980917907-8df7f48f6f2a?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1559825481-12a05cc00344?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1552422535-c45813c61732?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1518911710364-17ec553bde5d?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1483412033650-1015ddeb83d1?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1517230878791-4d28214057c2?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400&h=400&fit=crop',
    // Bands / Groups (30 photos)
    'https://images.unsplash.com/photo-1429962714451-bb934ecdc4ec?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1524368535928-5b5e00ddc76b?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1540039155733-5bb30b53aa14?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1506157786151-b8491531f063?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1501612780327-45045538702b?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1574391884720-bbc3740c59d1?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1598387181032-a3103a2db5b3?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1468164016595-6108e4c60c8b?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1499364615650-ec38552f4f34?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1454908027598-28c44b1716c1?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1561489401-fc2876ced162?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1533174072545-7a4b6ad7a6c3?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1566981731417-d4c8e17a9e82?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1542751371-adc38448a05e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1561489396-888724a1543d?w=400&h=400&fit=crop',
    // 404 fixed
    'https://images.unsplash.com/photo-1510915361894-db8b60106cb1?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1509824227185-9c5a01ceba0d?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1525362081669-2b476bb628c3?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1556379068-7a939ee1fa2c?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1571974599782-87624638275e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1485579149621-3123dd979885?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1504680177321-2e6a879aac86?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1598387993281-cecf8b71a8f8?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1522158637959-30385a09e0da?w=400&h=400&fit=crop',
    // Studios / Recording (40 photos)
    'https://images.unsplash.com/photo-1598653222000-6b7b7a552625?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1598520106830-8c45c2035460?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1619983081563-430f63602796?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1610041321327-b794c052db27?w=400&h=400&fit=crop',
    // 404 fixed
    'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1567596275753-92607c3c5774?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1571327073757-71d13c24de30?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1574154894072-16a2f0cc4e1a?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1519683384663-a1155f6f8bce?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1598387993281-cecf8b71a8f8?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1603794067602-9feaa4f70e0c?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1544391051-2e256e847bfc?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1556379068-7a939ee1fa2c?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1555086156-e6c7353d283f?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=400&fit=crop',
    // Extra diverse portraits (20 photos)
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1519456264917-42d0aa2e0625?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1560250097-0b93528c311a?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1573497019940-1c28c88b4f3e?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1580489944761-15a19d654956?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1599566150163-29194dcabd36?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1552058544-f2b08422138a?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1548142813-c348350df52b?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1543610892-0b1f7e6d8ac1?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1557862921-37829c790f19?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1522529599102-193c0d76b5b6?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1504257432389-52343af06ae3?w=400&h=400&fit=crop',
    'https://images.unsplash.com/photo-1521119989659-a83eee488004?w=400&h=400&fit=crop',
  ];

  // ============================================================================
  // HASHTAGS BY GENRE (Portuguese-focused)
  // ============================================================================
  static const _hashtagsByGenre = {
    'rock': [
      '#classicrock',
      '#grunge',
      '#alternativerock',
      '#hardrock',
      '#indierock',
      '#punkrock',
      '#cover',
      '#bandcover',
      '#rockbrasil',
      '#rocknacional',
      '#rockband',
      '#guitarrista',
      '#riffs',
    ],
    'jazz': [
      '#jazzmusic',
      '#bebop',
      '#smoothjazz',
      '#jazzfusion',
      '#jazzstandards',
      '#improvisation',
      '#jazzclub',
      '#bossanova',
      '#cooljazz',
      '#jazzrio',
      '#saxofone',
      '#jazzpiano',
    ],
    'metal': [
      '#heavymetal',
      '#deathmetal',
      '#thrashmetal',
      '#blackmetal',
      '#metalcore',
      '#progressivemetal',
      '#powermetal',
      '#groovemetal',
      '#metalbrasil',
      '#metalhead',
      '#headbanger',
    ],
    'pop': [
      '#popmusic',
      '#indiepop',
      '#synthpop',
      '#electropop',
      '#dancepop',
      '#popbrasil',
      '#hitmaker',
      '#vocalpop',
      '#pophits',
      '#modernpop',
      '#songwriter',
      '#poprock',
    ],
    'samba': [
      '#samba',
      '#sambarock',
      '#pagode',
      '#rodadesamba',
      '#sambacarioca',
      '#boteco',
      '#feijoada',
      '#carnaval',
      '#partidoalto',
      '#cavaquinho',
      '#pandeiro',
    ],
    'pagode': [
      '#pagode',
      '#pagode90',
      '#pagodão',
      '#grupodepagode',
      '#pagodebrasil',
      '#tantã',
      '#repique',
      '#surdopagode',
      '#vozdopagode',
      '#pagoderaiz',
    ],
    'sertanejo': [
      '#sertanejo',
      '#sertanejoraiz',
      '#sertanejouniversitario',
      '#modão',
      '#violacaipira',
      '#duplacaipira',
      '#brasilsertanejo',
      '#musicasertaneja',
    ],
    'eletronica': [
      '#edm',
      '#housemusic',
      '#techno',
      '#trance',
      '#dubstep',
      '#drumandbass',
      '#electronica',
      '#ambient',
      '#synthwave',
      '#djlife',
      '#producer',
      '#ableton',
    ],
    'mpb': [
      '#mpb',
      '#musicabrasileira',
      '#bossanova',
      '#tropicalia',
      '#chorinho',
      '#violãobrasil',
      '#vozeviolão',
      '#cantorbrasileiro',
      '#compositorbrasileiro',
    ],
    'blues': [
      '#bluesmusic',
      '#bluesguitar',
      '#deltablues',
      '#chicagoblues',
      '#bluesrock',
      '#electricblues',
      '#acousticblues',
      '#slideweiter',
      '#harmonica',
    ],
    'funk': [
      '#funk',
      '#funkcarioca',
      '#funkbrasil',
      '#bailefunk',
      '#djfunk',
      '#mcdofunk',
      '#funkmelody',
      '#funkwave',
    ],
    'hip_hop': [
      '#hiphop',
      '#rap',
      '#rapnacional',
      '#rapbrasil',
      '#freestyle',
      '#beatmaker',
      '#trapbrasil',
      '#mcbrasil',
      '#rimador',
      '#flowlivre',
    ],
    'gospel': [
      '#gospel',
      '#musicagospel',
      '#louvor',
      '#adoração',
      '#ministeriodelouvor',
      '#igrejacantando',
      '#gospelbrasil',
      '#cantorgospel',
    ],
    'reggae': [
      '#reggae',
      '#reggaebrasil',
      '#roots',
      '#onelove',
      '#jamaicanbrazil',
      '#dub',
      '#reggaemusic',
      '#rastafari',
    ],
    'forro': [
      '#forró',
      '#forródasantigas',
      '#xote',
      '#baião',
      '#triangulo',
      '#zabumba',
      '#sanfonaelétrica',
      '#pédeserra',
    ],
  };

  static const _genericHashtags = [
    '#autoral',
    '#cover',
    '#bandacover',
    '#showsaovivo',
    '#ensaio',
    '#estúdio',
    '#gravação',
    '#musicaindependente',
    '#artistaindependente',
    '#musicoprofissional',
    '#aovivo',
    '#palco',
    '#tournacional',
    '#festivalmusica',
    '#openmic',
    '#jamnight',
    '#colaboração',
    '#parceriamusical',
    '#compositores',
    '#letrista',
    '#produçãomusical',
    '#homerecording',
    '#musicario',
    '#musicacarioca',
  ];

  // ============================================================================
  // BRAZILIAN NAMES
  // ============================================================================
  static const _firstNames = [
    'João',
    'Maria',
    'Pedro',
    'Ana',
    'Lucas',
    'Juliana',
    'Gabriel',
    'Fernanda',
    'Rafael',
    'Camila',
    'Matheus',
    'Larissa',
    'Thiago',
    'Beatriz',
    'Gustavo',
    'Amanda',
    'Bruno',
    'Letícia',
    'Felipe',
    'Carolina',
    'Diego',
    'Mariana',
    'André',
    'Priscila',
    'Vinícius',
    'Gabriela',
    'Rodrigo',
    'Vanessa',
    'Leonardo',
    'Natália',
    'Marcelo',
    'Isabela',
    'Ricardo',
    'Aline',
    'Eduardo',
    'Renata',
    'Fábio',
    'Patrícia',
    'Caio',
    'Débora',
    'Daniel',
    'Monique',
    'Murilo',
    'Bianca',
    'Leandro',
    'Stephanie',
    'Alex',
    'Jéssica',
    'Henrique',
    'Tatiana',
  ];
  static const _lastNames = [
    'Silva',
    'Santos',
    'Oliveira',
    'Souza',
    'Rodrigues',
    'Ferreira',
    'Alves',
    'Pereira',
    'Lima',
    'Gomes',
    'Costa',
    'Ribeiro',
    'Martins',
    'Carvalho',
    'Almeida',
    'Lopes',
    'Soares',
    'Fernandes',
    'Vieira',
    'Barbosa',
    'Rocha',
    'Dias',
    'Nascimento',
    'Andrade',
    'Moreira',
    'Nunes',
    'Marques',
    'Machado',
    'Mendes',
    'Freitas',
  ];

  // ============================================================================
  // BAND NAME COMPONENTS
  // ============================================================================
  static const _bandPrefixes = [
    'Os',
    'As',
    'Banda',
    'Projeto',
    'Coletivo',
    'Quarteto',
    'Trio',
    'Duo',
    '',
  ];
  static const _bandMiddles = [
    'Cariocas',
    'Underground',
    'Rebeldes',
    'Selvagens',
    'Elétricos',
    'Acústicos',
    'Urbanos',
    'Tropicais',
    'Noturnos',
    'Eternos',
    'Loucos',
    'Sonhadores',
    'Viajantes',
    'Místicos',
    'Barulhentos',
    'Silenciosos',
  ];
  static const _bandSuffixes = [
    'Rock',
    'Soul',
    'Beats',
    'Sound',
    'Groove',
    'Vibes',
    'Blues',
    'Jazz',
    'Crew',
    'Union',
    'Express',
    'Session',
    'Connection',
    'Experience',
    'Project',
    '',
  ];

  // ============================================================================
  // STUDIO NAME COMPONENTS
  // ============================================================================
  static const _studioNames = [
    'Studio A1',
    'SoundWave Studio',
    'Estúdio Carioca',
    'Music Factory RJ',
    'Sala de Ensaio Rio',
    'Bunker Sound',
    'Studio 21',
    'Estúdio Zona Sul',
    'Recording House',
    'Pro Sound Studio',
    'Estúdio Mozart',
    'Audio Lab RJ',
    'The Recording Room',
    'Estúdio Central',
    'HitMaker Studio',
    'Estúdio Tijuca',
    'Sound Temple',
    'Garage Studio RJ',
    'Estúdio Laranjeiras',
    'MasterClass Audio',
    'Estúdio Profissional',
    'SoundBox RJ',
    'Estúdio Lapa',
    'Urban Sound Studio',
    'Estúdio Botafogo',
  ];

  // ============================================================================
  // BIO TEMPLATES (Portuguese)
  // ============================================================================
  // Professional Bios by Category
  static const _bioTemplatesCantor = [
    '🎤 Cantor(a) de {{genre}} há {{years}} anos. Voz é minha vida!',
    '🎵 {{years}} anos cantando {{genre}}. Disponível para shows e gravações.',
    '🎤 Cantor(a) profissional, especialista em {{genre}}. Bora fazer som!',
    '✨ Vocalista apaixonado(a) por {{genre}}. {{years}} anos de experiência no Rio.',
    '🎙️ Backing vocal e voz principal. {{genre}} é meu estilo. Procuro banda!',
  ];
  static const _bioTemplatesInstrumentista = [
    '🎸 {{instrument}} de {{genre}}. {{years}} anos de experiência em shows e estúdio.',
    '🎹 {{instrument}} versátil, mas meu coração é {{genre}}. Procurando banda fixa.',
    '🥁 {{instrument}} profissional. {{years}} anos de estrada. Bora tocar!',
    '🎺 Músico de {{genre}} há {{years}} anos. Já toquei em vários palcos do Rio.',
    '🎻 {{instrument}} com {{years}} anos de experiência. Disponível para projetos!',
  ];
  static const _bioTemplatesCrew = [
    '🔧 {{role}} profissional. Trabalhando com música há {{years}} anos.',
    '🎛️ {{role}} experiente. Já trabalhei com bandas de {{genre}} do Rio.',
    '📹 {{role}} com {{years}} anos de carreira. Disponível para eventos e shows.',
    '🔊 {{role}} técnico. {{genre}} é minha especialidade. Vamos trabalhar juntos!',
    '🎬 {{role}} dedicado(a). {{years}} anos de experiência no mercado musical.',
  ];
  static const _bioTemplatesDJ = [
    '🎧 DJ de {{genre}} há {{years}} anos. Festas, eventos e sets ao vivo.',
    '💿 Producer e DJ. {{genre}} é meu estilo. Disponível para eventos no Rio.',
    '🎛️ DJ profissional com {{years}} anos de experiência. EDM, {{genre}} e mais.',
    '🔊 DJ e Produtor. Criando beats de {{genre}} há {{years}} anos.',
    '🎵 DJ versátil. De {{genre}} a eletrônico. {{years}} anos na cena carioca.',
  ];
  // Band Bios
  static const _bioTemplatesBand = [
    '🎸 Banda de {{genre}} do Rio! Procurando {{role}} para completar a formação.',
    '🎤 Projeto de {{genre}} em busca de {{role}}. Ensaios na Zona Sul.',
    '🎵 {{genre}} autoral. Temos {{members}} integrantes, falta você!',
    '🔥 Banda cover de {{genre}} com {{members}} membros. Bora tocar?',
    '🎹 Projeto musical de {{genre}}. Procurando {{role}} comprometido.',
    '🥁 Banda em formação. Estilo: {{genre}}. Objetivo: shows e gravações.',
    '🎺 Grupo de {{genre}} do Rio procurando novos talentos.',
    '🎸 {{genre}} com influências diversas. Buscando {{role}} para ensaios.',
  ];
  // Studio Bios
  static const _bioTemplatesStudio = [
    '🎙️ Estúdio de {{service}} no Rio de Janeiro. Equipamento profissional!',
    '🎛️ {{service}} profissional. Atendemos bandas, cantores e produtores.',
    '🎚️ Estúdio completo para {{service}}. Preços acessíveis na Zona Sul.',
    '🔊 {{service}} de alta qualidade. Ambiente climatizado e isolamento acústico.',
    '🎵 Oferecemos {{service}} com engenheiros experientes. Agende sua sessão!',
    '🎧 Estúdio profissional para {{service}}. Equipamento de ponta e ótima acústica.',
  ];

  // ============================================================================
  // RIO DE JANEIRO NEIGHBORHOODS
  // ============================================================================
  static const _rjNeighborhoods = [
    {'name': 'Copacabana', 'lat': -22.9711, 'lng': -43.1822},
    {'name': 'Ipanema', 'lat': -22.9838, 'lng': -43.2045},
    {'name': 'Leblon', 'lat': -22.9852, 'lng': -43.2232},
    {'name': 'Botafogo', 'lat': -22.9512, 'lng': -43.1852},
    {'name': 'Lapa', 'lat': -22.9112, 'lng': -43.1806},
    {'name': 'Centro', 'lat': -22.9068, 'lng': -43.1729},
    {'name': 'Tijuca', 'lat': -22.9325, 'lng': -43.2436},
    {'name': 'Barra da Tijuca', 'lat': -23.0003, 'lng': -43.3659},
    {'name': 'Santa Teresa', 'lat': -22.9221, 'lng': -43.1864},
    {'name': 'Flamengo', 'lat': -22.9346, 'lng': -43.1759},
    {'name': 'Laranjeiras', 'lat': -22.9381, 'lng': -43.1901},
    {'name': 'Glória', 'lat': -22.9218, 'lng': -43.1765},
    {'name': 'Catete', 'lat': -22.9266, 'lng': -43.1766},
    {'name': 'Urca', 'lat': -22.9505, 'lng': -43.1637},
    {'name': 'Humaitá', 'lat': -22.9583, 'lng': -43.1970},
    {'name': 'Jardim Botânico', 'lat': -22.9682, 'lng': -43.2235},
    {'name': 'Gávea', 'lat': -22.9766, 'lng': -43.2280},
    {'name': 'São Conrado', 'lat': -22.9991, 'lng': -43.2740},
    {'name': 'Recreio', 'lat': -23.0258, 'lng': -43.4706},
    {'name': 'Méier', 'lat': -22.9027, 'lng': -43.2796},
    {'name': 'Madureira', 'lat': -22.8719, 'lng': -43.3389},
    {'name': 'Jacarepaguá', 'lat': -22.9494, 'lng': -43.3519},
    {'name': 'Vila Isabel', 'lat': -22.9167, 'lng': -43.2500},
    {'name': 'Engenho Novo', 'lat': -22.9053, 'lng': -43.2672},
    {'name': 'Campo Grande', 'lat': -22.9028, 'lng': -43.5539},
  ];

  // ============================================================================
  // CREW ROLES
  // ============================================================================
  static const _crewRoles = [
    'Roadie',
    'Técnico de Som',
    'Iluminador',
    'Produtor de Eventos',
    'Manager',
    'Engenheiro de Áudio',
    'Técnico de Palco',
    'Fotógrafo Musical',
    'Videomaker',
    'Social Media Manager',
    'Designer Gráfico',
    'Assessor de Imprensa',
  ];

  // ============================================================================
  // MAIN SEEDING FUNCTION
  // ============================================================================
  Future<void> seedDatabase(
    AppConfig config,
    void Function(String) onProgress,
  ) async {
    if (!kDebugMode) {
      onProgress('Seeding is only allowed in debug mode.');
      return;
    }

    // Basic seeded users for testing interactions
    // These 20 users are consistent and will be used for predictable testing
    await _seedBasicUsers(config, onProgress);

    // Dynamic large scale seeding
    // Generates 100+ users with varied attributes for realistic feed testing
    await _seedLargeScaleUsers(config, onProgress);

    onProgress('Seeding complete! Restart app recommended.');
  }

  /// Public method to delete seeded users (called from Settings)
  Future<int> deleteSeededUsers() async {
    await deleteSeededProfiles((msg) {
      if (msg.startsWith('Deleted')) {
        // Optional: Parse count
      }
    });
    return 150;
  }

  /// Deletes all users created by the seeder
  Future<void> deleteSeededProfiles(void Function(String) onProgress) async {
    if (!kDebugMode) {
      onProgress('Deletion of seeded profiles is only allowed in debug mode.');
      return;
    }

    onProgress('Searching for seeded profiles...');

    // Find all users with email ending in @seeded.mube.app
    // Since we don't have an email field in the root document and Auth is separate,
    // we query based on a known field pattern or just iterate and check.
    // However, our seeder adds 'email' to the document for debugging/admin purposes.
    // Let's use that.

    final snapshot = await _firestore
        .collection(FirestoreCollections.users)
        .where('email', isGreaterThanOrEqualTo: '')
        .get();

    final seededDocs = snapshot.docs.where((doc) {
      final email = doc.data()['email'] as String?;
      return email != null && email.endsWith('@seeded.mube.app');
    }).toList();

    if (seededDocs.isEmpty) {
      onProgress('No seeded profiles found to delete.');
      return;
    }

    onProgress('Found ${seededDocs.length} seeded profiles. Deleting...');

    const batchSize = 500;
    for (var i = 0; i < seededDocs.length; i += batchSize) {
      final batch = _firestore.batch();
      final end = (i + batchSize < seededDocs.length)
          ? i + batchSize
          : seededDocs.length;
      final chunk = seededDocs.sublist(i, end);

      for (final doc in chunk) {
        batch.delete(doc.reference);
        // Also delete from matches/interactions if necessary, but for now just users
      }

      await batch.commit();
      onProgress('Deleted $end of ${seededDocs.length} profiles...');
    }

    onProgress('All seeded profiles deleted successfully!');
  }

  Future<void> _seedBasicUsers(
    AppConfig appConfig,
    void Function(String) onProgress,
  ) async {
    final crewRolesConfig = appConfig.crewRoles;
    final instrumentsConfig = appConfig.instruments;
    final genresConfig = appConfig.genres;

    if (genresConfig.isEmpty) throw Exception('No genres found in AppConfig!');

    // Create 20 basic users
    for (int i = 0; i < 20; i++) {
      final name = _firstNames[_random.nextInt(_firstNames.length)];

      // Pick random photo
      final photoUrl = _photoUrls[_random.nextInt(_photoUrls.length)];

      final userData = _generateProfessional(
        genresConfig: genresConfig,
        instrumentsConfig: instrumentsConfig,
        crewRolesConfig: crewRolesConfig,
        firstName: name,
        photoUrl: photoUrl,
      );

      await _firestore
          .collection(FirestoreCollections.users)
          .doc(userData['uid'])
          .set(userData);
      onProgress('Created basic user ${i + 1}/20: $name');
    }
  }

  /// Public method to seed users (called from Settings)
  Future<int> seedUsers({int count = 150}) async {
    final appConfig = await _configRepo.fetchConfig();
    await seedDatabase(appConfig, (msg) => print(msg));
    return count + 20; // 150 dynamic + 20 basic
  }

  /// Seeds the database with [count] realistic, diverse users.
  Future<int> _seedLargeScaleUsers(
    AppConfig appConfig,
    void Function(String) onProgress, {
    int count = 150,
  }) async {
    onProgress('Starting to seed $count dynamic users...');

    // 1. Fetch App Configuration
    onProgress('Fetching AppConfig...');
    final genresConfig = appConfig.genres;
    final instrumentsConfig = appConfig.instruments;
    final crewRolesConfig = appConfig.crewRoles;
    final studioServicesConfig = appConfig.studioServices;
    final categoriesConfig = appConfig.professionalCategories;

    if (genresConfig.isEmpty) throw Exception('No genres found in AppConfig!');

    // 2. Shuffle photos for unique assignment
    final shuffledPhotos = List<String>.from(_photoUrls)..shuffle(_random);
    int photoIndex = 0;

    // 3. Calculate profile type distribution
    final professionalCount = (count * 0.60).round(); // 60% professionals
    final bandCount = (count * 0.25).round(); // 25% bands
    final studioCount = count - professionalCount - bandCount; // 15% studios

    print(
      '[AppSeeder] Distribution: $professionalCount pros, $bandCount bands, $studioCount studios',
    );

    final batch = _firestore.batch();
    int batchCount = 0;
    int totalCreated = 0;

    // --- CREATE PROFESSIONALS ---
    for (int i = 0; i < professionalCount; i++) {
      final userData = _generateProfessional(
        genresConfig: genresConfig,
        instrumentsConfig: instrumentsConfig,
        crewRolesConfig: crewRolesConfig,
        categoriesConfig: categoriesConfig,
        photoUrl: shuffledPhotos[photoIndex++ % shuffledPhotos.length],
      );
      batch.set(
        _firestore
            .collection(FirestoreCollections.users)
            .doc(userData['uid'] as String),
        userData,
      );
      batchCount++;
      totalCreated++;
      if (batchCount >= 450) {
        print('[AppSeeder] Committing batch of $batchCount...');
        await batch.commit();
        batchCount = 0;
      }
    }

    // --- CREATE BANDS ---
    for (int i = 0; i < bandCount; i++) {
      final userData = _generateBand(
        genresConfig: genresConfig,
        instrumentsConfig: instrumentsConfig,
        photoUrl: shuffledPhotos[photoIndex++ % shuffledPhotos.length],
      );
      batch.set(
        _firestore
            .collection(FirestoreCollections.users)
            .doc(userData['uid'] as String),
        userData,
      );
      batchCount++;
      totalCreated++;
      if (batchCount >= 450) {
        print('[AppSeeder] Committing batch of $batchCount...');
        await batch.commit();
        batchCount = 0;
      }
    }

    // --- CREATE STUDIOS ---
    for (int i = 0; i < studioCount; i++) {
      final userData = _generateStudio(
        servicesConfig: studioServicesConfig,
        photoUrl: shuffledPhotos[photoIndex++ % shuffledPhotos.length],
        studioIndex: i,
      );
      batch.set(
        _firestore
            .collection(FirestoreCollections.users)
            .doc(userData['uid'] as String),
        userData,
      );
      batchCount++;
      totalCreated++;
      if (batchCount >= 450) {
        print('[AppSeeder] Committing batch of $batchCount...');
        await batch.commit();
        batchCount = 0;
      }
    }

    // Commit remaining
    if (batchCount > 0) {
      print('[AppSeeder] Committing final batch of $batchCount...');
      await batch.commit();
    }

    print('[AppSeeder] ✅ Seeded $totalCreated users successfully!');
    return totalCreated;
  }

  // ============================================================================
  // PROFESSIONAL GENERATOR
  // ============================================================================
  Map<String, dynamic> _generateProfessional({
    required List<ConfigItem> genresConfig,
    required List<ConfigItem> instrumentsConfig,
    required List<ConfigItem> crewRolesConfig,
    List<ConfigItem> categoriesConfig = const [],
    required String photoUrl,
    String? firstName,
  }) {
    final uid = _uuid.v4();
    final first = firstName ?? _firstNames[_random.nextInt(_firstNames.length)];
    final lastName = _lastNames[_random.nextInt(_lastNames.length)];
    final nome = '$first $lastName';
    final nomeArtistico = _random.nextBool() ? first : null;

    // Pick 1-3 professional categories (Cantor, Instrumentista, Crew, DJ)
    final categoryLabels = categoriesConfig.isNotEmpty
        ? categoriesConfig.map((c) => c.label).toList()
        : ['Instrumentista'];
    final userCategories = <String>[];
    userCategories.add(categoryLabels[_random.nextInt(categoryLabels.length)]);
    if (_random.nextDouble() > 0.5 && categoryLabels.length > 1) {
      final second = categoryLabels[_random.nextInt(categoryLabels.length)];
      if (!userCategories.contains(second)) userCategories.add(second);
    }
    if (_random.nextDouble() > 0.75 && categoryLabels.length > 2) {
      final third = categoryLabels[_random.nextInt(categoryLabels.length)];
      if (!userCategories.contains(third)) userCategories.add(third);
    }

    // Pick genres
    final userGenres = _pickGenres(genresConfig, 1, 3);
    final primaryGenre = userGenres.first;

    // Pick instrument based on category
    String? instrument;
    List<String> instruments = [];
    // Functions are specific roles (crew roles, backing vocal), NOT categories
    final List<String> functions = [];
    if (userCategories.contains('Instrumentista') &&
        instrumentsConfig.isNotEmpty) {
      final inst = instrumentsConfig[_random.nextInt(instrumentsConfig.length)];
      instrument = inst.label;
      instruments = [inst.label];
      // Maybe add a second instrument
      if (_random.nextDouble() > 0.6) {
        final second =
            instrumentsConfig[_random.nextInt(instrumentsConfig.length)];
        if (!instruments.contains(second.label)) instruments.add(second.label);
      }
    }
    if (userCategories.contains('Equipe Técnica')) {
      final crewRole = crewRolesConfig.isNotEmpty
          ? crewRolesConfig[_random.nextInt(crewRolesConfig.length)].label
          : _crewRoles[_random.nextInt(_crewRoles.length)];
      functions.add(crewRole);
    }

    final years = 2 + _random.nextInt(18);
    final neighborhood =
        _rjNeighborhoods[_random.nextInt(_rjNeighborhoods.length)];
    final lat =
        (neighborhood['lat'] as double) + (_random.nextDouble() - 0.5) * 0.02;
    final lng =
        (neighborhood['lng'] as double) + (_random.nextDouble() - 0.5) * 0.02;

    // Generate bio based on primary category
    String bio;
    final primaryCategory = userCategories.first;
    // Use correct labels from app_constants: Cantor(a), Instrumentista, Equipe Técnica, DJ
    if (primaryCategory == 'Cantor(a)') {
      bio = _bioTemplatesCantor[_random.nextInt(_bioTemplatesCantor.length)]
          .replaceAll('{{genre}}', primaryGenre.label)
          .replaceAll('{{years}}', years.toString());
    } else if (primaryCategory == 'DJ') {
      bio = _bioTemplatesDJ[_random.nextInt(_bioTemplatesDJ.length)]
          .replaceAll('{{genre}}', primaryGenre.label)
          .replaceAll('{{years}}', years.toString());
    } else if (primaryCategory == 'Equipe Técnica') {
      // functions now only contains actual crew roles (not category names)
      final role = functions.isNotEmpty ? functions.first : 'Técnico de Som';
      bio = _bioTemplatesCrew[_random.nextInt(_bioTemplatesCrew.length)]
          .replaceAll('{{genre}}', primaryGenre.label)
          .replaceAll('{{role}}', role)
          .replaceAll('{{years}}', years.toString());
    } else {
      bio =
          _bioTemplatesInstrumentista[_random.nextInt(
                _bioTemplatesInstrumentista.length,
              )]
              .replaceAll('{{genre}}', primaryGenre.label)
              .replaceAll('{{instrument}}', instrument ?? 'Músico')
              .replaceAll('{{years}}', years.toString());
    }

    // Hashtags
    final hashtags = _generateHashtags(userGenres);

    return {
      'uid': uid,
      'email': '${uid.substring(0, 8)}@seeded.mube.app',
      'nome': nome,
      'foto': photoUrl,
      'bio': bio,
      'cadastro_status': 'concluido',
      'tipo_perfil': AppUserType.professional.id,
      'status': 'ativo',
      'plan': _random.nextDouble() > 0.8 ? 'premium' : 'free',
      'likeCount': 0,
      'favorites_count': 0,
      'location': {
        'cidade': neighborhood['name'],
        'estado': 'RJ',
        'lat': lat,
        'lng': lng,
      },
      'profissional': {
        'nomeArtistico': nomeArtistico ?? firstName,
        'categorias': userCategories,
        'funcoes': functions,
        'instrumentos': instruments,
        'generosMusicais': userGenres.map((g) => g.id).toList(),
        'anosExperiencia': years,
        'disponibilidade': _random.nextBool() ? 'shows' : 'banda',
        'cache': _random.nextBool() ? '${500 + _random.nextInt(2000)}' : null,
      },
      FirestoreFields.matchpointProfile: {
        FirestoreFields.isActive: true,
        'intent': 'join_band',
        FirestoreFields.musicalGenres: userGenres.map((g) => g.id).toList(),
        'hashtags': hashtags,
        'target_roles': [],
        'search_radius': 25 + _random.nextInt(50),
      },
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // ============================================================================
  // BAND GENERATOR
  // ============================================================================
  Map<String, dynamic> _generateBand({
    required List<ConfigItem> genresConfig,
    required List<ConfigItem> instrumentsConfig,
    required String photoUrl,
  }) {
    final uid = _uuid.v4();

    // Generate band name
    final prefix = _bandPrefixes[_random.nextInt(_bandPrefixes.length)];
    final middle = _bandMiddles[_random.nextInt(_bandMiddles.length)];
    final suffix = _bandSuffixes[_random.nextInt(_bandSuffixes.length)];
    final nome = '$prefix $middle $suffix'.trim().replaceAll('  ', ' ');

    // Pick genres
    final userGenres = _pickGenres(genresConfig, 1, 3);
    final primaryGenre = userGenres.first;

    // Pick what they're looking for
    final buscando = <String>[];
    if (instrumentsConfig.isNotEmpty) {
      final inst = instrumentsConfig[_random.nextInt(instrumentsConfig.length)];
      buscando.add(inst.id);
      if (_random.nextDouble() > 0.6) {
        final second =
            instrumentsConfig[_random.nextInt(instrumentsConfig.length)];
        if (!buscando.contains(second.id)) buscando.add(second.id);
      }
    }

    final membersCount = 2 + _random.nextInt(4);
    final neighborhood =
        _rjNeighborhoods[_random.nextInt(_rjNeighborhoods.length)];
    final lat =
        (neighborhood['lat'] as double) + (_random.nextDouble() - 0.5) * 0.02;
    final lng =
        (neighborhood['lng'] as double) + (_random.nextDouble() - 0.5) * 0.02;

    // Generate bio
    final roleLabel = instrumentsConfig.isNotEmpty
        ? instrumentsConfig[_random.nextInt(instrumentsConfig.length)].label
        : 'músico';
    final bio = _bioTemplatesBand[_random.nextInt(_bioTemplatesBand.length)]
        .replaceAll('{{genre}}', primaryGenre.label)
        .replaceAll('{{role}}', roleLabel)
        .replaceAll('{{members}}', membersCount.toString());

    // Hashtags
    final hashtags = _generateHashtags(userGenres);

    return {
      'uid': uid,
      'email': '${uid.substring(0, 8)}@seeded.mube.app',
      'nome': nome,
      'foto': photoUrl,
      'bio': bio,
      'cadastro_status': 'concluido',
      'tipo_perfil': AppUserType.band.id,
      'status': 'ativo',
      'plan': _random.nextDouble() > 0.7 ? 'premium' : 'free',
      'likeCount': 0,
      'favorites_count': 0,
      'location': {
        'cidade': neighborhood['name'],
        'estado': 'RJ',
        'lat': lat,
        'lng': lng,
      },
      'banda': {
        'nome': nome,
        'generosMusicais': userGenres.map((g) => g.id).toList(),
        'membros': membersCount,
        'descricao': bio,
        'buscando': buscando,
      },
      FirestoreFields.matchpointProfile: {
        FirestoreFields.isActive: true,
        'intent': 'find_member',
        FirestoreFields.musicalGenres: userGenres.map((g) => g.id).toList(),
        'hashtags': hashtags,
        'target_roles': buscando,
        'search_radius': 25 + _random.nextInt(50),
      },
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // ============================================================================
  // STUDIO GENERATOR
  // ============================================================================
  Map<String, dynamic> _generateStudio({
    required List<ConfigItem> servicesConfig,
    required String photoUrl,
    required int studioIndex,
  }) {
    final uid = _uuid.v4();

    // Generate studio name (use predefined or generate)
    final nome = studioIndex < _studioNames.length
        ? _studioNames[studioIndex]
        : 'Estúdio ${_lastNames[_random.nextInt(_lastNames.length)]}';

    // Pick services
    final services = <String>[];
    if (servicesConfig.isNotEmpty) {
      final primary = servicesConfig[_random.nextInt(servicesConfig.length)];
      services.add(primary.id);
      if (_random.nextDouble() > 0.4) {
        final second = servicesConfig[_random.nextInt(servicesConfig.length)];
        if (!services.contains(second.id)) services.add(second.id);
      }
      if (_random.nextDouble() > 0.7) {
        final third = servicesConfig[_random.nextInt(servicesConfig.length)];
        if (!services.contains(third.id)) services.add(third.id);
      }
    } else {
      services.addAll(['gravacao', 'ensaio']);
    }

    final neighborhood =
        _rjNeighborhoods[_random.nextInt(_rjNeighborhoods.length)];
    final lat =
        (neighborhood['lat'] as double) + (_random.nextDouble() - 0.5) * 0.02;
    final lng =
        (neighborhood['lng'] as double) + (_random.nextDouble() - 0.5) * 0.02;

    // Generate bio
    final serviceLabel = servicesConfig.isNotEmpty
        ? servicesConfig
              .firstWhere(
                (s) => s.id == services.first,
                orElse: () => servicesConfig.first,
              )
              .label
        : 'Gravação';
    final bio = _bioTemplatesStudio[_random.nextInt(_bioTemplatesStudio.length)]
        .replaceAll('{{service}}', serviceLabel);

    // Studio hashtags
    final hashtags = [
      '#estudio',
      '#gravação',
      '#recording',
      '#studiorio',
      '#musicproduction',
      '#ensaio',
      '#rehearsal',
      '#mixagem',
      '#masterização',
      '#produçãomusical',
    ]..shuffle(_random);

    return {
      'uid': uid,
      'email': '${uid.substring(0, 8)}@seeded.mube.app',
      'nome': nome,
      'foto': photoUrl,
      'bio': bio,
      'cadastro_status': 'concluido',
      'tipo_perfil': AppUserType.studio.id,
      'status': 'ativo',
      'plan': _random.nextDouble() > 0.5 ? 'premium' : 'free',
      'likeCount': 0,
      'favorites_count': 0,
      'location': {
        'cidade': neighborhood['name'],
        'estado': 'RJ',
        'lat': lat,
        'lng': lng,
      },
      'estudio': {
        'nome': nome,
        'servicos': services,
        'descricao': bio,
        'precoHora': 50 + _random.nextInt(250),
        'equipamentos': [
          'Microfones Profissionais',
          'Mesa de Som',
          'Tratamento Acústico',
        ],
      },
      FirestoreFields.matchpointProfile: {
        FirestoreFields.isActive: false, // Studios don't use MatchPoint
        'intent': null,
        FirestoreFields.musicalGenres: <String>[],
        'hashtags': hashtags.take(5).toList(),
        'target_roles': [],
        'search_radius': 0,
      },
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================
  List<ConfigItem> _pickGenres(List<ConfigItem> genres, int min, int max) {
    final picked = <ConfigItem>[];
    final count = min + _random.nextInt(max - min + 1);
    for (int i = 0; i < count && i < genres.length; i++) {
      final genre = genres[_random.nextInt(genres.length)];
      if (!picked.contains(genre)) picked.add(genre);
    }
    return picked.isEmpty ? [genres.first] : picked;
  }

  List<String> _generateHashtags(List<ConfigItem> genres) {
    final hashtags = <String>{};
    for (final genre in genres) {
      final key = genre.id
          .toLowerCase()
          .replaceAll('_', '')
          .replaceAll(' ', '');
      for (final mapKey in _hashtagsByGenre.keys) {
        if (key.contains(mapKey)) {
          final pool = _hashtagsByGenre[mapKey]!;
          final count = 2 + _random.nextInt(2);
          for (int i = 0; i < count && hashtags.length < 8; i++) {
            hashtags.add(pool[_random.nextInt(pool.length)]);
          }
          break;
        }
      }
    }
    // Add generic hashtags
    final genericCount = 1 + _random.nextInt(3);
    for (int i = 0; i < genericCount && hashtags.length < 10; i++) {
      hashtags.add(_genericHashtags[_random.nextInt(_genericHashtags.length)]);
    }
    return hashtags.toList();
  }

  // ============================================================================
  // SEED APP CONFIG
  // ============================================================================
  Future<void> seedAppConfig() async {
    if (!kDebugMode) {
      print('[AppSeeder] Cannot seed app config: only allowed in debug mode.');
      return;
    }
    print('[AppSeeder] Seeding App Config...');
    final configCollection = _firestore.collection('config');

    final config = AppConfig(
      version: 1,
      genres: app_constants.genres
          .map(
            (g) => ConfigItem(
              id: g.toLowerCase().replaceAll(' ', '_'),
              label: g,
              order: app_constants.genres.indexOf(g),
            ),
          )
          .toList(),
      instruments: app_constants.instruments
          .map(
            (i) => ConfigItem(
              id: i.toLowerCase().replaceAll(' ', '_'),
              label: i,
              order: app_constants.instruments.indexOf(i),
            ),
          )
          .toList(),
      crewRoles: app_constants.crewRoles
          .map(
            (r) => ConfigItem(
              id: r.toLowerCase().replaceAll(' ', '_'),
              label: r,
              order: app_constants.crewRoles.indexOf(r),
            ),
          )
          .toList(),
      studioServices: app_constants.studioServices
          .map(
            (s) => ConfigItem(
              id: s.toLowerCase().replaceAll(' ', '_'),
              label: s,
              order: app_constants.studioServices.indexOf(s),
            ),
          )
          .toList(),
      professionalCategories: app_constants.professionalCategories
          .map(
            (c) =>
                ConfigItem(id: c['id'] as String, label: c['label'] as String),
          )
          .toList(),
    );

    final jsonMap = jsonDecode(jsonEncode(config.toJson()));
    await configCollection.doc('app_data').set(jsonMap);
    print('[AppSeeder] ✅ App Config seeded to config/app_data');
  }
}

// ============================================================================
// PROVIDER
// ============================================================================
@riverpod
AppSeeder appSeeder(Ref ref) {
  return AppSeeder(
    FirebaseFirestore.instance,
    ref.watch(appConfigRepositoryProvider),
  );
}
