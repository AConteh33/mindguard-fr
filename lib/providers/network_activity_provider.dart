import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mindguard_fr/utils/network_monitoring_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NetworkActivityProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _dnsQueries = [];
  Map<String, dynamic> _networkStatistics = {};
  bool _isLoading = false;
  bool _isMonitoring = false;

  // Stream subscriptions for real-time updates
  StreamSubscription? _dnsQueriesSubscription;

  List<Map<String, dynamic>> get dnsQueries => _dnsQueries;
  Map<String, dynamic> get networkStatistics => _networkStatistics;
  bool get isLoading => _isLoading;
  bool get isMonitoring => _isMonitoring;

  /// Start DNS monitoring
  Future<void> startDNSMonitoring(String userId) async {
    try {
      _isMonitoring = true;
      notifyListeners();

      // Start DNS monitoring
      await NetworkMonitoringHelper.startDNSMonitoring(userId);

      if (kDebugMode) print('DNS monitoring started for user: $userId');
    } catch (e) {
      if (kDebugMode) print('Error starting DNS monitoring: $e');
      _isMonitoring = false;
      notifyListeners();
    }
  }

  /// Stop DNS monitoring
  Future<void> stopDNSMonitoring() async {
    try {
      _isMonitoring = false;
      notifyListeners();

      await NetworkMonitoringHelper.stopDNSMonitoring();

      if (kDebugMode) print('DNS monitoring stopped');
    } catch (e) {
      if (kDebugMode) print('Error stopping DNS monitoring: $e');
    }
  }

  /// Load DNS queries from Firestore with real-time listener
  Future<void> loadDNSQueriesWithListener(String childId, {int limitDays = 7}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: limitDays));

      // Cancel existing subscription if any
      _dnsQueriesSubscription?.cancel();

      // Create a real-time listener for DNS queries for the specific child
      _dnsQueriesSubscription = _firestore
          .collection('dns_queries')
          .where('childId', isEqualTo: childId)
          .orderBy('timestamp', descending: true)
          .limit(500)
          .snapshots()
          .listen((snapshot) {
        // Filter by date range in UI instead of query
        _dnsQueries = snapshot.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final timestamp = data['timestamp'] as int;
              return timestamp >= startDate.millisecondsSinceEpoch;
            })
            .map((doc) => doc.data())
            .toList();
        if (kDebugMode) print('Updated DNS queries with ${_dnsQueries.length} records');
        notifyListeners();
      });
    } catch (e) {
      if (kDebugMode) print('Error setting up DNS queries listener: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load DNS queries from Firestore (one-time load)
  Future<void> loadDNSQueries(String childId, {int limitDays = 7}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: limitDays));

      final snapshot = await _firestore
          .collection('dns_queries')
          .where('childId', isEqualTo: childId)
          .orderBy('timestamp', descending: true)
          .limit(500)
          .get();

      // Filter by date range in UI instead of query
      _dnsQueries = snapshot.docs
          .where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final timestamp = data['timestamp'] as int;
            return timestamp >= startDate.millisecondsSinceEpoch;
          })
          .map((doc) => doc.data())
          .toList();

      if (kDebugMode) print('Loaded ${_dnsQueries.length} DNS query records');
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error loading DNS queries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculate network statistics
  Future<void> loadNetworkStatistics(String childId, {int limitDays = 7}) async {
    try {
      final now = DateTime.now();
      final startDate = now.subtract(Duration(days: limitDays));

      // Get DNS query stats
      final dnsSnapshot = await _firestore
          .collection('dns_queries')
          .where('childId', isEqualTo: childId)
          .get();

      // Filter by date range in UI instead of query
      final filteredDocs = dnsSnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = data['timestamp'] as int;
        return timestamp >= startDate.millisecondsSinceEpoch;
      }).toList();

      // Calculate top domains
      final domainCounts = <String, int>{};
      for (var doc in filteredDocs) {
        final data = doc.data();
        final domain = data['domain'] as String? ?? 'unknown';
        domainCounts[domain] = (domainCounts[domain] ?? 0) + 1;
      }

      final topDomains = domainCounts.entries
          .toList()
          .sortedByDescending((e) => e.value)
          .take(10)
          .map((e) => {'domain': e.key, 'count': e.value})
          .toList();

      _networkStatistics = {
        'totalDNSQueries': dnsSnapshot.docs.length,
        'uniqueDomains': domainCounts.length,
        'topDomains': topDomains,
        'limitDays': limitDays,
      };

      if (kDebugMode) print('Network statistics calculated');
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Error calculating network statistics: $e');
    }
  }

  /// Get combined network and DNS activity with real-time listeners
  Future<void> loadCombinedActivityWithListeners(
    String childId, {
    int limitDays = 7,
  }) async {
    try {
      await loadDNSQueriesWithListener(childId, limitDays: limitDays);
      await loadNetworkStatistics(childId, limitDays: limitDays);
    } catch (e) {
      if (kDebugMode) print('Error loading combined activity: $e');
    }
  }

  /// Get DNS activity
  Future<List<Map<String, dynamic>>> getDNSActivity(
    String childId, {
    int limitDays = 7,
  }) async {
    try {
      await loadDNSQueries(childId, limitDays: limitDays);
      await loadNetworkStatistics(childId, limitDays: limitDays);

      // Sort by timestamp
      _dnsQueries.sort((a, b) {
        final aTime = a['timestamp'] as int? ?? 0;
        final bTime = b['timestamp'] as int? ?? 0;
        return bTime.compareTo(aTime);
      });

      return _dnsQueries;
    } catch (e) {
      if (kDebugMode) print('Error getting DNS activity: $e');
      return [];
    }
  }

  /// Clear all data
  void clearData() {
    _dnsQueries = [];
    _networkStatistics = {};
    notifyListeners();
  }

  // Cancel all subscriptions when provider is disposed
  @override
  void dispose() {
    _dnsQueriesSubscription?.cancel();
    super.dispose();
  }
}

extension on List<MapEntry<String, int>> {
  List<MapEntry<String, int>> sortedByDescending(int Function(MapEntry<String, int>) selector) {
    sort((a, b) => selector(b).compareTo(selector(a)));
    return this;
  }
}