import 'package:flutter/material.dart';

class ResponsiveScaffold extends StatefulWidget {
  final Widget sidePanel;
  final Widget body;
  final String? title;
  final Widget? floatingActionButton;

  const ResponsiveScaffold({
    Key? key,
    required this.sidePanel,
    required this.body,
    this.title,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  State<ResponsiveScaffold> createState() => _ResponsiveScaffoldState();
}

class _ResponsiveScaffoldState extends State<ResponsiveScaffold> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 600) {
          // Desktop/tablet: show side panel
          return Scaffold(
            appBar: widget.title != null ? AppBar(title: Text(widget.title!)) : null,
            body: Row(
              children: [
                Container(
                  width: 220,
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: widget.sidePanel,
                ),
                Expanded(child: widget.body),
              ],
            ),
            floatingActionButton: widget.floatingActionButton,
          );
        } else {
          // Mobile: use Drawer
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.title ?? ''),
              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            drawer: Drawer(child: widget.sidePanel),
            body: widget.body,
            floatingActionButton: widget.floatingActionButton,
          );
        }
      },
    );
  }
} 