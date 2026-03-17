class NetworkRateLimiter {
  final int maxRequests;
  final Duration duration;
  final Map<String, List<DateTime>> _clientRequests = {};

  NetworkRateLimiter({required this.maxRequests, required this.duration});

  bool isRefused(String? clientIp) {
    final now = DateTime.now();

    // Refuse connection if the client IP is undefined
    if (clientIp == null) return true;

    final requests = _clientRequests.putIfAbsent(clientIp, () => []);
    requests.removeWhere((time) => now.difference(time) > duration);

    if (requests.length >= maxRequests) {
      return true;
    }

    requests.add(now);
    return false;
  }
}
