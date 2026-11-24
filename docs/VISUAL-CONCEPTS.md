# Retro Arcade — Resumo visual e esboços
**Versão 0.1.0 · 2026-11-24 · Wireframes conceituais, não screenshots nem arte final.**
[GDD geral](GDD.md) | [Regras dos jogos](GDD-GAMES.md) | [Checklist](REVIEW-CHECKLIST.md)

## Direção geral
Arcade contemporâneo com pixel art de alta legibilidade; nostalgia na linguagem gráfica, não na cópia da composição dos originais. Menu fundo #101522, cards #202A3C, texto #F5F7FF, acento menta #63E6C4, PRO dourado #FFD166. Tipografia pixel nos títulos e números grandes; sans na descrição/controles. Cantos 12–16 dp no shell; gameplay com contornos nítidos, planos de fundo menos contrastados que objetos interativos. Sem moldura de televisão obrigatória, sem scanlines agressivas. Safe areas e alvos touch conforme GDD. As caixas abaixo são esboços textuais originais: a escala é ilustrativa, controles não ocupam área jogável útil; HUD real localizado. Os nomes são provisórios e dependem de clearance de marca. Os números de HUD ilustram estado, não especificação de balanceamento.

## Catálogo / tela inicial (retrato)
```text
┌─────────────────────────────────┐
│ RETRO ARCADE          ⚙         │
│ 10 mundos. Um só arcade.         │
│ ┌────────────┐ ┌────────────┐   │
│ │  avião     │ │  estrada   │   │
│ │ Canyon     │ │ Horizon    │   │
│ │ Wings      │ │ Rally      │   │
│ └────────────┘ └────────────┘   │
│ ┌────────────┐ ┌────────────┐   │
│ │  prismas   │ │ submarino  │   │
│ │ Prism      │ │ Abyss      │   │
│ │ Break      │ │ Rescue 🔒  │   │
│ └────────────┘ └────────────┘   │
│ ┌────────────┐ ┌────────────┐   │
│ │ Polar   🔒 │ │ Deep    🔒 │   │
│ └────────────┘ └────────────┘   │
│     ... mais 4 cards ...        │
│ [ Desbloquear 10 jogos · PRO ]  │
└─────────────────────────────────┘
```
Cards com thumbnail própria, nome legível, cadeado somente bloqueados, scroll vertical. PRO remove CTA e cadeados. Sem banner sobre card. Tela de detalhes: hero thumbnail, regras, dificuldade segmentada, recorde, jogar/upgrade. Resultado: números em destaque, repetir e catálogo; sem modal publicitário durante gameplay.

## G01 — Canyon Wings · FREE · retrato
```text
┌──────────────────────┐
│ 04280   SETOR 3   II │
│ Energia ███████░  ⏸ │
├──────────────────────┤
│ ▲ rocha  ~~~~  rocha │
│ ██╲    ╔════╗    ╱██ │
│ ███╲   ╚    ╝   ╱███ │
│ ████│    ◇     │████ │
│ ███╱ ~   ↑   ~ ╲████ │
│ ██╱     [E]     ╲███ │
│ █│  ~    ▲     ~ │██ │
│ █│      /_\      │██ │
│ ██╲  ~       ~  ╱███ │
├──────────────────────┤
│ [← ARRASTE →]  [●]   │
│ [− FREIO] [+ BOOST]  │
└──────────────────────┘
```
Paleta: água #184C79, margem #B77E55, vegetação #3D7862, aeronave #E9F2FF, energia #7EF4DA, perigo #FF865A. Cânion visto de cima, forma sinuosa com ilhas e luz diagonal; portões futuristas translúcidos com borda e setas, não pontes copiadas. Aeronave branca/teal, drones losangulares laranja, células com ícone E e halo. Esteira aquática e partículas discretas, indicação de rota segura. Arte: tiles de rocha/água, três drones, portão, células, aeronave em inclinação, projéteis e HUD.

