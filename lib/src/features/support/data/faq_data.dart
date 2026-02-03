class FAQItem {
  final String question;
  final String answer;
  final String category;

  const FAQItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

const List<FAQItem> kAppFAQs = [
  FAQItem(
    category: 'Conta e Perfil',
    question: 'Como altero minha senha?',
    answer:
        'Você pode alterar sua senha indo em Configurações > Conta > Alterar Senha. Um email de redefinição será enviado para você.',
  ),
  FAQItem(
    category: 'Conta e Perfil',
    question: 'Posso mudar meu tipo de perfil?',
    answer:
        'Atualmente, o tipo de perfil (Músico, Banda, etc) é definido no cadastro. Para alterar, entre em contato com o suporte.',
  ),
  FAQItem(
    category: 'MatchPoint',
    question: 'Como funciona o MatchPoint?',
    answer:
        'O MatchPoint conecta músicos e bandas baseando-se em afinidade musical e localização. Deslize para a direita para demonstrar interesse!',
  ),
  FAQItem(
    category: 'MatchPoint',
    question: 'O que acontece quando dá Match?',
    answer:
        'Quando ambos demonstram interesse, um chat é aberto automaticamente para vocês conversarem.',
  ),
  FAQItem(
    category: 'Geral',
    question: 'O aplicativo é gratuito?',
    answer:
        'Sim! O Mube é gratuito para download e uso das funcionalidades principais.',
  ),
];
