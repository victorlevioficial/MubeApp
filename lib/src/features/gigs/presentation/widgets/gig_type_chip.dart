import 'package:flutter/material.dart';

import '../../../../design_system/components/chips/app_chip.dart';
import '../../domain/gig_type.dart';

class GigTypeChip extends StatelessWidget {
  const GigTypeChip({super.key, required this.gigType});

  final GigType gigType;

  @override
  Widget build(BuildContext context) {
    return AppChip.genre(label: gigType.label);
  }
}
