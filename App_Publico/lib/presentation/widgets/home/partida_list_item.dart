import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatar a data
import '../../../models/partida_model.dart';

class PartidaListItem extends StatelessWidget {
  final Partida partida;
  final VoidCallback? onTap;

  const PartidaListItem({
    super.key,
    required this.partida,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Formatação da data (Ex: 15 Out)
    final String dataFormatada = partida.iniciadaEm != null
        ? DateFormat('dd MMM', 'pt_BR').format(partida.iniciadaEm!)
        : '--/--';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Coluna da Data/Hora
            Column(
              children: [
                Text(
                  dataFormatada.toUpperCase(),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(partida.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    partida.status == 'encerrada' ? 'FIM' : 'AGEND',
                    style: TextStyle(
                      color: _getStatusColor(partida.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            
            // Times e Placar
            Expanded(
              child: Column(
                children: [
                  _buildTeamRow(
                    partida.equipeA?.atletica?.nome ?? 'Time A',
                    partida.equipeA?.atletica?.escudoUrl,
                    partida.placarA,
                    venceu: partida.placarA > partida.placarB,
                  ),
                  const SizedBox(height: 8),
                  _buildTeamRow(
                    partida.equipeB?.atletica?.nome ?? 'Time B',
                    partida.equipeB?.atletica?.escudoUrl,
                    partida.placarB,
                    venceu: partida.placarB > partida.placarA,
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamRow(String nome, String? logoUrl, int placar, {bool venceu = false}) {
    return Row(
      children: [
        // Escudo ou Inicial
        CircleAvatar(
          radius: 12,
          backgroundColor: Colors.grey[200],
          backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
          child: logoUrl == null
              ? Text(nome[0], style: const TextStyle(fontSize: 10, color: Colors.black54))
              : null,
        ),
        const SizedBox(width: 10),
        
        // Nome do Time
        Expanded(
          child: Text(
            nome,
            style: TextStyle(
              fontSize: 15,
              fontWeight: venceu ? FontWeight.bold : FontWeight.w500,
              color: venceu ? Colors.black : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        // Placar
        Text(
          placar.toString(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: venceu ? const Color(0xFFF85C39) : Colors.black54,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'encerrada': return Colors.grey;
      case 'em_andamento': return const Color(0xFFF85C39);
      default: return Colors.blueAccent;
    }
  }
}