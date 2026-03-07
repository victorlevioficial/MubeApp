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
  static const String chatSecurity = 'Chat e Segurança';
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
        'Acesse Configurações > Conta > Alterar Senha. O app envia um link de redefinição para o seu e-mail cadastrado.',
    tags: ['senha', 'login', 'acesso', 'redefinir'],
  ),
  FAQItem(
    category: FAQCategories.accountAccess,
    question: 'Posso alterar o e-mail da minha conta?',
    answer:
        'Se você perdeu acesso ao e-mail atual ou precisa atualizar seus dados de conta, abra um ticket na categoria Problema na Conta para análise do suporte.',
    tags: ['email', 'conta', 'login'],
  ),
  FAQItem(
    category: FAQCategories.accountAccess,
    question: 'Como desativo minha conta no Mube?',
    answer:
        'No app, vá em Configurações e toque em Desativar Conta. Essa ação é permanente e remove seus dados pessoais conforme as regras legais aplicáveis.',
    tags: ['excluir', 'conta', 'desativar', 'dados'],
  ),
  FAQItem(
    category: FAQCategories.accountAccess,
    question: 'Existe idade mínima para usar o app?',
    answer:
        'Sim. O Mube é destinado a maiores de 18 anos. Durante o fluxo de cadastro, validamos elegibilidade para perfis que exigem confirmação de idade.',
    tags: ['18', 'idade', 'maioridade', 'elegibilidade'],
  ),
  FAQItem(
    category: FAQCategories.profileOnboarding,
    question: 'Quais tipos de perfil existem no Mube?',
    answer:
        'Atualmente você pode se cadastrar como Profissional, Banda, Estúdio ou Contratante. Cada tipo possui campos e regras de visibilidade específicos.',
    tags: ['tipo', 'perfil', 'profissional', 'banda', 'estúdio', 'contratante'],
  ),
  FAQItem(
    category: FAQCategories.profileOnboarding,
    question: 'Por que não consigo usar todas as funções logo após registrar?',
    answer:
        'Depois do registro com e-mail e senha, é necessário concluir o onboarding (tipo de perfil + dados obrigatórios). Só com cadastro concluído os recursos completos são liberados.',
    tags: ['onboarding', 'cadastro', 'concluído', 'bloqueio'],
  ),
  FAQItem(
    category: FAQCategories.profileOnboarding,
    question: 'Quais dados são obrigatórios para concluir o perfil?',
    answer:
        'No mínimo, nome e localização. Dependendo do tipo de perfil, também são exigidos campos específicos como instrumentos, gêneros musicais ou serviços oferecidos.',
    tags: ['dados', 'perfil', 'nome', 'localização', 'instrumentos'],
  ),
  FAQItem(
    category: FAQCategories.profileOnboarding,
    question: 'Posso mudar meu tipo de perfil depois?',
    answer:
        'No momento, o tipo de perfil é definido no cadastro inicial. Se precisar alterar, abra um ticket para avaliarmos seu caso com segurança de dados.',
    tags: ['tipo', 'perfil', 'alterar', 'migrar'],
  ),
  FAQItem(
    category: FAQCategories.bands,
    question: 'Por que minha banda aparece como rascunho (draft)?',
    answer:
        'Bandas novas iniciam como rascunho por regra da plataforma. Nessa fase, a banda ainda não aparece no app até atingir os requisitos mínimos de ativação.',
    tags: ['banda', 'draft', 'rascunho', 'status'],
  ),
  FAQItem(
    category: FAQCategories.bands,
    question: 'Quando a banda se torna ativa e visível?',
    answer:
        'A banda passa a ficar ativa e visível quando pelo menos 2 integrantes com perfil individual/profissional aceitam o convite da banda.',
    tags: ['banda', 'ativação', 'integrantes', 'visibilidade'],
  ),
  FAQItem(
    category: FAQCategories.bands,
    question: 'Quem administra a banda criada no onboarding?',
    answer:
        'O usuário que cria a banda entra como administrador inicial da banda. Depois, ele pode gerenciar convites, acompanhar quem aceitou e montar a composição até a banda ser ativada.',
    tags: ['admin', 'banda', 'convites', 'integrantes'],
  ),
  FAQItem(
    category: FAQCategories.matchpointSearch,
    question: 'Como funciona o MatchPoint?',
    answer:
        'O MatchPoint cruza afinidade musical, objetivos e localização para sugerir conexões mais relevantes entre perfis compatíveis.',
    tags: ['matchpoint', 'afinidade', 'localização', 'conexão'],
  ),
  FAQItem(
    category: FAQCategories.matchpointSearch,
    question: 'Como pauso minha visibilidade no MatchPoint e na busca?',
    answer:
        'Em Configurações > Privacidade e Visibilidade, você pode desativar o MatchPoint e também remover seu perfil da Home e Busca geral.',
    tags: ['privacidade', 'visibilidade', 'matchpoint', 'busca'],
  ),
  FAQItem(
    category: FAQCategories.matchpointSearch,
    question: 'O que acontece quando dá match?',
    answer:
        'Quando existe interesse mútuo, o app cria um chat entre os perfis para que vocês conversem diretamente.',
    tags: ['match', 'chat', 'conversa'],
  ),
  FAQItem(
    category: FAQCategories.matchpointSearch,
    question: 'Por que não encontro perfis perto de mim?',
    answer:
        'Verifique se sua localização está completa e atualizada. O app usa cidade/estado e coordenadas aproximadas para melhorar busca e recomendações.',
    tags: ['busca', 'localização', 'cidade', 'geolocalização'],
  ),
  FAQItem(
    category: FAQCategories.chatSecurity,
    question: 'Como bloquear usuários no app?',
    answer:
        'Você pode gerenciar bloqueios em Configurações > Privacidade e Visibilidade. Perfis bloqueados deixam de interagir com você.',
    tags: ['bloquear', 'segurança', 'usuário'],
  ),
  FAQItem(
    category: FAQCategories.chatSecurity,
    question: 'Como reportar comportamento inadequado?',
    answer:
        'Abra um ticket de suporte na categoria Reportar um Problema, descreva o ocorrido e anexe evidências (prints) quando possível.',
    tags: ['denúncia', 'abuso', 'comportamento', 'ticket'],
  ),
  FAQItem(
    category: FAQCategories.chatSecurity,
    question: 'O Mube intermedia contratos ou pagamentos entre usuários?',
    answer:
        'Não. O Mube facilita conexões entre perfis, mas não intermedia pagamentos ou contratos entre usuários neste momento.',
    tags: ['contrato', 'pagamento', 'intermediação'],
  ),
  FAQItem(
    category: FAQCategories.privacyLgpd,
    question: 'Quais dados pessoais o Mube coleta?',
    answer:
        'Coletamos dados de cadastro, perfil, localização e uso do app para operação da plataforma, conexões entre perfis, segurança e melhoria contínua do produto.',
    tags: ['dados', 'coleta', 'perfil', 'localização'],
  ),
  FAQItem(
    category: FAQCategories.privacyLgpd,
    question: 'O Mube vende meus dados?',
    answer:
        'Não. O Mube não vende dados pessoais. O compartilhamento ocorre apenas quando necessário para operação do serviço, como provedores de tecnologia e obrigações legais.',
    tags: ['compartilhamento', 'dados', 'venda'],
  ),
  FAQItem(
    category: FAQCategories.privacyLgpd,
    question: 'Como exerço meus direitos da LGPD?',
    answer:
        'Você pode solicitar acesso, correção, exclusão e outros direitos do titular entrando em contato pelo e-mail suporte@mube.app.',
    tags: ['lgpd', 'direitos', 'acesso', 'exclusão'],
  ),
  FAQItem(
    category: FAQCategories.privacyLgpd,
    question: 'O app coleta dados de pagamento?',
    answer:
        'Não. No momento, o Mube não coleta dados de pagamento e não oferece assinatura, créditos ou compra interna de conteúdo e funcionalidades digitais.',
    tags: ['pagamento', 'cobrança', 'financeiro'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'Como abrir um ticket com mais chance de resolução rápida?',
    answer:
        'Use um assunto claro, descreva o passo a passo do problema, informe contexto (tipo de perfil e ação realizada) e inclua anexos quando necessário.',
    tags: ['ticket', 'suporte', 'boas práticas', 'atendimento'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'Posso enviar anexos no ticket?',
    answer:
        'Sim. Você pode anexar até 3 imagens por chamado para ajudar na análise técnica.',
    tags: ['anexo', 'imagem', 'ticket'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'Como acompanho o andamento do chamado?',
    answer:
        'Acesse Meus Tickets para ver status e detalhes. Os estados mais comuns são: Aberto, Em Análise, Resolvido e Fechado.',
    tags: ['status', 'ticket', 'chamado', 'andamento'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'Em quanto tempo recebo retorno?',
    answer:
        'O tempo varia conforme complexidade e fila de atendimento. Chamados com descrição completa e anexos costumam ser analisados com mais agilidade.',
    tags: ['prazo', 'retorno', 'tempo', 'suporte'],
  ),
  FAQItem(
    category: FAQCategories.supportTickets,
    question: 'O aplicativo é gratuito?',
    answer:
        'Sim. O Mube é gratuito para download e para uso das funcionalidades disponíveis atualmente. Não há assinatura, compra interna ou desbloqueio pago no app neste momento.',
    tags: ['gratuito', 'plano', 'assinatura', 'preço'],
  ),
];
