import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// A badge displaying a QR code for joining the lobby.
class QRBadge extends StatelessWidget {
  final String connectionString;
  final bool isDesktop;

  const QRBadge({
    super.key,
    required this.connectionString,
    this.isDesktop = false,
  });

  @override
  Widget build(BuildContext context) {
    return isDesktop ? _buildDesktop() : _buildMobile();
  }

  Widget _buildDesktop() {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQR(160),
          const SizedBox(height: 16),
          const Text(
            'JOIN ARENA',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          _buildAddress(),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildQR(80),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SCAN TO JOIN',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                    letterSpacing: 2,
                    fontSize: 12,
                  ),
                ),
                _buildAddress(),
                const Text(
                  'Invite friends to join locally.',
                  style: TextStyle(fontSize: 10, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQR(double size) {
    return QrImageView(
      data: connectionString,
      version: QrVersions.auto,
      size: size,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    );
  }

  Widget _buildAddress() {
    return Text(
      connectionString,
      style: const TextStyle(
        fontSize: 9,
        color: Colors.black45,
        fontFamily: 'monospace',
      ),
    );
  }
}
