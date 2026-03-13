# Instagram DS Rework - 2026-03-11

## Contexto

Rework completo apos feedback de que o primeiro pack estava:

- contaminado pela linguagem das artes antigas
- repetitivo
- com excesso de texto
- com diagramação ruim e colisao de blocos

Objetivo desta segunda versao:

- partir do design system do app, nao do pack anterior
- reduzir o volume de copy
- organizar melhor hierarquia e respiro
- construir pecas com cara de produto/interface

## Base visual usada

- Cores do design system:
  `#0A0A0A`, `#141414`, `#1F1F1F`, `#292929`, `#383838`, `#E8466C`, `#FFFFFF`, `#B3B3B3`, `#8A8A8A`, `#3B82F6`, `#22C55E`
- Tipografia:
  Poppins para headline, Inter para texto de apoio
- Padrões traduzidos do app:
  surfaces dark
  bordas suaves
  botao pill primario
  chips de filtro/habilidade
  telas com app bar
  cards de selecao e estrutura de navegação inferior

## Pack gerado

Saida:

- `social_media/instagram_ds_rework_20260311/exports/01_capa_ds.png`
- `social_media/instagram_ds_rework_20260311/exports/02_quatro_perfis_ds.png`
- `social_media/instagram_ds_rework_20260311/exports/03_busca_ds.png`
- `social_media/instagram_ds_rework_20260311/exports/04_perfil_galeria_ds.png`
- `social_media/instagram_ds_rework_20260311/exports/05_match_chat_ds.png`
- `social_media/instagram_ds_rework_20260311/exports/06_cta_gig_ds.png`

Preview:

- `social_media/instagram_ds_rework_20260311/preview.png`

HTMLs fonte:

- `social_media/instagram_ds_rework_20260311/html/`

Script gerador:

- `scripts/generate_instagram_ds_pack_v2.mjs`

## Decisões

- `01_capa_ds`
  capa limpa, com feed real e navegação inspirada no `MainScaffold`
- `02_quatro_perfis_ds`
  onboarding reconstruido como tela do app, com cards empilhados e CTA fixo
- `03_busca_ds`
  busca redesenhada como shell de interface, sem manifesto visual
- `04_perfil_galeria_ds`
  perfil e portfolio em painéis separados, priorizando legibilidade
- `05_match_chat_ds`
  fluxo match -> conversa com menos texto e mais produto
- `06_cta_gig_ds`
  fechamento com card de oportunidade e proposta de valor objetiva

## Verificação rápida

- sem sobreposição estrutural de blocos no pack final
- menos texto por peça
- layout mais guiado por componentes do app
- paleta restrita aos tokens reais do design system
