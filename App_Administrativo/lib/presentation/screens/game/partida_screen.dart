import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kyarem_eventos/models/partida_model.dart';
import 'package:kyarem_eventos/models/tipo_evento_model.dart';
import 'package:kyarem_eventos/models/atleta_model.dart';
import 'package:kyarem_eventos/presentation/screens/game/resumo_partida_screen.dart';
import 'package:kyarem_eventos/services/partida_service.dart';
import '../../widgets/layout/gradient_background.dart';
import '../../widgets/game/game_scoreboard.dart';
import '../../widgets/game/game_events_feed.dart';
import '../../widgets/game/game_timer_card.dart';
import '../../widgets/game/game_field.dart';
import '../../widgets/game/game_actions_panel.dart';

enum PeriodoPartida {
  naoIniciada,
  primeiroTempo,
  intervalo,
  segundoTempo,
  prorrogacao,
  acrescimo,
  finalizada,
}

class EventoPartida {
  final String tipo;
  final String jogadorNome;
  final int jogadorNumero;
  final Color corTime;
  final String horario;
  final DateTime timestamp;

  EventoPartida({
    required this.tipo,
    required this.corTime,
    required this.jogadorNome,
    required this.jogadorNumero,
    required this.horario,
    required this.timestamp,
  });

  String get descricao {
    switch (tipo) {
      case 'INICIO_1_TEMPO':
        return '🟢 Início do 1º Tempo';
      case 'INICIO_2_TEMPO':
        return '🟢 Início do 2º Tempo';
      case 'PARTIDA_PAUSADA':
        return '⏸️ Partida Pausada';
      case 'PARTIDA_RETOMADA':
        return '▶️ Partida Retomada';
      case 'PAUSA_TECNICA':
        return '🔴 Pausa Técnica';
      default:
        return '$tipo #$jogadorNumero';
    }
  }
}

class PartidaRunningScreen extends StatefulWidget {
  final Partida partida;
  const PartidaRunningScreen({super.key, required this.partida});

  @override
  State<PartidaRunningScreen> createState() => _PartidaRunningScreenState();
}

class _PartidaRunningScreenState extends State<PartidaRunningScreen> {
  static const int duracaoPrimeiroTempo = 1 * 10;
  static const int duracaoSegundoTempo = 20 * 60;

  final PartidaService _partidaService = PartidaService();
  List<TipoEventoEsporte> _tiposDeEventosDisponiveis = [];

  late int _golsA;
  late int _golsB;
  bool _carregandoAtletas = true;

  List<Atleta> _jogadoresA = [];
  List<Atleta> _jogadoresB = [];
  List<Atleta> _reservasA = [];
  List<Atleta> _reservasB = [];

  late PeriodoPartida _periodoAtual;
  PeriodoPartida? _periodoAntesDoAcrescimo;

  Timer? _timer;
  int _segundos = 0;
  bool _rodando = false;

  int _segundosPausa = 0;
  bool _partidaJaIniciou = false;

  bool _emPausaTecnica = false;
  String _timeEmPausaTecnica = '';
  int _segundosPausaTecnica = 0;

  Timer? _timerPausaTecnica;
  Timer? _timerAcrescimo;
  Timer? _timerProrrogacao;
  Timer? _timerPausa;

  Atleta? _jogadorSelecionado;

  final List<EventoPartida> _eventosPartida = [];

  @override
  void initState() {
    super.initState();
    _golsA = widget.partida.placarA;
    _golsB = widget.partida.placarB;
    _periodoAtual = _converterStatusParaPeriodo(widget.partida.status);
    if (_periodoAtual != PeriodoPartida.naoIniciada) _partidaJaIniciou = true;
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    await Future.wait([_buscarConfiguracoesDeEventos(), _carregarAtletas()]);
  }

