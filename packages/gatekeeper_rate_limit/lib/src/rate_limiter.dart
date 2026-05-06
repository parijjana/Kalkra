import 'dart:async';
import 'package:meta/meta.dart';

/// Represents the result of a rate limit check.
class RateLimitResult {
  final bool allowed;
  final int remainingTokens;
  final Duration retryAfter;

  RateLimitResult({
    required this.allowed,
    required this.remainingTokens,
    this.retryAfter = Duration.zero,
  });
}

/// A thread-safe rate limiter implementing the Token Bucket algorithm.
class RateLimiter {
  final double capacity;
  final double refillRatePerSecond;
  
  final Map<String, _TokenBucket> _buckets = {};

  /// Creates a new rate limiter.
  /// [capacity] is the maximum number of tokens a bucket can hold (burst size).
  /// [refillRatePerSecond] is how many tokens are added per second.
  RateLimiter({
    required this.capacity,
    required this.refillRatePerSecond,
  });

  /// Checks if a request for the given [key] is allowed.
  /// Consumes [cost] tokens if allowed.
  RateLimitResult consume(String key, {double cost = 1.0}) {
    final bucket = _buckets.putIfAbsent(key, () => _TokenBucket(capacity));
    
    // 1. Refill tokens based on elapsed time
    bucket.refill(refillRatePerSecond, capacity);

    // 2. Check if enough tokens
    if (bucket.tokens >= cost) {
      bucket.tokens -= cost;
      return RateLimitResult(
        allowed: true,
        remainingTokens: bucket.tokens.floor(),
      );
    } else {
      // Calculate how long until we have enough tokens
      final needed = cost - bucket.tokens;
      final secondsToWait = needed / refillRatePerSecond;
      
      return RateLimitResult(
        allowed: false,
        remainingTokens: 0,
        retryAfter: Duration(milliseconds: (secondsToWait * 1000).ceil()),
      );
    }
  }

  /// Manually clears old buckets to prevent memory leaks in long-running processes.
  void cleanup(Duration maxAge) {
    final now = DateTime.now();
    _buckets.removeWhere((key, bucket) => 
      now.difference(bucket.lastRefill) > maxAge
    );
  }
}

class _TokenBucket {
  double tokens;
  DateTime lastRefill;

  _TokenBucket(double initialCapacity) 
    : tokens = initialCapacity, 
      lastRefill = DateTime.now();

  void refill(double rate, double capacity) {
    final now = DateTime.now();
    final elapsed = now.difference(lastRefill).inMicroseconds / 1000000.0;
    
    tokens = (tokens + (elapsed * rate)).clamp(0.0, capacity);
    lastRefill = now;
  }
}
