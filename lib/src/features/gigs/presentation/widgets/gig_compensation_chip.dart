import 'package:flutter/material.dart';

import '../../../../design_system/components/chips/app_chip.dart';
import '../../domain/gig.dart';

class GigCompensationChip extends StatelessWidget {
  const GigCompensationChip({super.key, required this.gig});

  final Gig gig;

  @override
  Widget build(BuildContext context) {
    return AppChip.skill(label: gig.displayCompensation);
  }
}
