import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_colors.dart';
import '../../domain/gig_type.dart';

Color gigAccentColor(GigType gigType) {
  switch (gigType) {
    case GigType.liveShow:
      return AppColors.primary;
    case GigType.privateEvent:
      return AppColors.warning;
    case GigType.recording:
      return AppColors.info;
    case GigType.rehearsalJam:
      return AppColors.success;
    case GigType.other:
      return AppColors.textSecondary;
  }
}

IconData gigTypeIcon(GigType gigType) {
  switch (gigType) {
    case GigType.liveShow:
      return Icons.mic_external_on_rounded;
    case GigType.privateEvent:
      return Icons.celebration_rounded;
    case GigType.recording:
      return Icons.graphic_eq_rounded;
    case GigType.rehearsalJam:
      return Icons.queue_music_rounded;
    case GigType.other:
      return Icons.music_note_rounded;
  }
}
