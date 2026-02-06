import 'package:flutter/material.dart';

import '../../foundations/tokens/app_colors.dart';
import '../../foundations/tokens/app_radius.dart';
import '../../foundations/tokens/app_spacing.dart';
import 'app_text_field.dart';

/// Campo de autocomplete do Design System Mube.
///
/// Combina um [AppTextField] com um [OverlayEntry] para exibir sugestões.
/// Ideal para buscas assíncronas (endereço, usuários, etc).
class AppAutocompleteField<T> extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;

  /// Lista de opções a serem exibidas no dropdown.
  final List<T> options;

  /// Builder para cada item da lista.
  final Widget Function(BuildContext, T) itemBuilder;

  /// Callback quando o usuário digita.
  final ValueChanged<String>? onChanged;

  /// Callback quando um item é selecionado.
  final ValueChanged<T> onSelected;

  /// Se true, exibe indicador de carregamento no suffix ou dropdown.
  final bool isLoading;

  /// Função para converter o objeto T em String para o campo de texto após seleção.
  final String Function(T) displayStringForOption;

  final String? Function(String?)? validator;
  final Widget? prefixIcon;

  const AppAutocompleteField({
    super.key,
    required this.label,
    required this.options,
    required this.itemBuilder,
    required this.onSelected,
    required this.displayStringForOption,
    this.controller,
    this.hint = '',
    this.onChanged,
    this.isLoading = false,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<AppAutocompleteField<T>> createState() =>
      _AppAutocompleteFieldState<T>();
}

class _AppAutocompleteFieldState<T> extends State<AppAutocompleteField<T>> {
  late TextEditingController _controller;
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(AppAutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Se a lista de opções mudou e temos foco, atualize ou abra o overlay
    if (widget.options != oldWidget.options) {
      if (_focusNode.hasFocus) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (widget.options.isNotEmpty) {
            if (_isOpen) {
              _overlayEntry?.markNeedsBuild();
            } else {
              _showOverlay();
            }
          } else {
            // Se não há opções, fecha (a menos que estejamos carregando?)
            // Aqui decidimos: se vazio, fecha
            if (!widget.isLoading) {
              _removeOverlay();
            }
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _removeOverlay();
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      if (widget.options.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _showOverlay();
        });
      }
    } else {
      // Pequeno delay para permitir o clique no item
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted && !_focusNode.hasFocus) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null || !mounted || !context.mounted) return;

    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;
    final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;

    // Calculate available space below
    final spaceBelow =
        screenHeight - (offset.dy + size.height) - viewInsetsBottom - 16;

    // If we have less than 200px below (typical dropdown height) and the element is not too high up
    final bool showAbove = spaceBelow < 200;

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                _focusNode.unfocus();
                _removeOverlay();
              },
              behavior: HitTestBehavior.translucent,
              child: Container(color: AppColors.transparent),
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: showAbove
                  ? Alignment.topLeft
                  : Alignment.bottomLeft,
              followerAnchor: showAbove
                  ? Alignment.bottomLeft
                  : Alignment.topLeft,
              offset: Offset(0.0, showAbove ? -4.0 : 4.0),
              child: Material(
                elevation: 8,
                color: AppColors.surface,
                borderRadius: AppRadius.all12,
                shadowColor: AppColors.background.withValues(alpha: 0.15),
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 250),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.all12,
                    border: Border.all(
                      color: AppColors.textTertiary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: widget.options.isEmpty
                      ? const SizedBox.shrink()
                      : ListView.separated(
                          padding: AppSpacing.v8,
                          shrinkWrap: true,
                          itemCount: widget.options.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            thickness: 0.5,
                            color: AppColors.textTertiary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final item = widget.options[index];
                            return InkWell(
                              onTap: () {
                                _selectItem(item);
                              },
                              child: widget.itemBuilder(context, item),
                            );
                          },
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) setState(() => _isOpen = false);
  }

  void _selectItem(T item) {
    _controller.text = widget.displayStringForOption(item);
    widget.onSelected(item);
    _removeOverlay();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: AppTextField(
        focusNode: _focusNode,
        controller: _controller,
        label: widget.label,
        hint: widget.hint,
        validator: widget.validator,
        prefixIcon: widget.prefixIcon,
        onChanged: (val) {
          widget.onChanged?.call(val);
          // Se o usuário digita, reabrimos o overlay se tiver opções ou loading
          if (!_isOpen && (widget.options.isNotEmpty || widget.isLoading)) {
            // _showOverlay é chamado no didUpdateWidget se options mudar,
            // mas se options já estiver lá e fechamos, reabrimos
            _showOverlay();
          }
        },
        suffixIcon: widget.isLoading
            ? const UnconstrainedBox(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              )
            : AnimatedRotation(
                turns: _isOpen ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              ),
      ),
    );
  }
}
