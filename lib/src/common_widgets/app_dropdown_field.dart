import 'package:flutter/material.dart';

import '../design_system/foundations/app_colors.dart';
import '../design_system/foundations/app_radius.dart';
import 'app_text_field.dart';

class AppDropdownField<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final String hint;

  const AppDropdownField({
    super.key,
    required this.label,
    required this.items,
    required this.onChanged,
    this.value,
    this.validator,
    this.hint = 'Selecione',
  });

  @override
  State<AppDropdownField<T>> createState() => _AppDropdownFieldState<T>();
}

class _AppDropdownFieldState<T> extends State<AppDropdownField<T>> {
  final TextEditingController _controller = TextEditingController();
  final GlobalKey _fieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _updateControllerText();
  }

  @override
  void didUpdateWidget(AppDropdownField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateControllerText();
    }
  }

  void _updateControllerText() {
    String newText = '';
    if (widget.value != null) {
      final selectedItem = widget.items.firstWhere(
        (item) => item.value == widget.value,
        orElse: () => widget.items.first,
      );
      // Extract text from child if it's a Text widget, otherwise vague string
      if (selectedItem.child is Text) {
        newText = (selectedItem.child as Text).data ?? '';
      } else {
        newText = widget.value.toString();
      }
    }

    // Only update if text actually changed to avoid notifyListeners loop / setState during build
    if (_controller.text != newText) {
      // Use addPostFrameCallback ensures we are not in the middle of a build phase
      // when stimulating the TextFormField listeners.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _controller.text = newText;
        }
      });
    }
  }

  Future<void> _showMenu() async {
    final RenderBox renderBox =
        _fieldKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Map items to PopupMenuItem
    final popupItems = widget.items.map((item) {
      return PopupMenuItem<T>(value: item.value, child: item.child);
    }).toList();

    final T? selectedValue = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height + 8, // Open below field with gap
        offset.dx + size.width,
        offset.dy + size.height + 300,
      ),
      items: popupItems,
      color: AppColors.surfaceHighlight, // Lighter for elevation in dark mode
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.all12),
      constraints: BoxConstraints(
        minWidth: size.width, // Match field width
        maxWidth: size.width,
      ),
      elevation: 12,
      shadowColor: Colors.black,
    );

    if (selectedValue != null) {
      widget.onChanged(selectedValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _showMenu,
          child: AbsorbPointer(
            // Prevent keyboard
            child: AppTextField(
              key: _fieldKey,
              controller: _controller,
              label: widget.label,
              hint: widget.hint,
              readOnly: true, // Prevent typing
              canRequestFocus: false, // Prevent Tab focus to avoid typing
              suffixIcon: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
              validator: (val) => widget.validator?.call(widget.value),
            ),
          ),
        ),
      ],
    );
  }
}
