import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Categorias profissionais
const List<Map<String, dynamic>> professionalCategories = [
  {'id': 'singer', 'label': 'Cantor(a)', 'icon': FontAwesomeIcons.microphone},
  {
    'id': 'instrumentalist',
    'label': 'Instrumentista',
    'icon': FontAwesomeIcons.guitar,
  },
  {'id': 'dj', 'label': 'DJ', 'icon': FontAwesomeIcons.compactDisc},
  {
    'id': 'production',
    'label': 'Produ\u00E7\u00E3o Musical',
    'icon': FontAwesomeIcons.sliders,
  },
  {
    'id': 'stage_tech',
    'label': 'T\u00E9cnica de Palco',
    'icon': FontAwesomeIcons.wrench,
  },
  {'id': 'audiovisual', 'label': 'Audiovisual', 'icon': FontAwesomeIcons.video},
  {
    'id': 'education',
    'label': 'Educa\u00E7\u00E3o',
    'icon': FontAwesomeIcons.graduationCap,
  },
  {
    'id': 'luthier',
    'label': 'Luthier',
    'icon': FontAwesomeIcons.screwdriverWrench,
  },
  {
    'id': 'performance',
    'label': 'Performance',
    'icon': FontAwesomeIcons.masksTheater,
  },
];

// Funcoes de audiovisual
const List<String> audiovisualRoles = [
  'Videomaker',
  'Fot\u00F3grafo Musical',
  'Editor de V\u00EDdeo',
  'Motion Designer',
  'Social Media Manager',
  'Diretor de Arte',
  'Colorista',
  'Operador de C\u00E2mera',
  'Live Streamer',
];

// Funcoes de educacao
const List<String> educationRoles = [
  'Professor(a)',
  'Instrutor(a)',
  'Mentor(a)',
  'Coach',
  'Oficineiro(a)',
  'Palestrante',
  'Educador(a) Musical',
];

// Funcoes de luthieria
const List<String> luthierRoles = [
  'Luthier',
  'Setup de Instrumentos',
  'Manuten\u00E7\u00E3o de Instrumentos',
  'Reparo de Instrumentos',
  'Ajuste de Instrumentos',
  'Regulagem',
  'Restaura\u00E7\u00E3o de Instrumentos',
];

// Funcoes de performance
const List<String> performanceRoles = [
  'Performer',
  'Dan\u00E7arino(a)',
  'Ator/atriz',
  'Apresentador(a)',
  'MC',
  'Artista de Palco',
  'Int\u00E9rprete',
];

// Generos musicais
const List<String> genres = [
  'Pagode',
  'Sertanejo',
  'Funk',
  'Forr\u00F3',
  'Trap',
  'Rap',
  'Hip Hop',
  'Pop',
  'Rock',
  'Samba',
  'MPB',
  'Gospel',
  'Eletr\u00F4nica',
  'Reggae',
  'Ax\u00E9',
  'Jazz',
  'Blues',
  'Metal',
  'Cl\u00E1ssica',
  'Brega',
  'Indie',
  'R&B',
  'Soul',
  'Country',
  'Latino',
  'Infantil',
  'Experimental',
  'Sertanejo Universit\u00E1rio',
  'Samba-enredo',
  'Xote',
  'Bai\u00E3o',
  'Xaxado',
  'Piseiro',
  'Lo-Fi',
  'Pop Rock',
  'Rock Cl\u00E1ssico',
  'Indie Rock',
  'Hard Rock',
  'Punk Rock',
  'Hardcore',
  'Emo',
  'Grunge',
  'Garage Rock',
  'Heavy Metal',
  'Thrash Metal',
  'Death Metal',
  'Black Metal',
  'Metalcore',
  'Nu Metal',
  'House',
  'Techno',
  'Trance',
  'EDM',
  'Dubstep',
  'Dancehall',
  'Bossa Nova',
  'Choro',
  'Fusion',
  'Smooth Jazz',
  'Worship',
  'Erudita',
  'Orquestral',
];

