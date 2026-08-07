import 'package:flutter/material.dart';
import '../core/utils/responsive_utils.dart';

/// Responsive builder that provides different widgets based on screen size
class ResponsiveBuilder extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.buildResponsiveLayout(
      context: context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Responsive card that adapts its padding and layout based on screen size
class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? elevation;
  final Color? color;
  final ShapeBorder? shape;
  final VoidCallback? onTap;
  final bool isGridItem;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation,
    this.color,
    this.shape,
    this.onTap,
    this.isGridItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? 
        EdgeInsets.all(context.responsiveCardPadding);
    
    final effectiveShape = shape ?? 
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius),
        );

    final card = Card(
      elevation: elevation ?? (isGridItem ? 2 : 4),
      color: color,
      shape: effectiveShape,
      child: Padding(
        padding: effectivePadding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: effectiveShape is RoundedRectangleBorder 
            ? effectiveShape.borderRadius as BorderRadius
            : null,
        child: card,
      );
    }

    return card;
  }
}

/// Responsive container that centers content with max width on larger screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;
  final Alignment alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? 
        ResponsiveUtils.getMaxContentWidth(context);
    
    final effectivePadding = padding ?? 
        EdgeInsets.symmetric(horizontal: context.responsiveSpacing);

    if (context.isMobile) {
      return Padding(
        padding: effectivePadding,
        child: child,
      );
    }

    return Container(
      alignment: alignment,
      padding: effectivePadding,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: child,
      ),
    );
  }
}

/// Responsive grid that adapts column count based on screen size
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;
  final double? mainAxisSpacing;
  final double? crossAxisSpacing;
  final double? childAspectRatio;
  final EdgeInsets? padding;
  final bool shrinkWrap;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.mainAxisSpacing,
    this.crossAxisSpacing,
    this.childAspectRatio,
    this.padding,
    this.shrinkWrap = true,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.buildResponsiveGrid(
      context: context,
      children: children,
      mobileColumns: mobileColumns,
      tabletColumns: tabletColumns,
      desktopColumns: desktopColumns,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      padding: padding,
      shrinkWrap: shrinkWrap,
    );
  }
}

/// Responsive list view that adapts item layout based on screen size
class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets? padding;
  final double? spacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.padding,
    this.spacing,
    this.shrinkWrap = true,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSpacing = spacing ?? context.responsiveSpacing;
    final effectivePadding = padding ?? 
        EdgeInsets.all(context.responsiveSpacing);

    return ListView.separated(
      padding: effectivePadding,
      shrinkWrap: shrinkWrap,
      physics: physics ?? (shrinkWrap ? const NeverScrollableScrollPhysics() : null),
      itemCount: children.length,
      separatorBuilder: (context, index) => SizedBox(height: effectiveSpacing),
      itemBuilder: (context, index) => children[index],
    );
  }
}

/// Responsive text that scales font size based on device type
class ResponsiveText extends StatelessWidget {
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final double? mobileFontSize;
  final double? tabletFontSize;
  final double? desktopFontSize;

  const ResponsiveText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.mobileFontSize,
    this.tabletFontSize,
    this.desktopFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium!;
    final fontSize = ResponsiveUtils.getValue(
      context,
      mobile: mobileFontSize ?? baseStyle.fontSize ?? 14,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );

    return Text(
      data,
      style: baseStyle.copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      softWrap: softWrap,
    );
  }
}

/// Responsive icon that scales size based on device type
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final double? size;
  final double? mobileSize;
  final double? tabletSize;
  final double? desktopSize;

  const ResponsiveIcon(
    this.icon, {
    super.key,
    this.color,
    this.size,
    this.mobileSize,
    this.tabletSize,
    this.desktopSize,
  });

  @override
  Widget build(BuildContext context) {
    final iconSize = size ?? ResponsiveUtils.getValue(
      context,
      mobile: mobileSize ?? context.responsiveIconSize,
      tablet: tabletSize,
      desktop: desktopSize,
    );

    return Icon(
      icon,
      color: color,
      size: iconSize,
    );
  }
}

/// Responsive button that adapts its size and padding based on screen size
class ResponsiveButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isFullWidth;
  final bool isPrimary;

  const ResponsiveButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isFullWidth = false,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    final horizontalPadding = context.isMobile ? 16.0 : 24.0;
    final verticalPadding = context.isMobile ? 12.0 : 16.0;
    final fontSize = context.isMobile ? 14.0 : 16.0;

    final button = ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null 
          ? Icon(icon, size: context.isMobile ? 18 : 20)
          : null,
      label: Text(
        label,
        style: TextStyle(fontSize: fontSize),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.responsiveBorderRadius),
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

/// Responsive scaffold that adapts layout based on device type
class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final bool useDrawerOnTablet;
  final bool showBackButton;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.drawer,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.useDrawerOnTablet = true,
    this.showBackButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final shouldUseDrawer = drawer != null && 
        (context.isMobile || (context.isTablet && useDrawerOnTablet));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        automaticallyImplyLeading: showBackButton,
        leading: shouldUseDrawer && !showBackButton
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
      ),
      drawer: shouldUseDrawer ? drawer : null,
      body: ResponsiveContainer(child: body),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Responsive layout that switches between column and row based on orientation
class ResponsiveLayout extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final double? spacing;
  final bool reverse;

  const ResponsiveLayout({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.spacing,
    this.reverse = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSpacing = spacing ?? context.responsiveSpacing;

    if (context.isLandscape && context.isTablet) {
      // Use row layout for landscape tablets
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: _buildChildren(context, effectiveSpacing),
      );
    }

    // Use column layout for portrait and mobile
    return Column(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      children: _buildChildren(context, effectiveSpacing),
    );
  }

  List<Widget> _buildChildren(BuildContext context, double spacing) {
    final effectiveChildren = reverse ? children.reversed.toList() : children;
    
    if (effectiveChildren.isEmpty) return [];

    final result = <Widget>[];
    for (int i = 0; i < effectiveChildren.length; i++) {
      result.add(effectiveChildren[i]);
      if (i < effectiveChildren.length - 1) {
        result.add(SizedBox(
          width: context.isLandscape && context.isTablet ? spacing : 0,
          height: context.isLandscape && context.isTablet ? 0 : spacing,
        ));
      }
    }
    return result;
  }
}
