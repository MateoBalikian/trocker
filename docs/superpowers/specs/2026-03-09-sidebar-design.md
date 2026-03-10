# Trocker Sidebar — Design Spec
**Date:** 2026-03-09
**Status:** Approved

---

## Overview

Redesign da identidade visual e sidebar de navegação do Trocker. Estética Arc Browser — superfícies escuras neutras, sem acento colorido, profundidade por luminosidade, animações suaves.

---

## Visual Identity

### Color Tokens (Theme.qml)

| Token        | Value       | Usage                        |
|--------------|-------------|------------------------------|
| `bg`         | `#111114`   | Fundo principal da janela    |
| `surface`    | `#161619`   | Sidebar, cards               |
| `surface2`   | `#1C1C22`   | Hover, inputs, pills         |
| `border`     | `#1E1E26`   | Divisores, bordas            |
| `textPrimary`| `#E8E8ED`   | Texto ativo, ícone ativo     |
| `textMuted`  | `#555560`   | Texto e ícones inativos      |
| `accent`     | `#E8E8ED`   | Acento único (branco quente) |
| `green`      | `#4ade80`   | Dot do projeto ativo         |

**Princípio:** zero gradientes, zero azul Apple. Contraste via luminosidade.

### Typography
- **TROCKER** wordmark: Rajdhani Bold, 15px, letter-spacing 3px
- **Nav labels**: Poppins Regular/SemiBold, 11px
- **Section labels**: Poppins SemiBold, 8px, letter-spacing 2px, uppercase
- **Project badge**: Poppins Medium, 10px

---

## File Structure

```
src/qml/
  main.qml      — orquestra layout, gerencia collapsed e activeIndex
  Theme.qml     — singleton com todos os tokens de cor e espaçamento
  Sidebar.qml   — sidebar completa, recebe props, emite sinais
  NavItem.qml   — item de navegação reutilizável
```

---

## Sidebar

### Dimensões
| Estado     | Largura | Transição               |
|------------|---------|-------------------------|
| Expandida  | 220px   | —                       |
| Colapsada  | 64px    | 280ms, Easing.OutCubic  |

### Estrutura (expandida)
```
┌─────────────────────┐
│ [T]  TROCKER        │  ← logo mark + wordmark
│ ● Flamengo vs Pal…  │  ← project badge
├─────────────────────┤
│ MENU                │  ← section label
│ ⊞  Projects         │  ← nav item (active)
│ ◎  Tracker          │
│ ⌗  Homography       │
│ ▤  Reports          │
│ ⚙  Settings         │
├─────────────────────┤
│ [M]  mateo    ···   │  ← user row
└─────────────────────┘
              [‹]       ← collapse button, borda direita, centro vertical
```

### Estrutura (colapsada)
```
┌────────┐
│  [T]   │
│  ●     │
├────────┤
│  ⊞     │  ← ícone centralizado + tooltip no hover
│  ◎     │
│  ⌗     │
│  ▤     │
│  ⚙     │
├────────┤
│  [M]   │
└────────┘
[›]         ← collapse button, borda direita, centro vertical
```

### Botão de Colapso
- Posição: borda direita da sidebar, centralizado verticalmente (`anchors.verticalCenter`)
- Tamanho: 28px círculo
- Ícone: `‹` expandida / `›` colapsada
- Background: `surface2`, borda `border`
- Sempre levemente visível; destaque no hover
- Clique: emite `toggleCollapse()` para `main.qml`

### Animações

| Elemento              | Propriedade | Duração | Easing        |
|-----------------------|-------------|---------|---------------|
| Colapso sidebar       | `width`     | 280ms   | OutCubic      |
| Labels nav            | `opacity`   | 200ms   | OutCubic      |
| Barra indicadora ativa| `height`    | 200ms   | OutBack       |
| Hover pill            | `color`     | 150ms   | OutCubic      |
| Tooltip               | delay 500ms | —       | —             |

---

## NavItem.qml — Props

```qml
property string label      // "Projects"
property string icon       // "⊞"
property bool   active     // highlight ativo
property bool   collapsed  // sidebar colapsada?
signal clicked()
```

---

## Signals / Props Flow

```
main.qml
  ├── collapsed: bool   → Sidebar.qml
  ├── activeIndex: int  → Sidebar.qml
  └── handles: navSelected(i), toggleCollapse()

Sidebar.qml
  ├── signal navSelected(int index)
  ├── signal toggleCollapse()
  └── NavItem.qml × 5
```

---

## Out of Scope (esta fase)

- Conteúdo das páginas (Projects, Tracker, etc.)
- Toggle de tema (vai para Settings → Appearance, fase futura)
- Backend / integração com Python
