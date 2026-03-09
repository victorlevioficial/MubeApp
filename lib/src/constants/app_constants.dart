import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Categorias Profissionais
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
    'label': 'Produção Musical',
    'icon': FontAwesomeIcons.sliders,
  },
  {
    'id': 'stage_tech',
    'label': 'Técnica de Palco',
    'icon': FontAwesomeIcons.wrench,
  },
];

// Gêneros Musicais
const List<String> genres = [
  'Pagode',
  'Sertanejo',
  'Funk',
  'Forró',
  'Trap',
  'Rap',
  'Hip Hop',
  'Pop',
  'Rock',
  'Samba',
  'MPB',
  'Gospel',
  'Eletrônica',
  'Reggae',
  'Axé',
  'Jazz',
  'Blues',
  'Metal',
  'Clássica',
  'Brega',
  'Indie',
  'R&B',
  'Soul',
  'Country',
  'Latino',
  'Infantil',
  'Experimental',
  'Sertanejo Universitário',
  'Samba-enredo',
  'Xote',
  'Baião',
  'Xaxado',
  'Piseiro',
  'Lo-Fi',
  'Pop Rock',
  'Rock Clássico',
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
  'Violão',
  'Guitarra',
  'Baixo',
  'Bass Synth',
  'Cavaquinho',
  'Viola caipira',
  'Violão 7 cordas',
  'Bandolim',
  'Banjo',
  'Ukulele',
  'Violino',
  'Viola de arco',
  'Violoncelo',
  'Contrabaixo de arco',
  'Piano',
  'Teclado',
  'Órgão',
  'Clavinete',
  'Sintetizador',
  'Acordeon',
  'Bateria',
  'Cajón',
  'Congas',
  'Bongô',
  'Timbales',
  'Pandeiro',
  'Tantan',
  'Tamborim',
  'Surdo',
  'Repique',
  'Repique de mão',
  'Timbal (baiano)',
  'Cuíca',
  'Caixa',
  'Agogô',
  'Reco-reco',
  'Ganzá',
  'Chocalho / Shaker',
  'Triângulo',
  'Atabaque',
  'Berimbau',
  'Zabumba',
  'Alfaia',
  'Percussão geral',
  'Flauta transversal',
  'Flauta doce',
  'Clarinete',
  'Saxofone soprano',
  'Saxofone alto',
  'Saxofone tenor',
  'Saxofone barítono',
  'Gaita (harmônica)',
  'Trompete',
  'Trombone',
  'Trompa',
  'Tuba',
  'Eufônio / Bombardino',
  'Oboé',
  'EWI',
  'Flugelhorn',
];

// Funções de Produção Musical
const List<String> productionRoles = [
  'Produtor Musical',
  'Técnico de Gravação',
  'Edição de Áudio',
  'Afinação de Voz',
  'Time Alignment (Bateria/Instrumentos)',
  'Mixagem',
  'Masterização',
  'Sound Design',
  'Programação de Bateria (MIDI)',
  'Programação de Instrumentos (MIDI)',
  'Beatmaker',
  'Arranjador',
  'Compositor',
  'Diretor Vocal',
];

// Funções de Técnica de Palco
const List<String> stageTechRoles = [
  'Produtor Técnico',
  'Produtor Artístico',
  'Produtor Executivo',
  'Técnico de PA',
  'Técnico de Monitor',
  'Técnico de RF',
  'Técnico de Luz',
  'VJ (Telão)',
  'Técnico de LED (Painel)',
  'Técnico de Teleprompter',
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

// Serviços de Estúdio
const List<String> studioServices = [
  'Mixagem',
  'Masterização',
  'Edição de áudio',
  'Afinação de voz',
  'Alinhamento/edição de voz',
  'Edição de bateria',
  'Programação de bateria (MIDI)',
  'Criação de beat',
  'Produção musical',
  'Arranjo',
  'Sound design',
  'Restauração de áudio',
  'Mixagem de podcast',
  'Edição de podcast',
  'Trilha/jingle',
  'Gravação de voz',
  'Gravação de violão',
  'Gravação de guitarra',
  'Gravação de baixo',
  'Gravação de teclados',
  'Gravação de bateria',
  'Gravação de banda ao vivo',
  'Direção vocal',
  'Locução (gravação)',
  'Dublagem (gravação)',
  'Ensaios pré-produção (com gravação guia)',
];

// Gênero (perfil profissional/contratante)
const String genderMale = 'Masculino';
const String genderFemale = 'Feminino';
const String genderOther = 'Outro';
const String genderPreferNotToInform = 'Prefiro não informar';
const String _legacyGenderPreferNotToSay = 'Prefiro não dizer';

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