## G02 — Horizon Rally · FREE · retrato
```text
┌──────────────────────┐
│ DIA 2  18/28  00:46  │
│ 148 km/h  ◆◆◆◇◇  ⏸  │
├──────────────────────┤
│ ☀   montanhas       │
│ ───────┬──┬──────── │
│       ╱ ·  ╲         │
│      ╱  ▣   ╲        │
│     ╱ ·  ·   ╲       │
│    ╱ ▣      ▣ ╲      │
│   ╱   ·  ·     ╲     │
│  ╱       ▓      ╲    │
│ ╱________________╲   │
├──────────────────────┤
│ [←] [→] [FREIO][GÁS] │
└──────────────────────┘
```
Paleta: céu #F2A65A→#262D55, estrada #414958, faixa #F3DFB0, carro #4CE3C4, rivais #E97961/#91A7F0. Perspectiva pseudo-3D com curvas suaves, horizonte de montanhas e paisagens originais, lanternas e placas legíveis à noite. Nevoeiro não oculta ameaça imediata; gelo marcado por textura e ícone. Arte: carros em ângulos/escala, montanhas, postes, pista segmentada, efeitos chuva/neblina/gelo, velocímetro. Sem logotipo de fabricantes.

## G03 — Prism Break · FREE · retrato
```text
┌──────────────────────┐
│ 01850  FASE 04   ⏸  │
│ ●●●    BLOCOS 21     │
├──────────────────────┤
│  ▰ ▰ ▰ ▰ ▰ ▰ ▰       │
│   ▰ ▰ ▓ ▓ ▰ ▰        │
│    ▰ ▰ ▰ ▰ ▰         │
│     ▰ ▰ ▰ ▰          │
│       ▓ ▓            │
│            ✦         │
│          ·           │
│        ●             │
│      ═══════         │
├──────────────────────┤
│ [← ARRASTE →] [SERVIR]│
└──────────────────────┘
```
Paleta: fundo #151B35, blocos #A78BFA/#4BD9C6/#FFC878, paddle #F1F5FF, bola #FFFFFF. Prismas geométricos com padrões e marcas de HP (não apenas cor); layouts diagonais, mosaicos e anéis próprios; fundo discreto, impacto com partículas curtas, trilha leve da bola. Arte: blocos 1/2/3 HP, indestrutível, bola, paddle, power-ups, efeitos.

## G04 — Abyss Rescue · PRO · paisagem
```text
┌────────────────────────────────────────────┐
│ 02800   ONDA 3    O₂ █████░  CARGA 2/4  ⏸ │
├────────────────────────────────────────────┤
│ ☁      navio de pesquisa    ║ DOCA ║      │
│ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ │
│  ·         ◇ cápsula       < drone         │
│       ╭═══╮    ○ bolhas                    │
│       ╰═══╯ → pulso     ◇     ◁             │
│  recife           corrente →       recife  │
├────────────────────────────────────────────┤
│ [   STICK 2D   ]              [ ● PULSO ]  │
└────────────────────────────────────────────┘
```
Paleta: superfície #86D3E7, água #123A63→#081D38, veículo #F6C85D, cápsulas #B7F3DC, inimigos #F18C82. Profundidade em camadas, luz volumétrica moderada; veículo de pesquisa compacto, cápsulas luminosas com ícone de resgate, superfície com faixa de doca clara. Oxigênio sempre visível; recife decorativo não parece obstáculo se não colide. Arte: veículo quatro direções/estados, drones, cápsulas, doca, bolhas, corais, pulso.

## G05 — Polar Workshop · PRO · paisagem
```text
┌────────────────────────────────────────────┐
│ FASE 2   MÓDULOS 5/8   TEMP ██████░░   ⏸  │
├────────────────────────────────────────────┤
│ BASE ╔══[■■■□□]══╗  antena     neve       │
│ ~~~ [▧▧] → ~~~ [▧▧] → ~~~ [▧▧] ~~~~~~~~ │
│ ~~ [▧▧] ← ~~  [◆◆] ← ~~ [▧▧] ~~~~~~~~~~ │
│ ~~~~ [▧▧] → ~~ ROBÔ ↑ ~~~~ [▧▧] → ~~~~~~ │
│ ~~ [▧▧] ← ~~~~ [▧▧] ← ~~ [◆◆] ~~~~~~~~~ │
│ ~~~~~ [▧▧] → ~~~~~~ [▧▧] → ~~~~~~~~~~~~ │
├────────────────────────────────────────────┤
│ [ ← ↑ ↓ → ]                        [SALTO]│
└────────────────────────────────────────────┘
```
Paleta: neve #E3F1F5, gelo #8BD1F0, água #203E6E, módulo #F5B95F, robô #F5E8CC, perigo #BE647D. Estação modular no topo, placas com padrão de circuito e setas de direção, robô de manutenção original. Placa ativa possui símbolo e contorno diferentes; queda distingue água de gelo. Arte: base em estados 0–100%, plataformas 3 tipos, robô pulando, rajada, drone, indicador termal.

