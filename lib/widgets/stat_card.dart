import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String? trend;
  final bool isPositive;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    this.trend,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon with glass effect background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: iconBg, width: 1),
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 20),
          // Label and Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: Color(0xFF1A1C1E),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // Trend and Chevron
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        trend!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade300, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}
