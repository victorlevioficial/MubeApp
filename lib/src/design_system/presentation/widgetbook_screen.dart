import 'package:flutter/material.dart';
import '../widgetbook_app.dart';

class WidgetbookScreen extends StatelessWidget {
  const WidgetbookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // WidgetbookApp já cria seu próprio MaterialApp/Router,
    // então podemos retorná-lo diretamente.
    // Se houver conflitos de navegação, pode ser necessário abrir em nova rota/janela,
    // mas como uma tela isolada geralmente funciona bem.
    return const WidgetbookApp();
  }
}