  Future<void> _carregarAtletas() async {
    try {
      final resultados = await Future.wait([
        _partidaService.buscarInscritos(widget.partida.equipeAId),
        _partidaService.buscarInscritos(widget.partida.equipeBId),
      ]);

      setState(() {
        _distribuirJogadores(resultados[0], true);
        _distribuirJogadores(resultados[1], false);
        _carregandoAtletas = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar atletas: $e");
      setState(() => _carregandoAtletas = false);
    }
  }

  void _distribuirJogadores(List<dynamic> inscritos, bool isTimeA) {
    // 1. Definição fixa das cores
    final corFixa = isTimeA ? Colors.orange : Colors.blue;

    List<Atleta> titulares = [];
    List<Atleta> reservas = [];

    for (var cada in inscritos) {
      // Transforma o Map da API em objeto Atleta
      final atleta = Atleta.fromMap(cada);

      // 2. Injeta a cor fixa no objeto para uso posterior no feed/detalhes
      atleta.corTime = corFixa;

      if (atleta.ativo) {
        titulares.add(atleta);
      } else {
        reservas.add(atleta);
      }
    }

    setState(() {
      if (isTimeA) {
        _jogadoresA = titulares;
        _reservasA = reservas;
        _posicionarJogadoresNoCampo(_jogadoresA, true);
      } else {
        _jogadoresB = titulares;
        _reservasB = reservas;
        _posicionarJogadoresNoCampo(_jogadoresB, false);
      }
    });
  }

  void _posicionarJogadoresNoCampo(List<Atleta> jogadores, bool isTimeA) {
    final posicoesA = [
      const Offset(0.03, 0.45),
      const Offset(0.20, 0.45),
      const Offset(0.30, 0.15),
      const Offset(0.30, 0.75),
      const Offset(0.35, 0.45),
    ];
    final posicoesB = [
      const Offset(0.87, 0.45),
      const Offset(0.73, 0.45),
      const Offset(0.65, 0.15),
      const Offset(0.65, 0.75),
      const Offset(0.57, 0.45),
    ];

    final listaPosicoes = isTimeA ? posicoesA : posicoesB;

    for (int i = 0; i < jogadores.length; i++) {
      if (i < listaPosicoes.length) {
        jogadores[i].posicao = listaPosicoes[i];
      }
    }
  }

  // Função auxiliar para o mapeamento
  PeriodoPartida _converterStatusParaPeriodo(String status) {
    switch (status.toLowerCase()) {
      case 'agendada':
        return PeriodoPartida.naoIniciada;
      case '1° tempo':
        return PeriodoPartida.primeiroTempo;
      case '2° tempo':
        return PeriodoPartida.segundoTempo;
      case 'acréscimo':
        return PeriodoPartida.acrescimo;
      case 'intervalo':
        return PeriodoPartida.intervalo;
      case 'prorrogação':
        return PeriodoPartida.prorrogacao;
      case 'finalizada':
        return PeriodoPartida.finalizada;

      default:
        return PeriodoPartida.naoIniciada;
    }
  }

  Future<void> _buscarConfiguracoesDeEventos() async {
    try {
      final tipos = await _partidaService.buscarTiposDeEventoDaPartida(
        widget.partida.modalidadeId,
      );
      setState(() {
        _tiposDeEventosDisponiveis = tipos;
      });
      debugPrint(
        _tiposDeEventosDisponiveis.map((e) => e.nome).toList().toString(),
      );
    } catch (e) {}
  }

  // Método para registrar eventos sistêmicos usando as IDs reais carregadas
  Future<void> _registrarEventoSistemico(String nomeEventoNoBanco) async {
    // 1. Tentar encontrar o tipo de evento na lista carregada
    final tipoEvento = _tiposDeEventosDisponiveis.firstWhere(
      (e) => e.nome == nomeEventoNoBanco,
      orElse: () => TipoEventoEsporte(
        id: '',
        nome: nomeEventoNoBanco,
        esporteId: '',
        idx: 0,
      ),
    );

    // 2. Registrar visualmente no feed
    final eventoFeed = EventoPartida(
      tipo:
          nomeEventoNoBanco, // O switch do descricao no modelo vai precisar lidar com isso
      jogadorNome: '',
      jogadorNumero: 0,
      corTime: Colors.green,
      horario: _formatarTempo(_segundos),
      timestamp: DateTime.now(),
    );

    setState(() {
      _eventosPartida.insert(0, eventoFeed);
    });

    // 3. Salvar no Banco de Dados com a ID real
    if (tipoEvento.id.isNotEmpty) {
      debugPrint(
        'Salvando no banco: ${tipoEvento.nome} (ID: ${tipoEvento.id})',
      );
      await _partidaService.salvarEvento(
        partidaId: widget.partida.id,
        tipoEventoId: tipoEvento.id,
        tempoFormatado: _segundos,
      );
    }
  }

  // Variáveis para controle de prorrogação
  int _tempoProrrogacao = 0; // Em segundos
  bool _temProrrogacao = false;
  bool _estaNaProrrogacao = false;

  // Variáveis para controle de acrescimo
  int _tempoAcrescimo = 0; // Em segundos
  bool _temAcrescimo = false;
  bool _estaNoAcrescimo = false;

  // Controle de uso das pausas técnicas por período
  int _pausasTecnicasTimeAPrimeiroTempo = 0;
  int _pausasTecnicasTimeBPrimeiroTempo = 0;
  int _pausasTecnicasTimeASegundoTempo = 0;
  int _pausasTecnicasTimeBSegundoTempo = 0;

  @override
  void dispose() {
    _timer?.cancel(); // Limpar timer ao sair da tela
    _timerPausa?.cancel(); // Limpar timer de pausa
    _timerPausaTecnica?.cancel(); // Limpar timer de pausa técnica
    _timerAcrescimo?.cancel(); // Limpar timer do acrescimo
    _timerProrrogacao?.cancel(); // Limpar timer da prorrogação
    super.dispose();
  }

  // Verifica se deve finalizar período automaticamente
  void _verificarFimPeriodo() {
    switch (_periodoAtual) {
      case PeriodoPartida.primeiroTempo:
        if (_segundos >= duracaoPrimeiroTempo) {
          if (_temAcrescimo && !_estaNoAcrescimo) {
            // Iniciar acrescimo do primeiro tempo
            _iniciarAcrescimo();
            _estaNoAcrescimo = true;
          } else {
            _finalizarPrimeiroTempo();
          }
        }
        break;
      case PeriodoPartida.segundoTempo:
        if (_segundos >= duracaoSegundoTempo) {
          // 1º Prioridade: Se tem acréscimo e ainda não iniciou, inicia o acréscimo
          if (_temAcrescimo && !_estaNoAcrescimo) {
            _iniciarAcrescimo();
            _estaNoAcrescimo = true;
          }
          // 2º Prioridade: Se não tem acréscimo (ou já acabou) e tem prorrogação
          else if (_temProrrogacao && !_estaNaProrrogacao) {
            _iniciarProrrogacao();
            _estaNaProrrogacao = true;
          }
          // 3º Prioridade: Finaliza se não houver mais nada pendente
          else {
            _finalizarPartida();
          }
        }
        break;
      case PeriodoPartida.acrescimo:
        // Se os segundos contados atingirem o tempo definido no modal
        if (_segundos >= _tempoAcrescimo) {
          _timer?.cancel();
          setState(() {
            _rodando = false;
          });
          if (_periodoAntesDoAcrescimo == PeriodoPartida.primeiroTempo) {
            _finalizarPrimeiroTempo();
          } else {
            _finalizarPartida();
          }
        }
      case PeriodoPartida.prorrogacao:
        if (_segundos >= _tempoProrrogacao) {
          _finalizarPartida();
        }
        break;
      default:
        break;
    }
  }

  // Inicia período de prorrogação
  void _iniciarProrrogacao() {
    _timer?.cancel();
    setState(() {
      _rodando = false;
      _estaNaProrrogacao = true;
      _periodoAtual = PeriodoPartida.prorrogacao;
      _segundos = 0; // Reset do cronômetro para a prorrogação
    });

    _registrarEventoSistemico('PRORROGACAO');
  }

  // Inicia período de prorrogação
  void _iniciarAcrescimo() {
    _timer?.cancel(); // Cancela qualquer timer ativo

    setState(() {
      _periodoAntesDoAcrescimo = _periodoAtual;
      _rodando = true; // Já começa rodando
      _estaNoAcrescimo = true;
      _periodoAtual = PeriodoPartida.acrescimo;
      _segundos = 0; // Reset para contar o tempo do acréscimo
    });

    // Inicia o contador
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _segundos++;
          _verificarFimPeriodo(); // Esta função vai travar o tempo quando chegar no limite
        });
      }
    });

    _registrarEventoSistemico('ACRESCIMO');
  }

  // Finaliza o primeiro tempo automaticamente ou manualmente
  void _finalizarPrimeiroTempo() {
    _timer?.cancel();
    _timerPausa?.cancel();

    setState(() {
      _rodando = false;
      _periodoAtual = PeriodoPartida.intervalo;

      _partidaService.atualizarPartida(
        widget.partida.id,
        novoStatus: 'intervalo',
      );

      _temAcrescimo = false;
      _tempoAcrescimo = 0;
      _estaNoAcrescimo = false;
    });

    _registrarEventoSistemico('FIM_1_TEMPO');
    _registrarEventoSistemico('INTERVALO');
  }

  // Finaliza o segundo tempo e a partida
  void _finalizarPartida() {
    _timer?.cancel();
    _timerPausa?.cancel();

    setState(() {
      _rodando = false;
      _periodoAtual = PeriodoPartida.finalizada;
    });

    _registrarEventoSistemico('FIM_PARTIDA');
  }

  // Abre modal para selecionar tempo de prorrogação
  void _abrirModalProrrogacao() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Prorrogação'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o tempo de prorrogação em minutos:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos',
                border: OutlineInputBorder(),
                hintText: 'Ex: 5, 10, 15...',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final String input = controller.text.trim();
              final int? minutos = int.tryParse(input);

              if (minutos == null || minutos <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, digite um número válido de minutos!',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _registrarEventoSistemico('PRORROGACAO_DADA');

              setState(() {
                _tempoProrrogacao = minutos * 60; // Converter para segundos
                _temProrrogacao = true;
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Prorrogação de $minutos minutos configurada com sucesso!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Abre modal para selecionar tempo de prorrogação
  void _abrirModalAcrescimo() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Definir Acrescimo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Digite o tempo de acrescimo em minutos:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutos',
                border: OutlineInputBorder(),
                hintText: 'Ex: 5, 10, 15...',
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final String input = controller.text.trim();
              final int? minutos = int.tryParse(input);

              if (minutos == null || minutos <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Por favor, digite um número válido de minutos!',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              _registrarEventoSistemico('ACRESCIMO_DADO');

              setState(() {
                _tempoAcrescimo = minutos * 60; // Converter para segundos
                _temAcrescimo = true;
              });

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Acrescimo de $minutos minutos configurada com sucesso!',
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // Verifica se o time ainda pode usar pausa técnica no período atual
  bool _podeUsarPausaTecnica(bool isTimeA) {
    switch (_periodoAtual) {
      case PeriodoPartida.primeiroTempo:
      case PeriodoPartida.prorrogacao:
        return isTimeA
            ? _pausasTecnicasTimeAPrimeiroTempo < 1
            : _pausasTecnicasTimeBPrimeiroTempo < 1;
      case PeriodoPartida.segundoTempo:
        return isTimeA
            ? _pausasTecnicasTimeASegundoTempo < 1
            : _pausasTecnicasTimeBSegundoTempo < 1;
      default:
        return false;
    }
  }

  // Inicia pausa técnica para um time
  void _iniciarPausaTecnica(bool isTimeA) {
    // 1. Pegar nomes corretos das equipes de dentro do objeto partida
    final nomeTimeA = widget.partida.equipeA?.nome ?? "Time A";
    final nomeTimeB = widget.partida.equipeB?.nome ?? "Time B";

    // Verificações de segurança
    if (_emPausaTecnica) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Já há uma pausa técnica em andamento!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_podeUsarPausaTecnica(isTimeA)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "${isTimeA ? nomeTimeA : nomeTimeB} já usou sua pausa técnica neste período!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pausar cronometro principal se estiver rodando
    if (_rodando) {
      _timer?.cancel();
      setState(() {
        _rodando = false;
      });
    }

    // Iniciar pausa técnica
    setState(() {
      _emPausaTecnica = true;
      _timeEmPausaTecnica = isTimeA ? nomeTimeA : nomeTimeB;
      _segundosPausaTecnica = 0;
    });

    // Incrementar contador do time no período atual
    switch (_periodoAtual) {
      case PeriodoPartida.primeiroTempo:
      case PeriodoPartida.prorrogacao:
        if (isTimeA) {
          _pausasTecnicasTimeAPrimeiroTempo++;
        } else {
          _pausasTecnicasTimeBPrimeiroTempo++;
        }
        break;
      case PeriodoPartida.segundoTempo:
        if (isTimeA) {
          _pausasTecnicasTimeASegundoTempo++;
        } else {
          _pausasTecnicasTimeBSegundoTempo++;
        }
        break;
      default:
        break;
    }

    // Timer de 1 minuto (60 segundos) para pausa técnica
    _timerPausaTecnica = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        // Verificação para evitar erros se a tela for fechada
        setState(() {
          _segundosPausaTecnica++;
          if (_segundosPausaTecnica >= 60) {
            _finalizarPausaTecnica();
          }
        });
      }
    });
  }

  // Finaliza pausa técnica manualmente ou automaticamente
  void _finalizarPausaTecnica() {
    _timerPausaTecnica?.cancel();

    setState(() {
      _emPausaTecnica = false;
    });

    _timeEmPausaTecnica = '';
    _segundosPausaTecnica = 0;
  }

  void _alternarCronometro() {
    setState(() {
      _rodando = !_rodando;

      if (_rodando) {
        switch (_periodoAtual) {
          case PeriodoPartida.naoIniciada:
            _periodoAtual = PeriodoPartida.primeiroTempo;
            _segundos = 0;
            _registrarEventoSistemico('INICIO_1_TEMPO');

            _partidaService.atualizarPartida(
              widget.partida.id,
              novoStatus: '1° tempo',
            );

            break;

          case PeriodoPartida.intervalo:
            _periodoAtual = PeriodoPartida.segundoTempo;
            _segundos = 0;
            _registrarEventoSistemico('INICIO_2_TEMPO');

            _partidaService.atualizarPartida(
              widget.partida.id,
              novoStatus: '2° tempo',
            );

            break;

          default:
            _registrarEventoSistemico('PARTIDA_RETOMADA');
            break;
        }

        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {
              _segundos++;
              _verificarFimPeriodo();
            });
          }
        });
        _timerPausa?.cancel();
        _partidaJaIniciou = true;
      } else {
        _timer?.cancel();
        if (_periodoAtual != PeriodoPartida.finalizada && !_emPausaTecnica) {
          _timerPausa = Timer.periodic(const Duration(seconds: 1), (timer) {
            if (mounted) setState(() => _segundosPausa++);
          });
          _registrarEventoSistemico('PARTIDA_PAUSADA');
        }
      }
    });
  }

  void _registrarEvento(TipoEventoEsporte tipoObjeto) {
    // 1. Validações de Estado da Partida (Mantidas)
    if (_periodoAtual == PeriodoPartida.naoIniciada) {
      _mostrarAviso(
        "Não é possível registrar eventos antes de iniciar a partida!",
        Colors.orange,
      );
      return;
    }

    if (_periodoAtual == PeriodoPartida.finalizada) {
      _mostrarAviso(
        "Não é possível registrar eventos com a partida encerrada!",
        Colors.red,
      );
      return;
    }

    if (_periodoAtual == PeriodoPartida.intervalo) {
      _mostrarAviso(
        "Não é possível registrar eventos durante o intervalo!",
        Colors.blue,
      );
      return;
    }

    if (_jogadorSelecionado == null) {
      _mostrarAviso("Selecione um jogador no campo primeiro!", Colors.red);
      return;
    }

    // 2. Extraímos o nome para facilitar as comparações lógicas
    final String nomeEvento = tipoObjeto.nome.trim();

    // 3. Tratamento especial para substituições
    if (nomeEvento.toLowerCase() == "substituição") {
      _abrirModalSubstituicaoNovo(); // O seu método de substituição já lida com o estado
      return;
    }

    // 4. Guardar informações do jogador e identificar o time
    final jogador = _jogadorSelecionado!;
    final isTimeA = _jogadoresA.contains(jogador);

    // 5. Criar objeto de evento para a UI (Feed)
    final novoEventoFeed = EventoPartida(
      tipo:
          tipoObjeto.nomeFormatado, // Usando o helper que você criou no modelo
      corTime: jogador.corTime ?? Colors.grey,
      jogadorNome: jogador.nome,
      jogadorNumero: jogador.numero,
      horario: _formatarTempo(_segundos),
      timestamp: DateTime.now(),
    );

    // 6. Atualização do Estado (Placar e Lista de Eventos)
    setState(() {
      // Lógica para aumentar placar se for GOL
      if (nomeEvento.toLowerCase() == "gol") {
        if (isTimeA) {
          _golsA++;
        } else {
          _golsB++;
        }

        _partidaService.atualizarPartida(
          widget.partida.id,
          golsA: _golsA,
          golsB: _golsB,
        );
      }

      // Adiciona no início da lista do feed
      _eventosPartida.insert(0, novoEventoFeed);

      // Limpa a seleção do jogador para evitar registros duplicados por erro
      _jogadorSelecionado = null;
    });

    // 7. Feedback visual para o usuário
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "${tipoObjeto.nomeFormatado} registrado: ${jogador.nome} (#${jogador.numero})",
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

    debugPrint('--- ⚽ NOVO EVENTO REGISTRADO ---');
    debugPrint('ID Tipo Evento: ${tipoObjeto.id}');
    debugPrint('Nome (DB):      ${tipoObjeto.nome}');
    debugPrint('Nome (Format):  ${tipoObjeto.nomeFormatado}');
    debugPrint('Atleta:         ${jogador.nome} (#${jogador.numero})');
    debugPrint('Tempo Partida:  ${_formatarTempo(_segundos)}');
    debugPrint('---------------------------------');
  }

  // Helper simples para reduzir repetição de código nas validações
  void _mostrarAviso(String mensagem, Color cor) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem), backgroundColor: cor));
  }

  String _formatarTempo(int totalSegundos) {
    int min = totalSegundos ~/ 60;
    int seg = totalSegundos % 60;
    return '${min.toString().padLeft(2, '0')}:${seg.toString().padLeft(2, '0')}';
  }

  void _abrirDetalhesJogador(Atleta jogador) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: jogador.corTime,
              child: Text(
                "#${jogador.numero}",
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              jogador.nome,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Status: Em campo",
              style: TextStyle(color: Colors.green),
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _infoStat("Gols", "1"),
                _infoStat("Faltas", "2"),
                _infoStat("Cartões", "0"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoStat(String label, String valor) {
    return Column(
      children: [
        Text(
          valor,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }

  // MOSTRA DIÁLOGO DE CONFIRMAÇÃO PARA SAIR DURANTE PARTIDA
  void _mostrarDialogoSaida() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Text(
                'Partida em Andamento',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: const Text(
            'A partida está em andamento! Para sair, você deve pausar o cronômetro primeiro.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.orange)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBotaoVoltar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Permite voltar da tela se a partida estiver finalizada ou não estiver rolando
          if (_periodoAtual == PeriodoPartida.finalizada || !_rodando) {
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  "Não é possível sair com a partida em andamento!",
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2D2D2D),
          padding: const EdgeInsets.all(16),
        ),
        child: Text(
          _periodoAtual == PeriodoPartida.finalizada
              ? "Voltar"
              : _rodando
              ? "Pause para sair"
              : "Voltar",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_rodando, // Só permite voltar se a partida não estiver rolando
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) {
        if (!didPop && _rodando) {
          _mostrarDialogoSaida();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            // 1. Fundo com Gradiente (Sempre visível)
            const GradientBackground(),

            // 2. Conteúdo Principal da UI
            SafeArea(
              child: Opacity(
                // Se estiver carregando, a UI fica semi-transparente
                opacity: _carregandoAtletas ? 0.3 : 1.0,
                child: IgnorePointer(
                  // Se estiver carregando, bloqueia cliques em tudo
                  ignoring: _carregandoAtletas,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        // Placar
                        GameScoreboard(
                          timeA: widget.partida.equipeA?.nome ?? "Time A",
                          timeB: widget.partida.equipeB?.nome ?? "Time B",
                          golsA: _golsA,
                          golsB: _golsB,
                          periodoAtual: _periodoAtual,
                          emPausaTecnica: _emPausaTecnica,
                          timeEmPausaTecnica: _timeEmPausaTecnica,
                          segundosPausaTecnica: _segundosPausaTecnica,
                          podeUsarPausaTecnica: _podeUsarPausaTecnica,
                          onPausaTecnicaIniciada: _iniciarPausaTecnica,
                          onPausaTecnicaFinalizada: _finalizarPausaTecnica,
                        ),

                        const SizedBox(height: 12),

                        // Feed de Eventos
                        GameEventsFeed(eventos: _eventosPartida),

                        const SizedBox(height: 12),

                        // Card do Cronómetro e Controles de Tempo
                        GameTimerCard(
                          segundos: _segundos,
                          rodando: _rodando,
                          partidaJaIniciou: _partidaJaIniciou,
                          periodoAtual: _periodoAtual,
                          emPausaTecnica: _emPausaTecnica,
                          timeEmPausaTecnica: _timeEmPausaTecnica,
                          segundosPausaTecnica: _segundosPausaTecnica,
                          segundosPausa: _segundosPausa,
                          tempoProrrogacao: _tempoProrrogacao,
                          temProrrogacao: _temProrrogacao,
                          temAcrescimo: _temAcrescimo,
                          tempoAcrescimo: _tempoAcrescimo,
                          onToggleCronometro: _alternarCronometro,
                          onFinalizarPrimeiroTempo: _finalizarPrimeiroTempo,
                          onFinalizarSegundoTempo: _finalizarPartida,
                          onAbrirModalProrrogacao: _abrirModalProrrogacao,
                          onAbrirModalAcrescimo: _abrirModalAcrescimo,
                        ),

                        const SizedBox(height: 16),

                        // Campo de Jogo com Jogadores
                        GameField(
                          jogadoresA: _jogadoresA,
                          jogadoresB: _jogadoresB,
                          jogadorSelecionado: _jogadorSelecionado,
                          onJogadorSelecionado: (jogador) {
                            setState(() => _jogadorSelecionado = jogador);
                          },
                          onJogadorDoubleTap: _abrirDetalhesJogador,
                        ),

                        const SizedBox(height: 16),

                        // Painel de Ações (Gols, Cartões, etc)
                        GameActionsPanel(
                          jogadorSelecionado: _jogadorSelecionado,
                          periodoAtual: _periodoAtual,
                          onRegistrarEvento: _registrarEvento,
                          tiposDeEventos: _tiposDeEventosDisponiveis,
                        ),

                        const SizedBox(height: 20),

                        // Botão Gerar Súmula (Só aparece no fim)
                        if (_periodoAtual == PeriodoPartida.finalizada) ...[
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MatchSummaryScreen(
                                      timeA:
                                          widget.partida.equipeA?.nome ??
                                          "Time A",
                                      timeB:
                                          widget.partida.equipeB?.nome ??
                                          "Time B",
                                      golsA: _golsA,
                                      golsB: _golsB,
                                      eventos: _eventosPartida,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.analytics),
                                  SizedBox(width: 8),
                                  Text(
                                    'VER RESUMO DA PARTIDA',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Botão Sair/Voltar dinâmico
                        _buildBotaoVoltar(),

                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Loader Central (Aparece por cima de tudo)
            if (_carregandoAtletas)
              Container(
                color: Colors.black54, // Escurece o fundo
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Carregando equipas e atletas...",
                        style: TextStyle(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- NOVO MODAL DE SUBSTITUIÇÃO REFINADO ---
  void _abrirModalSubstituicaoNovo() {
    final jogadorSaindo = _jogadorSelecionado!;
    final isTimeA = _jogadoresA.contains(jogadorSaindo);
    final reservas = isTimeA ? _reservasA : _reservasB;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Color(0xFF2D2D2D),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            // Barra de arraste
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header do Modal
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "SUBSTITUIÇÃO", // Nome do evento conforme events.txt
                        style: TextStyle(
                          color: Color(0xFF00FFC2),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        // Acessando o nome da equipe corretamente através do modelo da partida
                        isTimeA
                            ? (widget.partida.equipeA?.nome ?? "Time A")
                            : (widget.partida.equipeB?.nome ?? "Time B"),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Jogador que está saindo (UI em destaque)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(15),
                // ignore: deprecated_member_use
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.redAccent),
                  const SizedBox(width: 12),
                  Text(
                    "SAINDO:",
                    style: TextStyle(
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${jogadorSaindo.nome} (#${jogadorSaindo.numero})",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.only(top: 24, bottom: 12),
              child: Text(
                "SELECIONE QUEM ENTRA",
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Lista de Reservas Animada
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: reservas.length,
                itemBuilder: (context, index) {
                  final reserva = reservas[index];
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, 20 * (1 - value)),
                          child: _buildReservaCard(reserva, jogadorSaindo),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservaCard(Atleta reserva, Atleta saindo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          _confirmarSubstituicao(saindo, reserva);
        },
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // ignore: deprecated_member_use
              colors: [
                (reserva.corTime ?? Colors.grey).withOpacity(0.2),
                Colors.white10,
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: reserva.corTime,
                radius: 18,
                child: Text(
                  "${reserva.numero}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                reserva.nome,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              const Icon(Icons.login, color: Color(0xFF00FFC2), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmarSubstituicao(Atleta saindo, Atleta entrando) {
    setState(() {
      final isA = _jogadoresA.contains(saindo);
      final listTitulares = isA ? _jogadoresA : _jogadoresB;
      final listReservas = isA ? _reservasA : _reservasB;

      int idx = listTitulares.indexOf(saindo);
      listTitulares[idx] = Atleta(
        id: entrando.id,
        atletaId: entrando.atletaId,
        ativo: entrando.ativo,
        numero: entrando.numero,
        nome: entrando.nome,
        corTime: entrando.corTime,
        posicao: saindo.posicao,
      );

      listReservas.remove(entrando);
      listReservas.add(
        Atleta(
          id: entrando.id,
          atletaId: entrando.atletaId,
          ativo: entrando.ativo,
          numero: saindo.numero,
          nome: saindo.nome,
          corTime: saindo.corTime,
          posicao: Offset.zero,
        ),
      );

      _eventosPartida.insert(
        0,
        EventoPartida(
          tipo: 'Substituição',
          jogadorNome: '${saindo.nome} ↔ ${entrando.nome}',
          jogadorNumero: saindo.numero,
          corTime: saindo.corTime ?? Colors.grey,
          horario: _formatarTempo(_segundos),
          timestamp: DateTime.now(),
        ),
      );

      // Mostrar confirmação do evento registrado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Substituição registrada: ${saindo.nome} (#${saindo.numero}) ↔ ${entrando.nome} (#${entrando.numero})",
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _jogadorSelecionado = null;
    });
  }
}
