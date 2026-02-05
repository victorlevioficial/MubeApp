import 'package:flutter/material.dart';

import '../../../../design_system/foundations/tokens/app_spacing.dart';
import 'feed_item_skeleton.dart';

class FeedLoadingMore extends StatelessWidget {
  final int count;
  final EdgeInsets padding;

  const FeedLoadingMore({
    super.key,
    this.count = 2,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.s8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        children: List.generate(count, (_) => const FeedItemSkeleton()),
      ),
    );
  }
}
