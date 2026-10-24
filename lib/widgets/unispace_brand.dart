import 'package:flutter/material.dart';
import '../core/brand_palette.dart';

abstract final class UniSpaceBrand {
  static const forest = UniSpaceColors.forest;
  static const ivory = UniSpaceColors.ivory;
  static const emerald = UniSpaceColors.emerald;
  static const asset = 'assets/brand/university-mark.png';
}

/// Shared approved campus artwork; never recolored by the user's accent theme.
class UniSpaceBrandMark extends StatelessWidget {
  const UniSpaceBrandMark({super.key, this.width = 180});
  final double width;
  @override
  Widget build(BuildContext context) => Semantics(
        image: true,
        label: 'UniSpace',
        child: ClipRRect(
            borderRadius: BorderRadius.circular(width * .23),
            child: Image.asset(UniSpaceBrand.asset,
                width: width,
                height: width,
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                cacheWidth:
                    (width * MediaQuery.devicePixelRatioOf(context)).ceil())),
      );
}
