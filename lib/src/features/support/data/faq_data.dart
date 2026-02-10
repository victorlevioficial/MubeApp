class FAQItem {
  final String question;
  final String answer;
  final String category;
  final List<String> tags;

  const FAQItem({
    required this.question,
    required this.answer,
    required this.category,
    this.tags = const [],
  });
}

abstract final class FAQCategories {
  static const String accountAccess = 'Conta e Acesso';
  static const String profileOnboarding = 'Perfil e Onboarding';
  static const String bands = 'Bandas e Integrantes';
  static const String matchpointSearch = 'MatchPoint e Busca';
  static const String chatSecurity = 'Chat e Seguranca';
  static const String privacyLgpd = 'Privacidade e LGPD';
  static const String supportTickets = 'Tickets e Atendimento';
}

const List<String> kFaqCategoryOrder = [
  FAQCategories.accountAccess,
  FAQCategories.profileOnboarding,
  FAQCategories.bands,
  FAQCategories.matchpointSearch,
  FAQCategories.chatSecurity,
  FAQCategories.privacyLgpd,
  FAQCategories.supportTickets,
];

const List<FAQItem> kAppFAQs = [
  FAQItem(
    category: FAQCategories.accountAccess,
    question: 'Como redefino minha senha?',
    answer:
        'Acesse Configuracoes > Conta > Alterar Senha. O app envia um link de redefinicao para o seu e-mail cadastrado.',
    tags: ['senha', 'login', 'acesso', 'redefinir'],
  ),
  FAQItem(
    category: FAQCategories.accountAccess,
    question: 'Posso alterar o e-mail da minha conta?',
    answer:
        'Se voce perdeu acesso ao e-mail atual ou precisa atualizar seus dados de conta, abra um ticket na categoria Problema na Conta para analise do suporte.',
    tags: ['email', 'conta', 'login'],
  ),
  FAQItem(
    category: FAQCategories.accountAccess,
    question: 'Como desativo minha conta no Mube?',
    answer:
        'No app, va em Configuracoes e toque em Desativar Conta. Essa acao e permanente e remove seus dados pessoais conforme as regras legais aplicaveis.',
    tags: ['excluir', 'conta', 'desativar', 'dados'],
  ),
  FAQItem(
    category: FAQCategories.accountAccess,
    question: 'Existe idade minima para usar o app?',
    answer:
        'Sim. O Mube e destinado a maiores de 18 anos. Durante o fluxo de cadastro, validamos elegibilidade para perfis que exigem confirmacao de idade.',
    tags: ['18', 'idade', 'maioridade', 'elegibilidade'],
  ),
  FAQItem(
    category: FAQCategories.profileOnboarding,
    question: 'Quais tipos de perfil existem no Mube?',
    answer:
        'Atualmente voce pode se cadastrar como Profissional, Banda, Estudio ou Contratante. Cada tipo possui campos e regras de visibilidade especificos.',
    tags: ['tipo', 'perfil', 'profissional', 'banda', 'estudio', 'contratante'],
  ),
  FAQItem(
    category: FAQCategories.profileOnboarding,
    question: 'Por que nao consigo usar todas as funcoes logo apos registrar?',
    answer:
        'Depois do registro com e-mail e senha, e necessario concluir o onboarding (tipo de perfil + dados obrigatorios). So com cadastro concluido os recursos completos sao liberados.',
    tags: ['onboarding', 'cadastro', 'concluido', 'bloqueio'],
  ),
  FAQItem(
    category: FAQCategories.profileOnboarding,
    question: 'Quais dados sao obrigatorios para concluir o perfil?',
    answer:
        'No minimo, nome e localizacao. Dependendo do tipo de perfil, tambem sao exigidos campos especificos como instrumentos, generos musicais ou servicos oferecidos.',
    tags: ['dados', 'perfil', 'nome', 'localizacao', 'instrumentos'],
  ),
  FAQItem(
    category: FAQCategories.profileOnboarding,
    question: 'Posso mudar meu tipo de perfil depois?',
    answer:
        'No momento, o tipo de perfil e definido no cadastro inicial. Se precisar alterar, abra um ticket para avaliarmos seu caso com seguranca de dados.',
    tags: ['tipo', 'perfil', 'alterar', 'migrar'],
  ),
  FAQItem(
    category: FAQCategories.bands,
    question: 'Por que minha banda aparece como rascunho (draft)?',
    answer:
        'Bandas novas iniciam como rascunho por regra da plataforma. Nessa fase, a visibilidade e limitada ate que os requisitos de ativacao sejam atendidos.',
    tags: ['banda', 'draft', 'rascunho', 'status'],
  ),
  FAQItem(
    category: FAQCategories.bands,
    question: 'Quando a banda se torna ativa e visivel?',
    answer:
        'A banda e ativada apos convites aceitos por integrantes com perfil profissional, conforme o fluxo de onboarding da banda.',
    tags: ['banda', 'ativacao', 'integrantes', 'visibilidade'],
  ),
  FAQItem(
    category: FAQCategories.bands,
    question: 'Quem administra a banda criada no onboarding?',
    answer:
        'O usuario que cria a banda entra como administrador inicial e primeiro integrante. Depois, ele pode gerenciar convites e composicao da banda.',
    tags: ['admin', 'banda', 'convites', 'integrantes'],
  ),
  FAQItem(
    category: FAQCategories.matchpointSearch,
    question: 'Como funciona o MatchPoint?',
    answer:
        'O MatchPoint cruza afinidade musical, objetivos e localizacao para sugerir conexoes mais relevantes entre perfis compativeis.',
    tags: ['matchpoint', 'afinidade', 'localizacao', 'conexao'],
  ),
  FAQItem(
    category: FAQCategories.matchpointSearch,
    question: 'Como pauso minha visibilidade no MatchPoint e na busca?',
    answer:
        'Em Configuracoes > Privacidade e Visibilidade, voce pode desativar o MatchPoint e tambem remover seu perfil da Home e Busca geral.',
    tags: ['privacidade', 'visibilidade', 'matchpoint', 'busca'],
  ),
  FAQItem(
    category: FAQCategories.matchpointSearch,
    question: 'O que acontece quando da match?',
    answer:
        'Quando existe interesse mutuo, o app cria um chat entre os perfis para que voces conversem diretamente.',
    tags: ['match', 'chat', 'conversa'],
  ),
  FAQItem(
    category: FAQCategories.matchpointSearch,
    question: 'Por que nao encontro perfis perto de mim?',
    answer:
        'Verifique se sua localizacao esta completa e atualizada. O app usa cidade/estado e coordenadas aproximadas para melhorar busca e recomendacoes.',
    tags: ['busca', 'localizacao', 'cidade', 'geolocalizacao'],
  ),
  FAQItem(
    category: FAQCategories.chatSecurity,
    question: 'Como bloquear usuarios no app?',
    answer:
        'Voce pode gerenciar bloqueios em Configuracoes > Privacidade e Visibilidade. Perfis bloqueados deixam de interagir com voce.',
    tags: ['bloquear', 'seguranca', 'usuario'],
  ),
  FAQItem(
    category: FAQCategories.chatSecurity,
    question: 'Como reportar comportamento inadequado?',
    answer:
        'Abra um ticket de suporte na categoria Reportar um Problema, descreva o ocorrido e anexe evidencias (prints) quando possivel.',
    tags: ['denuncia', 'abuso', 'comportamento', 'ticket'],
  ),
  FAQItem(
    category: FAQCategories.chatSecurity,
    question: 'O Mube intermedia contratos ou pagamentos entre usuarios?',
    answer:
        'Nao. O Mube facilita conexoes entre perfis, mas nao intermedia pagamentos ou contratos entre usuarios neste momento.',
    tags: ['contrato', 'pagamento', 'intermediacao'],
  ),
  FAQItem(
    category: FAQCategories.privacyLgpd,
    question: 'Quais dados pessoais o Mube coleta?',
    answer:
        'Coletamos dados de cadastro, perfil, localizacao e uso do app para operacao da plataforma, conexoes entre perfis, seguranca e melhoria continua do produto.',
    tags: ['dados', 'coleta', 'perfil', 'localizacao'],
  ),
  FAQItem(
    category: FAQCategories.privacyLgpd,
    question: 'O Mube vende meus dados?',
    answer:
        'Nao. O Mube nao vende dados pessoais. O compartilhamento ocorre apenas quando necessario para operacao do servico, como provedores de tecnologia e obrigacoes legais.',
    tags: ['compartilhamento', 'dados', 'venda'],
  ),
  FAQItem(
    category: FAQCategories.privacyLgpd,
    question: 'Como exerco meus direitos da LGPD?',
    answer:
        'Voce pode solicitar acesso, correcao, exclusao e outros direitos do titular entrando em contato pelo e-mail suporte@mube.app.',
    tags: ['lgpd', 'direitos', 'acesso', 'exclusao'],
  ),
  FAQItem(
    category: FAQCategories.privacyLgpd,
    question: 'O app coleta dados de pagamento?',
    answer:
        'Nao no momento. Se funcionalidades pagas forem implementadas no futuro, os documentos legais serao atualizados com transparencia.',
    tags: ['pagamento', 'cobranca', 'financeiro'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'Como abrir um ticket com mais chance de resolucao rapida?',
    answer:
        'Use um assunto claro, descreva o passo a passo do problema, informe contexto (tipo de perfil e acao realizada) e inclua anexos quando necessario.',
    tags: ['ticket', 'suporte', 'boas praticas', 'atendimento'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'Posso enviar anexos no ticket?',
    answer:
        'Sim. Voce pode anexar ate 3 imagens por chamado para ajudar na analise tecnica.',
    tags: ['anexo', 'imagem', 'ticket'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'Como acompanho o andamento do chamado?',
    answer:
        'Acesse Meus Tickets para ver status e detalhes. Os estados mais comuns sao: Aberto, Em Analise, Resolvido e Fechado.',
    tags: ['status', 'ticket', 'chamado', 'andamento'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'Em quanto tempo recebo retorno?',
    answer:
        'O tempo varia conforme complexidade e fila de atendimento. Chamados com descricao completa e anexos costumam ser analisados com mais agilidade.',
    tags: ['prazo', 'retorno', 'tempo', 'suporte'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'O aplicativo e gratuito?',
    answer:
        'Sim. O Mube e gratuito para download e uso das funcionalidades principais da plataforma.',
    tags: ['gratuito', 'plano', 'assinatura', 'preco'],
  ),
];