## G06 — Deep Signal · PRO · paisagem
```text
┌────────────────────────────────────────────┐
│ NÍVEL 07   ENERGIA █████░░   CORTES 2  ⏸  │
├────────────────────────────────────────────┤
│ ▓▓▓▓▓▓▓▓▓▓  entrada  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓       ▓▓            [E]               ▓ │
│ ▓  ◇ ↑  ▓▓       ░░ BARREIRA ░░          ▓ │
│ ▓    ↑     → pulso   ░░░░░░     cientista▓ │
│ ▓▓▓▓▓▓▓          vapor ↑↑    ▓▓▓▓▓▓▓▓▓▓▓▓ │
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ │
├────────────────────────────────────────────┤
│ [← →]           [JET] [PULSO] [CORTE]     │
└────────────────────────────────────────────┘
```
Paleta: rocha #38354D, luz #D8E0F2, energia #6BE2D2, equipamento #F4C56E, risco #F67868. Cavernas industriais, minerais e cabos, luz localizada com borda legível, piso e áreas de risco marcados. Personagem drone humanoide com equipamento de emergência próprio, cientista com marcador de objetivo; parede quebrável com fissura e ícone, efeito de corte não imita explosivos do original. Arte: tiles diversos, ferramentas, bateria, resgatado, inimigos, portas, vapor.

## G07 — Skyport Chase · PRO · paisagem
```text
┌────────────────────────────────────────────┐
│ TEMPO 00:42   RODADA 3   ◆◆◆    MAPA   ⏸ │
├────────────────────────────────────────────┤
│ P4 ─────── [LIFT] ──────── [ROBO] →       │
│ P3 ── esteira → ──────────────── ╱        │
│ P2 ───── mala ▣ ─────── [LIFT] ╱         │
│ P1 ── agente ▲ ─── drone ◇ ────╱         │
│        terminal · vitrines · painéis      │
├────────────────────────────────────────────┤
│ [← →]               [SALTO][ABAIXAR][LIFT]│
└────────────────────────────────────────────┘
```
Paleta: terminal #28435C/#526B84, painéis #C0D7E6, agente #6DE1C4, alvo #FFBA67, obstáculo #E98279. Aeroporto futurista em corte lateral com pisos numerados, minimapa claro e lifts distintos. Evitar uniforme policial, ladrão, lojas e cenários originais. Esteiras com chevrons, malas e drones geométricos. Arte: agente 6 estados, robô alvo, lift/portas, rampas, obstáculos, sinalética.

## G08 — Emerald Expedition · PRO · paisagem
```text
┌────────────────────────────────────────────┐
│ REGIÃO 2  RELÍQUIAS 2/4  02:25  ◆◆◆   ⏸ │
├────────────────────────────────────────────┤
│   copa da floresta         ruína         │
│    ╭──ponte──╮        ◇ artefato         │
│  ▲ ╯         ╰───────┐   ┌───────        │
│ ───────      fenda   └───┘     escada    │
│        ║       trilha inferior    ║      │
│ _______║__________________________║______ │
├────────────────────────────────────────────┤
│ [← →]                   [SALTO][ESCALAR]  │
└────────────────────────────────────────────┘
```
Paleta: selva #285B49/#467B55, ruínas #927A59, céu #A8D6C1, exploradora #EAD5A2/#C46D45, artefatos #F6D46E. Selva em camadas, ruínas assimétricas, trilhas elevadas/subterrâneas, protagonista cartógrafa com mochila e ferramenta própria. Armadilhas têm aviso físico/animação; não copiar composição de cipós, crocodilos e buracos da referência. Arte: tiles floresta/ruína, escalada, pontes, animais, artefatos, acampamento, minimapa.

