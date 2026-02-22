-- 1) Colunas novas em eventos_partida
ALTER TABLE public.eventos_partida
    ADD COLUMN IF NOT EXISTS is_substitution BOOLEAN DEFAULT FALSE;

ALTER TABLE public.eventos_partida
    ADD COLUMN IF NOT EXISTS atleta_sai_id UUID;

-- 2) Coluna nova em partidas
ALTER TABLE public.partidas
    ADD COLUMN IF NOT EXISTS agendado_para TIMESTAMPTZ;

-- 3) Atualiza status antigos (se existirem) para evitar falha ao criar constraint
UPDATE public.partidas
SET status = 'finalizada'
WHERE status IN ('encerrada', 'encerrado');

UPDATE public.partidas
SET status = '1° tempo'
WHERE status IN ('em_andamento', 'em andamento');

-- 4) Recria a constraint com os novos valores permitidos
ALTER TABLE public.partidas
DROP CONSTRAINT IF EXISTS check_status_partida;

ALTER TABLE public.partidas
    ADD CONSTRAINT check_status_partida
        CHECK (status IN ('agendada', '1° tempo', 'intervalo', '2° tempo', 'prorrogação', 'finalizada'));