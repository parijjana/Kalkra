# Rate Limiting Best Practices

This document outlines the industry standards and architectural patterns used in the `gatekeeper_rate_limit` SDK.

## Core Algorithms

### 1. Token Bucket (Chosen for this SDK)
The **Token Bucket** algorithm is the industry standard for most modern APIs (used by Stripe, AWS, and Cloudflare).
- **Concept**: A "bucket" holds tokens. Every request consumes a token. Tokens are refilled at a constant rate.
- **Why**: It allows for bursts of traffic (up to the bucket capacity) while strictly enforcing a sustained average rate.
- **Reference**: [Stripe Engineering: Scaling your API with rate limiters](https://stripe.com/blog/rate-limiters)

### 2. Leaky Bucket
- **Concept**: Requests are added to a bucket and processed at a fixed, constant rate. If the bucket overflows, new requests are discarded.
- **Why**: Best for smoothing out traffic spikes completely.
- **Reference**: [Google Cloud: Rate limiting strategies](https://cloud.google.com/architecture/rate-limiting-strategies-techniques)

### 3. Fixed Window Counter
- **Concept**: Limits requests per fixed time window (e.g., 100 requests per hour).
- **Why**: Simple to implement but suffers from "edge bursts" (double the limit near the window boundary).

---

## Implementation Mandates

1.  **Fail-Open vs. Fail-Closed**: In high-security systems, rate limiters should **Fail-Closed** (reject traffic if the limiter service is unavailable).
2.  **Distributed State**: For online systems, the "bucket" count should be stored in a central fast-access store like **Redis**. For this local SDK, we use in-memory thread-safe maps.
3.  **HTTP Headers**: When a limit is hit, systems should return a `429 Too Many Requests` status and include a `Retry-After` header.
4.  **Granularity**: Limiting should be applied per **IP Address**, **User ID**, or **API Key**.

---

## Protocol Integrity: Replay Protection
A **Replay Attack** occurs when an attacker captures a valid, encrypted packet and resends it later to trigger the same action (e.g., re-submitting a winning math expression).

### Best Practice: Sequence Numbering (Monotonic Counters)
1.  **Concept**: Every packet includes a number that increases by 1.
2.  **Implementation**:
    - **Sender**: Maintains a counter and increments it for each packet.
    - **Receiver**: Stores the `last_seen_sequence` for every unique client.
    - **Validation**: If `incoming_sequence <= last_seen_sequence`, the packet is rejected as a replay or out-of-order delivery.
3.  **Why**: It provides immediate integrity without requiring synchronized clocks between devices.
4.  **Reference**: [IETF RFC 4303 (IPsec - Anti-Replay Service)](https://datatracker.ietf.org/doc/html/rfc4303#section-3.4.3)
