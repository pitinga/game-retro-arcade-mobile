# Protocolo de revisão — Retro Arcade Mobile
Versão 0.2.0 · 2026-11-24 · [GDD geral](GDD.md) · [GDD dos jogos](GDD-GAMES.md) · [Visual](VISUAL-CONCEPTS.md)
Este documento é destinado ao revisor independente. A baseline documentada é proposta, não implementação. Nenhum teste executado nesta etapa. Não assumir conformidade por existência de arquivos ou claims do programador.

## 1. Procedimento
1. Ler os três documentos e ADRs aprovados; identificar SHA base/head, versão do GDD, escopo e mudanças. Inspecionar diff completo, arquitetura, testes e código afetado; não limitar aos arquivos apontados no handoff.
2. Verificar cada requisito aplicável por ID, relacionar a implementação e teste; distinguir ausente, falhou, aprovado e não aplicável com justificativa.
3. Executar lint/typecheck/test/build da stack escolhida, testes de integração e manual conforme escopo; registrar comandos, resultados/exit codes, logs úteis, dispositivo/SO/resolução, SHA e versão. Não declarar testes executados se ambiente indisponível; marcar BLOCKED.
4. Examinar assets/licenças, dados comerciais, lógica de gameplay, controles, UI, estados de erro, segurança, desempenho e casos-limite. Verificar screenshots próprios de QA contra wireframes; não exigir cópia de layout histórico.
5. Gerar review Markdown com evidências, prioridade e passos de reprodução; recomendar aprovação apenas quando gates aplicáveis atendidos. Não alterar código em revisão independente; correções pelo programador e nova rodada.
6. Após correção comparar novo SHA, reexecutar regressões, confirmar resolução de todos achados P0/P1; não apagar achado aberto. Vincular PR/commit e handoff. Histórico de revisões fica em local definido pelo fluxo da equipe.

## 2. Matriz geral de rastreabilidade
| Teste | Requisito | Evidência mínima |
|---|---|---|
| R01 | P01, UX01 | catálogo 10 IDs únicos, exatamente 3 FREE, 7 PRO; deeplink/navegação direta não abre bloqueado; FREE completos; PRO libera todos sem anúncios |
| R02 | P02 | mock time/ads; primeira partida, limites 3 partidas/180s, falha SDK, no-fill, consentimento negado, pausa, resultado, PRO após compra cancela anúncio |
| R03 | P03 | matriz UNKNOWN/FREE/PRO/cache; compra pendente/cancelada/confirmada/duplicada; restore offline e online; erro transitório; revogação confirmada; concorrência |
| R04 | P04 | release sem fakes; política de privacidade, consentimento, verificação das lojas e minimização de dados |
| R05 | UX01–05 | navegação, tutorial pulável, pausa/restart, resultado único, offline, rotação, safe areas, back, localização e configurações persistentes |
| R06 | ART01–02, A11Y01, AUD01 | arte original/licença por arquivo, contraste, fontes e alvos touch, perigo não só por cor, redução movimento, mute e background |
| R07 | ENG01–03 | registro de módulos, ausência de dependência cruzada, simulação headless, fixed dt, replay por seed em 30/60/120 Hz render, clamp/resume, escala coordenadas |
| R08 | ENG04–06 | colisões swept e simultâneas, entidades limitadas, pausa congela todos timers, background/foreground 10x, touch cancel, multitouch, input resize, dispose sem timers |
| R09 | ENG07, GLO02 | recorde por ID/dificuldade/versão, persistência atômica, schema inválido/migração, retry idempotente, score inteiro seguro, sem recurso negativo |
| R10 | ENG08–09 | cold start offline, frame p95, PSS, tamanho release, 10 trocas de jogo, 5 min por jogo, sem segredo ou debug em release; logs e medições reais |
| R11 | GLO01–04 | dificuldades distintas, Normal default, progressão com limites, sem ads entre fases, sem pagamento por vantagem, originalidade e regras consistentes |
| R12 | Seção 8 | auditoria de origem, nenhuma ROM/disassembly/screenshot/código/áudio/branding alheio no repo ou pacote; marca/lojas/jurídico antes de release |
| R13 | G01–G10 | executar AC-Gxx-01..04 de cada jogo, pelo menos 40 critérios; cada caso com teste/evidência ou bloqueio explícito |
| R14 | Visual | screenshots próprias por jogo, retrato/paisagem e 2 aspect ratios, layout não distorcido, HUD legível, controles não sobrepostos, tema consistente |

## 3. Estratégia de testes
### Unitários e propriedades
- Configs válidas; invariantes de posição/recursos/score; colisão tangente, canto, alta velocidade, simultânea; sem NaN/Infinity; RNG estável; limites e remoção de entidades.
- Replay: fixtures com seed + dificuldade + lista de inputs por tick + versão; comparar snapshots/hash por tick, excluir timestamp, estado cosmético e IDs aleatórios de fora da simulação. Render em frequências distintas não muda simulação; testar delta grande, clamp, interrupção.
- Generators: 1000 seeds por configuração aplicável nos GDDs; seed de falha registrada e reproduzível. Solver verifica possibilidade abstrata, não substitui playtest humano. Caso impossível = regressão, não só média. Limitar retries de geração e usar fallback autoral validado.
- Níveis autorados: solver ou validação sistemática todos níveis e dificuldades; verificar portas, retornos, recursos, checkpoints, alcance e sem softlock.
- Score: exatamente uma vez por ID/ação; sem farm por respawn, volta, fragmento, colisão múltipla; game over idempotente; recorde só persistido uma vez por resultado.
- Commerce: fake store/ad SDK determinístico e relógio injetável; fluxo cancelado/pendente/retry/revogado; nunca liberar pela UI isolada; testar acesso direto à rota, entitlement mudando em partida (não interromper rodada PRO já iniciada por erro transitório; revogação confirmada bloqueia próximo início).

