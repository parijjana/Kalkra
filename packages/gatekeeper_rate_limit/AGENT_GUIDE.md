# Gatekeeper Rate Limit - Agent Usage Guide

This SDK provides an industry-standard **Token Bucket** rate limiter. Use this to protect resources from abuse, prevent DDoS, or serialize traffic across multiple services.

## Core Concepts

1.  **Capacity (Burst)**: The maximum number of requests allowed in a single burst.
2.  **Refill Rate**: How many new requests are permitted per second.
3.  **Key-Based**: Limiting is applied per-key (e.g., unique IP address or User ID).

## Workflow for Agents

### 1. Initialization
Create a global or service-scoped limiter.

```dart
// Allows 5 requests per second, with a burst capacity of 10.
final limiter = RateLimiter(
  capacity: 10.0,
  refillRatePerSecond: 5.0,
);
```

### 2. Guarding a Resource
Call `consume()` before processing any request.

```dart
void onEventReceived(String clientIp, dynamic payload) {
  final result = limiter.consume(clientIp);
  
  if (!result.allowed) {
    print("REJECTED: Please wait ${result.retryAfter.inSeconds}s");
    return;
  }
  
  // Process request...
}
```

### 3. Cleanup
For long-running servers, periodically remove idle buckets.

```dart
// Remove buckets that haven't been active for 1 hour.
limiter.cleanup(Duration(hours: 1));
```

## Security Best Practices
- **Granularity**: Always use a unique identifier (like IP or Device ID) as the key.
- **Fail-Closed**: If logic depends on the limiter, ensure failure to check results in a rejection.
- **Dynamic Tuning**: Adjust capacity and refill rate based on the target system's CPU/Memory limits.
