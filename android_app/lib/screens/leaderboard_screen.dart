import 'package:flutter/material.dart';
import '../services/gamification_service.dart';
import '../widgets/app_theme.dart';

class LeaderboardScreen extends StatelessWidget {
  final String codCosechero;
  final GamificationData? gamData;
  const LeaderboardScreen({super.key, required this.codCosechero, this.gamData});

  @override
  Widget build(BuildContext context) {
    final top7 = gamData?.leaderboardTop7 ?? [];
    final posicion = gamData?.posicionLeaderboard;
    final enTop7 = posicion != null && posicion <= 7;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text(
            'Top 7 esta semana',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          const Text('Racimos cosechados',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 20),

          if (top7.isEmpty)
            const Center(child: Text('Sin datos de leaderboard.\nSincroniza cuando tengas conexión.',
                textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)))
          else
            ...top7.asMap().entries.map((e) => _buildCard(e.value, e.key + 1)),

          // Show personal stats if not in top 7
          if (!enTop7 && posicion != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: AppColors.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tu posición: #$posicion',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Racimos esta semana: ${gamData?.racimosQuincena ?? 0}',
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const Text('Sigue así 💪', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> worker, int pos) {
    final esYo = worker['cod_cosechero'] == codCosechero ||
        (worker['es_yo'] as bool? ?? false);
    final nombre = worker['nombre'] as String? ?? '';
    final racimos = worker['racimos_semana'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: esYo ? AppColors.accent.withOpacity(0.15) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: esYo ? AppColors.accent : Colors.grey.shade200,
          width: esYo ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              _medal(pos),
              style: const TextStyle(fontSize: 28),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              esYo ? '$nombre (Tú)' : nombre,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: esYo ? AppColors.primary : Colors.black87),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$racimos',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
              const Text('racimos', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  String _medal(int pos) {
    switch (pos) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return ' $pos';
    }
  }
}
