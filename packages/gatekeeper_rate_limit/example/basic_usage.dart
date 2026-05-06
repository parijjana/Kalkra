import 'package:gatekeeper_rate_limit/gatekeeper_rate_limit.dart';

void main() async {
  // Setup: 1 request per second, 3 burst capacity
  final limiter = RateLimiter(capacity: 3, refillRatePerSecond: 1);
  final clientId = "user-123";

  print("--- Attempting burst ---");
  for (int i = 1; i <= 5; i++) {
    final result = limiter.consume(clientId);
    if (result.allowed) {
      print("Request $i: ALLOWED (Tokens left: ${result.remainingTokens})");
    } else {
      print("Request $i: REJECTED (Retry after: ${result.retryAfter.inMilliseconds}ms)");
    }
  }

  print("\n--- Waiting 2 seconds ---");
  await Future.delayed(Duration(seconds: 2));

  print("\n--- Attempting recovery check ---");
  final result = limiter.consume(clientId);
  print("Request 6: ${result.allowed ? 'ALLOWED' : 'REJECTED'}");
}
