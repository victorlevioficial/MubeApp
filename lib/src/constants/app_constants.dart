import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Categorias Profissionais
const List<Map<String, dynamic>> professionalCategories = [
  {'id': 'singer', 'label': 'Cantor(a)', 'icon': FontAwesomeIcons.microphone},
  {
    'id': 'instrumentalist',
    'label': 'Instrumentista',
    'icon': FontAwesomeIcons.guitar,
  },
  {'id': 'crew', 'label': 'Equipe Técnica', 'icon': FontAwesomeIcons.wrench},
  {'id': 'dj', 'label': 'DJ', 'icon': FontAwesomeIcons.compactDisc},
];

// Gêneros Musicais
const List<String> genres = [
  'Rock',
  'Pop',
  'Sertanejo',
  'MPB',
  'Pagode',
  'Samba',
  'Funk',
  'Hip Hop',
  'Rap',
  'Eletrônica',
  'Jazz',
  'Blues',
  'Reggae',
  'Forró',
  'Gospel',
  'Metal',
  'Punk',
  'Country',
  'Folk',
  'Soul',
  'RnB',
  'Outro',
];

// Instrumentos
const List<String> instruments = [
  'Violão',
  'Guitarra',
  'Baixo',
  'Bateria',
  'Teclado',
  'Piano',
  'Percussão',
  'Violino',
  'Viola',
  'Cello',
  'Saxofone',
  'Trompete',
  'Trombone',
  'Clarinete',
  'Flauta',
  'Gaita',
  'Sanfona',
  'Ukulele',
  'Cavaquinho',
  'Banjo',
  'DJ', // Added DJ as requested
  'Outro',
];

// Funções de Equipe
const List<String> crewRoles = [
  'Técnico de Som',
  'Técnico de Luz',
  'Roadie',
  'Produtor',
  'Stage Manager',
  'Diretor Musical',
  'Fotógrafo',
  'Videomaker',
  'Maquiador',
  'Figurinista',
  'Motorista',
  'DJ', // Added DJ here too as it can be considered a role
];

// Serviços de Estúdio
const List<String> studioServices = [
  'Ensaio',
  'Gravação',
  'Mixagem',
  'Masterização',
  'Produção Musical',
  'Podcast',
  'Videoclipe',
  'Livestream',
  'Outro',
];