### Integração e E2E
- Do catálogo ao resultado nos três FREE e dez PRO em fixture autorizada. Abrir card bloqueado, upgrade, restaurar, cancelar, falha de pagamento, voltar. Modo avião com cache FREE/PRO; sem internet não trava.
- Background com dois dedos ativos, retorno, pause/resume, back, rotation/resize, saída, restart, dez ciclos por jogo; verificar ausência de áudio/RAF/timers/input após dispose. Tela bloqueada e interrupção de áudio.
- Todos níveis de dificuldade em cada jogo; uma partida curta + teste final/derrota; testes focados nos 40 AC. Capturar screenshot de menu, jogo inicial, fase avançada, pausa, resultado, bloqueado e upgrade. Registro por resolução/orientação.
- Regressões de tradução pt-BR/en, fontes ampliadas, safe area e controles em dispositivos reais; simulação headless não substitui E2E touch. Dispositivos propostos: pelo menos Android low-end e intermediário, proporções 16:9 e 20:9; iOS somente se target suportado (declarar não testado caso não disponível).
- CI sem acesso a loja real usa mocks apenas debug; release deve executar smoke de build, auditoria de dependência/licença e garantir que mocks não sejam empacotados/ativáveis.

## 4. Performance e qualidade
Medir build de release ou equivalente sem devtools pesados, aparelho e SO informados, modo offline, temperatura e método. Alvos ENG08 são de design, não dados medidos. Por jogo executar 5 min de gameplay, reportar FPS/p95, stalls, PSS pico e entidades ativas. Repetir abrir/fechar dez vezes; comparar memória após estabilizar, não exigir igualdade exata de GC. Cold start em pelo menos 5 execuções, reportar mediana e máximo. Verificar tamanho real do artefato (download estimado da loja separado de AAB). Não otimizar prematuramente sem perfil.

## 5. Gates e severidade
- P0 bloqueante: crash/release impossível, acesso PRO indevido, anúncio em PRO, perda de compra, risco crítico de segurança/privacidade, material protegido sem autorização, impossibilidade de iniciar jogo.
- P1 alta: game over/score incorreto, softlock, mapa impossível, dano duplicado, física dependente de FPS, controle preso, jogo não funciona offline, requisito MUST não cumprido, anúncio durante partida, perda de recorde, CI obrigatório falha.
- P2 média: desvio visual ou UX relevante, desempenho aquém do target com impacto moderado, problema de acessibilidade, cobertura insuficiente de caso secundário; documentar prazo e risco. Se impede requisito MUST ou jogar, P1.
- P3 baixa: refinamento, manutenção, nomenclatura, melhoria não obrigatória.
- PR: nenhum P0/P1 aberto, testes obrigatórios do escopo executados e verdes; P2 somente com aceitação explícita/issue. Release: todos 10 completos, todos 40 AC e R01–R14 verificados, dispositivo/loja/privacidade/licenças/branding aprovados, sem P0/P1, sem pendência P2 que contrarie MUST. Sem release baseado apenas no protótipo. Verificações não executadas não são aprovadas.

## 6. Modelo de relatório (copiar)
```markdown
# Review — <SHA curto> — <data UTC>
- Repositório:
- PR/base/head:
- GDD/versão:
- Escopo:
- Ambiente/dispositivo:
- Resultado: APPROVE | REQUEST_CHANGES | BLOCKED

## Resumo
- P0: 0 | P1: 0 | P2: 0 | P3: 0
- Requisitos: PASS / FAIL / BLOCKED / N/A (contagem)

## Rastreabilidade
| ID | Status | Arquivo:linha / teste | Evidência | Achado |
|---|---|---|---|---|

## Achados
### RV-001 — P1 — <título>
- Requisito:
- Arquivo/linha/commit:
- Reprodução (seed, passos, dificuldade, plataforma):
- Esperado:
- Observado:
- Impacto:
- Correção recomendada:
- Teste de regressão:

## Comandos realmente executados
| Comando | Exit code | Evidência |
|---|---|---|

## Visual, desempenho, licenças
- Capturas próprias / evidências:
- Medições:
- Origem dos assets:

## Não testado / bloqueios
- Motivo e ação requerida:

## Veredito e próximos passos
```

## 7. Estado inicial
Requisitos de M2–M7 permanecem PENDENTES; M1 deve ser avaliado pelo SHA do PR e evidências. Nenhum teste de jogo, ROM ou asset final é produzido por estes documentos. Próximo passo: revisar baseline, escolher stack/ADR, implementar shell + engine + G03 como vertical slice antes de expandir.