## G09 — Orbit Shards · PRO · paisagem
```text
┌────────────────────────────────────────────┐
│ 05480     ONDA 6    ◆◆    DASH █████  ⏸  │
├────────────────────────────────────────────┤
│   ✧     ◇◇     ·         nebulosa        │
│     ⬡             ◇          ⬡          │
│              · ·  ▲↗                     │
│         ◇       ·               ◇       │
│  ·      drone ◁          ✧               │
├────────────────────────────────────────────┤
│ [↶ ↷] [PROPULSÃO]              [TIRO][DASH]│
└────────────────────────────────────────────┘
```
Paleta: espaço #11152D, nebulosa #30365D, nave #9EE8E0, cristais #C4A4FF/#78B7EA, drone #FF987A. Cristais facetados com escala e silhueta distintas, nave de mineração com propulsores visíveis, wrap indicado por cópias na borda. Fundo sem estrelas que confundam tiro, flashes limitados. Arte: cristais três tamanhos e variantes, nave/propulsão/dash, drone, projétil, explosão de fragmentos.

## G10 — Aurora Shield · PRO · paisagem
```text
┌────────────────────────────────────────────┐
│ ONDA 4  03/05 HABITATS  A:6 B:3  03200 ⏸│
├────────────────────────────────────────────┤
│  ·  ╲   ·         ╱·        · ╲          │
│      ╲          ◌              ╲         │
│        ◎     + alvo                       │
│             ╱   ╲                        │
│  [A]  ⌂    ⌂     ⌂    ×    ⌂     [B]    │
│ ________planície polar / aurora__________ │
├────────────────────────────────────────────┤
│          TOQUE NO CAMPO PARA INTERCEPTAR  │
└────────────────────────────────────────────┘
```
Paleta: céu #18243D, aurora #4CC6A7, habitats #BDDEEA, lançadores #E7C77D, ameaça #FF9B72, escudo #70D6FF. Cinco habitats científicos com formatos variados e dois lançadores em extremos assimétricos; detritos com trilhas e alvos sinalizados, bolhas concêntricas de energia transparentes. Estado destruído tem ícone × e silhouette apagada, não só cor. Arte: habitats íntegros/danificados, lançadores, detritos, fragmentos, bolhas, aurora, retículo. Toque mira no campo sem controle virtual fixo.

## Matriz de assets mínimos (todos originais)
| Jogo | Personagens/veículos | Mundo | Feedback e HUD |
|---|---|---|---|
| G01 | aeronave, drones | cânions, portões | energia, setor, tiros |
| G02 | carro + rivais | pista, céu/clima | meta, tempo, integridade |
| G03 | paddle, bola | prismas, 30 padrões | HP, serve, power-ups |
| G04 | veículo, drones, cápsulas | recifes, doca | O2, carga, pulso |
| G05 | robô, drone | plataformas, estação | temperatura, módulos |
| G06 | resgatador, cientista, inimigos | 20 tilemaps próprios | energia, ferramentas |
| G07 | agente, alvo robô | terminal, lifts | minimapa, cronômetro |
| G08 | cartógrafa, fauna | 24 salas próprias | artefatos, tempo |
| G09 | nave, drone | cristais, nebulosa | dash, onda, fragmentos |
| G10 | habitats, lançadores | planície e aurora | alvo, munição, escudo |
Cada jogo precisa de thumbnail, ícone, sprite atlas, efeitos, 3–8 cues de áudio próprios, tela de tutorial e capturas de QA. Não gerar 10 conjuntos completos antes do primeiro vertical slice; validar consistência do estilo com G03.

## Checklist visual para o revisor
Comparar captura real com wireframe quanto a hierarquia, legibilidade, safe area, posição de controles e feedback, não pixel-perfect. Verificar paletas em luz/escuro, contraste, daltonismo, redução de movimento; registrar screenshots retrato e paisagem em duas proporções. Nenhuma arte original dos clássicos; thumbnails e nomes finais precisam de revisão de similaridade e licenças. Este documento contém apenas esboços textuais; mockups renderizados e arte final deverão ser feitos em etapa posterior, aprovados e vinculados ao GDD.
