import 'package:flutter/material.dart';
import '../models/sensor_node.dart';
import '../services/data_service.dart';
import '../theme/design_tokens.dart';
import '../screens/node_detail_screen.dart';

class NodeSearchDelegate extends SearchDelegate<SensorNode?> {
  final DataService _data = DataService();

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = DesignTokens.isDark ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: DesignTokens.bg,
      appBarTheme: AppBarTheme(
        backgroundColor: DesignTokens.surface,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: DesignTokens.textMuted, fontFamily: 'RobotoMono', fontSize: 16),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: Icon(Icons.clear_rounded, color: DesignTokens.textSecondary),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: DesignTokens.textPrimary, size: 20),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSuggestions(context);
  }

  Widget _buildSuggestions(BuildContext context) {
    final matches = _data.nodes.where((n) {
      final q = query.toLowerCase();
      return n.id.toLowerCase().contains(q) || n.location.toLowerCase().contains(q);
    }).toList();

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: DesignTokens.textMuted.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('NO MATCHING NODES',
              style: TextStyle(color: DesignTokens.textMuted, fontFamily: 'RobotoMono', fontSize: 12, letterSpacing: 1),
            ),
          ],
        ),
      );
    }

    return Container(
      color: DesignTokens.bg,
      child: ListView.builder(
        itemCount: matches.length,
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemBuilder: (context, i) {
          final node = matches[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: DesignTokens.cyan.withValues(alpha: 0.1),
                borderRadius: DesignTokens.r8,
                border: Border.all(color: DesignTokens.cyan.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.router_rounded, color: DesignTokens.cyan, size: 20),
            ),
            title: Text(node.id, 
              style: TextStyle(color: DesignTokens.textPrimary, fontWeight: FontWeight.bold, fontFamily: 'RobotoMono'),
            ),
            subtitle: Text(node.location,
              style: TextStyle(color: DesignTokens.textSecondary, fontSize: 11, letterSpacing: 0.5),
            ),
            trailing: Icon(Icons.arrow_forward_ios_rounded, color: DesignTokens.textMuted, size: 14),
            onTap: () {
              close(context, node);
              Navigator.push(context, MaterialPageRoute(builder: (_) => NodeDetailScreen(node: node)));
            },
          );
        },
      ),
    );
  }
}
