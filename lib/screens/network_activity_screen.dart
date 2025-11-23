import 'package:flutter/material.dart';
import 'package:mindguard_fr/models/child_model.dart';
import 'package:mindguard_fr/providers/network_activity_provider.dart';
import 'package:mindguard_fr/widgets/section_header.dart';
import 'package:mindguard_fr/widgets/visual/animated_background_visual.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class NetworkActivityScreen extends StatefulWidget {
  final ChildModel child;
  final bool showAppBar;

  const NetworkActivityScreen({
    super.key,
    required this.child,
    this.showAppBar = true,
  });

  @override
  State<NetworkActivityScreen> createState() => _NetworkActivityScreenState();
}

class _NetworkActivityScreenState extends State<NetworkActivityScreen> {
  int _selectedDays = 7;
  String _viewMode = 'domains'; // 'domains', 'activity', 'stats'

  @override
  void initState() {
    super.initState();
    _loadNetworkActivity();
  }

  Future<void> _loadNetworkActivity() async {
    final provider = Provider.of<NetworkActivityProvider>(context, listen: false);
    await provider.loadCombinedActivityWithListeners(widget.child.childId, limitDays: _selectedDays);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text('${widget.child.childName}\'s Network Activity'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: AnimatedBackgroundVisual(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Network Activity Monitor',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Real-time monitoring of all network connections and DNS queries',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Filter controls
                    Row(
                      children: [
                        Expanded(
                          child: ShadCard(
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  const Text('Last '),
                                  DropdownButton<int>(
                                    value: _selectedDays,
                                    items: [1, 7, 30, 90]
                                        .map((days) => DropdownMenuItem(
                                              value: days,
                                              child: Text('$days days'),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _selectedDays = value);
                                        _loadNetworkActivity();
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ShadCard(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                _buildViewModeButton(
                                  'domains',
                                  Icons.domain,
                                  'Domains',
                                  theme,
                                ),
                                _buildViewModeButton(
                                  'activity',
                                  Icons.list,
                                  'Activity',
                                  theme,
                                ),
                                _buildViewModeButton(
                                  'stats',
                                  Icons.bar_chart,
                                  'Stats',
                                  theme,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Statistics overview
                    _buildStatisticsOverview(),
                    const SizedBox(height: 20),
                    // Content based on view mode
                    if (_viewMode == 'domains') _buildDomainsView(),
                    if (_viewMode == 'activity') _buildActivityView(),
                    if (_viewMode == 'stats') _buildStatsView(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewModeButton(
    String mode,
    IconData icon,
    String label,
    ThemeData theme,
  ) {
    final isSelected = _viewMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: label,
        child: IconButton(
          icon: Icon(
            icon,
            color: isSelected ? theme.colorScheme.primary : Colors.grey,
            size: 20,
          ),
          onPressed: () => setState(() => _viewMode = mode),
        ),
      ),
    );
  }

  Widget _buildStatisticsOverview() {
    return Consumer<NetworkActivityProvider>(
      builder: (context, provider, child) {
        if (provider.networkStatistics.isEmpty) {
          return const SizedBox.shrink();
        }

        final stats = provider.networkStatistics;
        final totalDNS = stats['totalDNSQueries'] ?? 0;
        final uniqueDomains = stats['uniqueDomains'] ?? 0;

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'DNS Queries',
                totalDNS.toString(),
                Icons.dns,
                Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Unique Domains',
                uniqueDomains.toString(),
                Icons.domain,
                Colors.green,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDomainsView() {
    return Consumer<NetworkActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = provider.networkStatistics;
        final topDomains = stats['topDomains'] ?? [];

        if (topDomains.isEmpty) {
          return ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.domain,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Domain Data',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No network activity detected in the selected period',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Top Domains Accessed'),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topDomains.length,
              itemBuilder: (context, index) {
                final domain = topDomains[index];
                final domainName = domain['domain'] ?? 'Unknown';
                final count = domain['count'] ?? 0;
                final percentage = ((count / (stats['totalDNSQueries'] ?? 1)) * 100).toStringAsFixed(1);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ShadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.language,
                                size: 24,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      domainName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$count connections',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$percentage%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: count / (stats['totalDNSQueries'] ?? 1),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityView() {
    return Consumer<NetworkActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final combinedActivity = [
          ...provider.dnsQueries,
        ];

        if (combinedActivity.isEmpty) {
          return ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.list,
                    size: 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Recent Network Activity'),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: combinedActivity.take(50).length,
              itemBuilder: (context, index) {
                final activity = combinedActivity[index];
                final domain = activity['domain'] as String? ?? 'Unknown';
                final type = activity['type'] as String? ?? 'UNKNOWN';
                final date = activity['date'] as String? ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ShadCard(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(
                            _getActivityIcon(type),
                            size: 20,
                            color: _getActivityColor(type),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  domain,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  date,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getActivityColor(type).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: _getActivityColor(type),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsView() {
    return Consumer<NetworkActivityProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = provider.networkStatistics;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(title: 'Network Statistics'),
            const SizedBox(height: 12),
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatRow(
                      'Total DNS Queries',
                      '${stats['totalDNSQueries'] ?? 0}',
                      Icons.dns,
                    ),
                    const Divider(height: 20),
                    _buildStatRow(
                      'Unique Domains',
                      '${stats['uniqueDomains'] ?? 0}',
                      Icons.domain,
                    ),
                    const Divider(height: 20),
                    _buildStatRow(
                      'Analysis Period',
                      'Last ${stats['limitDays'] ?? 7} days',
                      Icons.calendar_today,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Connection Types'),
            const SizedBox(height: 12),
            ShadCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildConnectionTypeRow('DNS Queries', Icons.dns, Colors.purple),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionTypeRow(String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'DNS_QUERY':
        return Icons.dns;
      default:
        return Icons.language;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'DNS_QUERY':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }
}