// Instrumentos
const List<String> instruments = [
  'Viol\u00E3o',
  'Guitarra',
  'Baixo',
  'Bass Synth',
  'Cavaquinho',
  'Viola caipira',
  'Viol\u00E3o 7 cordas',
  'Bandolim',
  'Banjo',
  'Ukulele',
  'Violino',
  'Viola de arco',
  'Violoncelo',
  'Contrabaixo de arco',
  'Piano',
  'Teclado',
  '\u00D3rg\u00E3o',
  'Clavinete',
  'Sintetizador',
  'Acordeon',
  'Bateria',
  'Caj\u00F3n',
  'Congas',
  'Bong\u00F4',
  'Timbales',
  'Pandeiro',
  'Tantan',
  'Tamborim',
  'Surdo',
  'Repique',
  'Repique de m\u00E3o',
  'Timbal (baiano)',
  'Cu\u00EDca',
  'Caixa',
  'Agog\u00F4',
  'Reco-reco',
  'Ganz\u00E1',
  'Chocalho / Shaker',
  'Tri\u00E2ngulo',
  'Atabaque',
  'Berimbau',
  'Zabumba',
  'Alfaia',
  'Percuss\u00E3o geral',
  'Flauta transversal',
  'Flauta doce',
  'Clarinete',
  'Saxofone soprano',
  'Saxofone alto',
  'Saxofone tenor',
  'Saxofone bar\u00EDtono',
  'Gaita (harm\u00F4nica)',
  'Trompete',
  'Trombone',
  'Trompa',
  'Tuba',
  'Euf\u00F4nio / Bombardino',
  'Obo\u00E9',
  'EWI',
  'Flugelhorn',
];

// Funcoes de producao musical
const List<String> productionRoles = [
  'Produtor Musical',
  'T\u00E9cnico de Grava\u00E7\u00E3o',
  'Edi\u00E7\u00E3o de \u00C1udio',
  'Afina\u00E7\u00E3o de Voz',
  'Time Alignment (Bateria/Instrumentos)',
  'Mixagem',
  'Masteriza\u00E7\u00E3o',
  'Sound Design',
  'Programa\u00E7\u00E3o de Bateria (MIDI)',
  'Programa\u00E7\u00E3o de Instrumentos (MIDI)',
  'Beatmaker',
  'Arranjador',
  'Compositor',
  'Diretor Vocal',
];

// Funcoes de tecnica de palco
const List<String> stageTechRoles = [
  'Produtor T\u00E9cnico',
  'Produtor Art\u00EDstico',
  'Produtor Executivo',
  'T\u00E9cnico de PA',
  'T\u00E9cnico de Monitor',
  'T\u00E9cnico de RF',
  'T\u00E9cnico de Luz',
  'VJ (Tel\u00E3o)',
  'T\u00E9cnico de LED (Painel)',
  'T\u00E9cnico de Teleprompter',
  'Roadie',
  'Stage Manager',
  'Drum Tech',
  'Guitar Tech',
  'Bass Tech',
  'Keyboard Tech',
];

@Deprecated(
  'Use productionRoles and stageTechRoles. Kept for transition compatibility.',
)
const List<String> crewRoles = [...productionRoles, ...stageTechRoles];

// Servicos de estudio
const List<String> studioServices = [
  'Mixagem',
  'Masteriza\u00E7\u00E3o',
  'Edi\u00E7\u00E3o de \u00E1udio',
  'Afina\u00E7\u00E3o de voz',
  'Alinhamento/edi\u00E7\u00E3o de voz',
  'Edi\u00E7\u00E3o de bateria',
  'Programa\u00E7\u00E3o de bateria (MIDI)',
  'Cria\u00E7\u00E3o de beat',
  'Produ\u00E7\u00E3o musical',
  'Arranjo',
  'Sound design',
  'Restaura\u00E7\u00E3o de \u00E1udio',
  'Mixagem de podcast',
  'Edi\u00E7\u00E3o de podcast',
  'Trilha/jingle',
  'Grava\u00E7\u00E3o de voz',
  'Grava\u00E7\u00E3o de viol\u00E3o',
  'Grava\u00E7\u00E3o de guitarra',
  'Grava\u00E7\u00E3o de baixo',
  'Grava\u00E7\u00E3o de teclados',
  'Grava\u00E7\u00E3o de bateria',
  'Grava\u00E7\u00E3o de banda ao vivo',
  'Dire\u00E7\u00E3o vocal',
  'Locu\u00E7\u00E3o (grava\u00E7\u00E3o)',
  'Dublagem (grava\u00E7\u00E3o)',
  'Ensaios pr\u00E9-produ\u00E7\u00E3o (com grava\u00E7\u00E3o guia)',
];

// Genero (perfil profissional/contratante)
const String genderMale = 'Masculino';
const String genderFemale = 'Feminino';
const String genderOther = 'Outro';
const String genderPreferNotToInform = 'Prefiro n\u00E3o informar';
const String _legacyGenderPreferNotToSay = 'Prefiro n\u00E3o dizer';

const List<String> genderOptions = [
  genderMale,
  genderFemale,
  genderOther,
  genderPreferNotToInform,
];

String normalizeGenderValue(String? value) {
  final normalized = value?.trim() ?? '';
  if (normalized.isEmpty) return '';
  if (normalized == _legacyGenderPreferNotToSay) {
    return genderPreferNotToInform;
  }
  return normalized;
}
