import 'package:flutter/material.dart';

class ActionButtons extends StatelessWidget {
  final String? interactLabel;
  final VoidCallback onInteract;
  final VoidCallback onPhone;
  final bool running;
  final ValueChanged<bool> onRunChanged;

  const ActionButtons({
    super.key,
    required this.interactLabel,
    required this.onInteract,
    required this.onPhone,
    required this.running,
    required this.onRunChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 12,
      bottom: 12,
      child: SafeArea(
        // Bottom inset only so left/right gutters stay symmetric
        // (matching the joystick's 12px) on cutout phones.
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (interactLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ElevatedButton.icon(
                  onPressed: onInteract,
                  icon: const Icon(Icons.touch_app),
                  label: Text(interactLabel!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade700,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _roundBtn(
                  icon: running ? Icons.directions_run : Icons.directions_walk,
                  label: 'RUN',
                  active: running,
                  onTap: () => onRunChanged(!running),
                ),
                const SizedBox(width: 8),
                _roundBtn(
                  icon: Icons.smartphone,
                  label: 'PHONE',
                  onTap: onPhone,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: active ? Colors.green.shade700 : Colors.black.withAlpha(150),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white70),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }
}
