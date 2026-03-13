# Instagram Public Launch - Mube

## Overview

- Prompt: criar artes para Instagram apresentando o app ao publico, com variedade visual e alinhamento ao design system real.
- Formato final: 8 pecas para feed/carrossel em `1080x1350`.
- Saida principal: `social_media/instagram_public_launch_20260311/exports/`
- Preview geral: `social_media/instagram_public_launch_20260311/preview.png`

## Concepts

1. `01_manifesto`
   foco em manifesto de marca e abertura de campanha.
2. `02_quatro_perfis`
   explica as entradas do ecossistema: musico, banda, estudio e contratante.
3. `03_matchpoint`
   mostra descoberta e match como feature central.
4. `04_busca_inteligente`
   posiciona a busca com filtros como corte de ruido.
5. `05_perfil_completo`
   valoriza profundidade de perfil e legibilidade.
6. `06_galeria_viva`
   destaca portfolio, fotos e videos.
7. `07_gigs_e_chat`
   conecta descoberta, conversa e oportunidade real.
8. `08_cta_final`
   fecha o carrossel com sintese de proposta e chamada de acao.

## Design Decisions

- Base visual: dark-only, usando o mesmo eixo do app.
- Tipografia: Poppins para headline e Inter para apoio, seguindo `AppTypography`.
- Tokens de cor usados no gerador:
  `#0A0A0A`, `#141414`, `#1F1F1F`, `#E8466C`, `#C026D3`, `#3B82F6`, `#22C55E`, `#F59E0B`, `#FFFFFF`
- Assets reais usados:
  screenshots do app em `assets/images/screenshots/ss1.png` a `ss6.png`
  logos em `assets/images/logos_svg/brand/`
- Variacao intencional de direcao:
  manifesto tipografico, grid de cards, hero com device, editorial com callouts, collage de galeria e CTA mais limpo.

## UI Doctor Adapted Check

- Contraste: headlines em branco sobre fundos escuros e paines translcidos com leitura confortavel.
- Hierarquia: cada peca tem um ponto focal principal, um bloco secundario e no maximo um grupo de apoios.
- Tokens: apos ajuste final, o script usa apenas hex de tokens canonicamente presentes no design system e seus semanticos de apoio.
- Coerencia: cantos arredondados altos, paines glass/dark e glow sutil mantem parentesco com o app sem copiar a UI literalmente.

## Nano Banana Status

- A skill foi acionada no fluxo, mas nao foi possivel executar geracao por IA neste ambiente porque o CLI `infsh` nao estava instalado e nao havia autenticacao/chave Gemini disponivel.
- Fallback aplicado:
  usar composicao forte com screenshots reais do produto, logos oficiais e direcao visual derivada do design system do app.

## Output Files

- `social_media/instagram_public_launch_20260311/html/01_manifesto.html`
- `social_media/instagram_public_launch_20260311/html/02_quatro_perfis.html`
- `social_media/instagram_public_launch_20260311/html/03_matchpoint.html`
- `social_media/instagram_public_launch_20260311/html/04_busca_inteligente.html`
- `social_media/instagram_public_launch_20260311/html/05_perfil_completo.html`
- `social_media/instagram_public_launch_20260311/html/06_galeria_viva.html`
- `social_media/instagram_public_launch_20260311/html/07_gigs_e_chat.html`
- `social_media/instagram_public_launch_20260311/html/08_cta_final.html`
- `social_media/instagram_public_launch_20260311/exports/01_manifesto.png`
- `social_media/instagram_public_launch_20260311/exports/02_quatro_perfis.png`
- `social_media/instagram_public_launch_20260311/exports/03_matchpoint.png`
- `social_media/instagram_public_launch_20260311/exports/04_busca_inteligente.png`
- `social_media/instagram_public_launch_20260311/exports/05_perfil_completo.png`
- `social_media/instagram_public_launch_20260311/exports/06_galeria_viva.png`
- `social_media/instagram_public_launch_20260311/exports/07_gigs_e_chat.png`
- `social_media/instagram_public_launch_20260311/exports/08_cta_final.png`
- `social_media/instagram_public_launch_20260311/preview.png`

## Generator

- Script de geracao e export:
  `scripts/generate_instagram_public_launch_pack.mjs`
- Render:
  `playwright` via `chromium`
- Validacao:
  `sharp` para checagem de dimensoes e montagem do preview
