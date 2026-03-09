import 'package:flutter/material.dart';

import '../domain/music_link_validator.dart';

@immutable
class MusicPlatformDefinition {
  final String key;
  final String label;
  final String assetPath;
  final Color color;
  final String placeholder;

  const MusicPlatformDefinition({
    required this.key,
    required this.label,
    required this.assetPath,
    required this.color,
    required this.placeholder,
  });
}

const musicPlatformCatalog = <MusicPlatformDefinition>[
  MusicPlatformDefinition(
    key: MusicLinkValidator.spotifyKey,
    label: 'Spotify',
    assetPath: 'assets/images/icons/spotify.svg',
    color: Color(0xFF1DB954),
    placeholder: 'https://open.spotify.com/artist/...',
  ),
  MusicPlatformDefinition(
    key: MusicLinkValidator.deezerKey,
    label: 'Deezer',
    assetPath: 'assets/images/icons/deezer.svg',
    color: Color(0xFFA238FF),
    placeholder: 'https://www.deezer.com/artist/...',
  ),
  MusicPlatformDefinition(
    key: MusicLinkValidator.youtubeMusicKey,
    label: 'YouTube Music',
    assetPath: 'assets/images/icons/youtubemusic.svg',
    color: Color(0xFFFF0000),
    placeholder: 'https://music.youtube.com/channel/...',
  ),
  MusicPlatformDefinition(
    key: MusicLinkValidator.appleMusicKey,
    label: 'Apple Music',
    assetPath: 'assets/images/icons/applemusic.svg',
    color: Color(0xFFFA233B),
    placeholder: 'https://music.apple.com/artist/...',
  ),
];

final Map<String, MusicPlatformDefinition> musicPlatformCatalogByKey = {
  for (final platform in musicPlatformCatalog) platform.key: platform,
};
