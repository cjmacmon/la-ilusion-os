import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final Connectivity _connectivity = Connectivity();

  // connectivity_plus v5+ returns List<ConnectivityResult>
  static Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isOnlineList);

  static Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    return _isOnlineList(results);
  }

  static bool _isOnlineList(List<ConnectivityResult> results) =>
      results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);
}
