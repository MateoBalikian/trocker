# Trocker Sidebar Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Construir a sidebar de navegação colapsável do Trocker com identidade visual Arc-inspired em QML/PySide6, decomposta em componentes reutilizáveis.

**Architecture:** Theme.qml centraliza todos os tokens visuais como um QtObject. NavItem.qml é um delegate reutilizável que recebe props e emite signal. Sidebar.qml compõe o layout completo. main.qml orquestra estado global (collapsed, activeIndex) e conecta sinais.

**Tech Stack:** PySide6 6.x, Qt Quick / QML (Qt 6), fontes Rajdhani + Poppins (carregadas via QFontDatabase em main.py)

**Spec:** `docs/superpowers/specs/2026-03-09-sidebar-design.md`

**Run command (venv ativado):**
```bash
trocker\Scripts\python src\main.py
```

---

## Chunk 1: Theme.qml + NavItem.qml

### Task 1: Criar Theme.qml

**Files:**
- Create: `src/qml/Theme.qml`

Theme é um QtObject simples instanciado uma vez em main.qml e passado como propriedade. Centraliza todos os tokens de cor e evita valores hardcoded nos componentes filhos.

- [ ] **Step 1: Criar o arquivo**

```qml
// src/qml/Theme.qml
import QtQuick

QtObject {
    // Backgrounds
    readonly property color bg:       "#111114"
    readonly property color surface:  "#161619"
    readonly property color surface2: "#1C1C22"

    // Borders
    readonly property color border:   "#1E1E26"

    // Text
    readonly property color textPrimary: "#E8E8ED"
    readonly property color textMuted:   "#555560"

    // Accent (único — branco quente)
    readonly property color accent: "#E8E8ED"

    // Semantic
    readonly property color green: "#4ade80"

    // Sidebar dimensions
    readonly property int sidebarExpanded:  220
    readonly property int sidebarCollapsed: 64
    readonly property int collapseMs:       280
}
```

- [ ] **Step 2: Verificar que o arquivo foi salvo corretamente**

Abrir `src/qml/Theme.qml` e confirmar que todos os 10 tokens estão presentes.

- [ ] **Step 3: Commit**

```bash
git add src/qml/Theme.qml
git commit -m "feat: add Theme.qml with visual tokens"
```

---

### Task 2: Criar NavItem.qml

**Files:**
- Create: `src/qml/NavItem.qml`

Componente de item de navegação. Quando `collapsed = false`: mostra ícone + label com pill de hover/active e barra indicadora esquerda. Quando `collapsed = true`: só ícone centralizado com ToolTip nativo.

- [ ] **Step 1: Criar o arquivo**

```qml
// src/qml/NavItem.qml
import QtQuick
import QtQuick.Controls

Item {
    id: root

    // ── Props ─────────────────────────────────────────────
    property string label:    ""
    property string icon:     ""
    property bool   active:   false
    property bool   collapsed: false
    property QtObject theme   // recebe Theme {} de Sidebar.qml

    signal clicked()

    // ── Dimensions ────────────────────────────────────────
    width:  parent ? parent.width : 0
    height: 36

    // ── State ─────────────────────────────────────────────
    property bool hovered: false

    // ── Hover pill ────────────────────────────────────────
    Rectangle {
        id: pill
        anchors.left:           parent.left
        anchors.right:          parent.right
        anchors.leftMargin:     collapsed ? 8 : 8
        anchors.rightMargin:    8
        anchors.verticalCenter: parent.verticalCenter
        height: 32
        radius: 7
        color: root.active   ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.07)
             : root.hovered  ? Qt.rgba(theme.textPrimary.r, theme.textPrimary.g, theme.textPrimary.b, 0.04)
             : "transparent"
        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }
    }

    // ── Active left bar ───────────────────────────────────
    Rectangle {
        anchors.left:           parent.left
        anchors.verticalCenter: parent.verticalCenter
        width:  2
        height: root.active ? 18 : 0
        radius: 1
        color:  theme.textPrimary
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
    }

    // ── Icon ─────────────────────────────────────────────
    Text {
        id: iconText
        anchors.left:           parent.left
        anchors.leftMargin:     collapsed ? 0 : 16
        anchors.verticalCenter: parent.verticalCenter
        width:                  collapsed ? parent.width : undefined
        horizontalAlignment:    collapsed ? Text.AlignHCenter : Text.AlignLeft
        text:           root.icon
        font.pixelSize: 14
        color: root.active ? theme.textPrimary : theme.textMuted
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    // ── Label (hidden when collapsed) ────────────────────
    Text {
        id: labelText
        anchors.left:           iconText.right
        anchors.leftMargin:     10
        anchors.verticalCenter: parent.verticalCenter
        text:           root.label
        font.family:    "Poppins"
        font.pixelSize: 12
        font.weight:    root.active ? Font.DemiBold : Font.Normal
        color: root.active ? theme.textPrimary : theme.textMuted
        opacity: root.collapsed ? 0 : 1
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on color   { ColorAnimation  { duration: 150 } }
    }

    // ── Tooltip (só quando collapsed) ────────────────────
    ToolTip {
        visible:  root.collapsed && root.hovered
        text:     root.label
        delay:    500
        timeout:  3000
    }

    // ── Mouse ─────────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape:  Qt.PointingHandCursor
        onEntered: root.hovered = true
        onExited:  root.hovered = false
        onClicked: root.clicked()
    }
}
```

- [ ] **Step 2: Rodar o app e verificar que não há erros de parse**

```bash
trocker\Scripts\python src\main.py
```

Expected: janela abre normalmente (NavItem ainda não está sendo usado).

- [ ] **Step 3: Commit**

```bash
git add src/qml/NavItem.qml
git commit -m "feat: add NavItem.qml with collapse/active/hover states"
```

---

## Chunk 2: Sidebar.qml

### Task 3: Criar Sidebar.qml — estrutura base

**Files:**
- Create: `src/qml/Sidebar.qml`

Neste step criamos a sidebar com layout completo mas sem o botão de colapso ainda. Verificamos visualmente antes de adicionar a interação.

- [ ] **Step 1: Criar Sidebar.qml com estrutura e nav items**

```qml
// src/qml/Sidebar.qml
import QtQuick
import QtQuick.Controls

Item {
    id: root

    // ── Props ─────────────────────────────────────────────
    property QtObject theme
    property bool collapsed:   false
    property int  activeIndex: 0

    signal navSelected(int index)
    signal toggleCollapse()

    // ── Dimensions ────────────────────────────────────────
    width:  collapsed ? theme.sidebarCollapsed : theme.sidebarExpanded
    height: parent ? parent.height : 0
    Behavior on width { NumberAnimation { duration: theme.collapseMs; easing.type: Easing.OutCubic } }
    clip: true

    // ── Nav model ─────────────────────────────────────────
    property var navItems: [
        { label: "Projects",   icon: "⊞" },
        { label: "Tracker",    icon: "◎" },
        { label: "Homography", icon: "⌗" },
        { label: "Reports",    icon: "▤" },
        { label: "Settings",   icon: "⚙" }
    ]

    // ── Surface ───────────────────────────────────────────
    Rectangle {
        anchors.fill: parent
        color: theme.surface

        // Right border
        Rectangle {
            anchors.top:    parent.top
            anchors.right:  parent.right
            anchors.bottom: parent.bottom
            width: 1
            color: theme.border
        }

        // ── Header ────────────────────────────────────────
        Item {
            id: header
            anchors.top:   parent.top
            anchors.left:  parent.left
            anchors.right: parent.right
            height: 96

            Column {
                anchors.left:           parent.left
                anchors.right:          parent.right
                anchors.leftMargin:     14
                anchors.rightMargin:    14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                // Logo row
                Row {
                    spacing: 8

                    // Logo mark
                    Rectangle {
                        width: 26; height: 26; radius: 6
                        color: theme.textPrimary

                        Text {
                            anchors.centerIn: parent
                            text:           "T"
                            font.family:    "Rajdhani"
                            font.weight:    Font.Bold
                            font.pixelSize: 14
                            color:          theme.bg
                        }
                    }

                    // Wordmark
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text:             "TROCKER"
                        font.family:      "Rajdhani"
                        font.weight:      Font.Bold
                        font.pixelSize:   15
                        font.letterSpacing: 3
                        color:            theme.textPrimary
                        opacity:          root.collapsed ? 0 : 1
                        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                    }
                }

                // Project badge
                Rectangle {
                    width:  parent.width
                    height: 28
                    radius: 7
                    color:  theme.surface2
                    border.color: theme.border
                    border.width: 1
                    opacity: root.collapsed ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                    Row {
                        anchors.left:           parent.left
                        anchors.leftMargin:     9
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        // Status dot
                        Rectangle {
                            width: 6; height: 6; radius: 3
                            color: theme.green
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text:             "Nenhum projeto ativo"
                            font.family:      "Poppins"
                            font.pixelSize:   10
                            font.weight:      Font.Medium
                            color:            theme.textMuted
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // Header divider
        Rectangle {
            id: headerDivider
            anchors.top:         header.bottom
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.leftMargin:  12
            anchors.rightMargin: 12
            height: 1
            color:  theme.border
        }

        // ── Nav section ───────────────────────────────────
        Column {
            id: navCol
            anchors.top:        headerDivider.bottom
            anchors.left:       parent.left
            anchors.right:      parent.right
            anchors.topMargin:  12
            anchors.leftMargin: 0
            spacing: 2

            // Section label
            Text {
                leftPadding:      collapsed ? 0 : 22
                width:            parent.width
                horizontalAlignment: collapsed ? Text.AlignHCenter : Text.AlignLeft
                text:             "MENU"
                font.family:      "Poppins"
                font.pixelSize:   8
                font.weight:      Font.SemiBold
                font.letterSpacing: 2
                color:            theme.textMuted
                opacity:          root.collapsed ? 0 : 0.6
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            // Nav items
            Repeater {
                model: root.navItems
                delegate: NavItem {
                    theme:     root.theme
                    label:     modelData.label
                    icon:      modelData.icon
                    active:    index === root.activeIndex
                    collapsed: root.collapsed
                    width:     navCol.width
                    height:    38
                    topPadding: index === 0 ? 4 : 0
                    onClicked: root.navSelected(index)
                }
            }
        }

        // ── Footer divider ────────────────────────────────
        Rectangle {
            id: footerDivider
            anchors.bottom:      userRow.top
            anchors.left:        parent.left
            anchors.right:       parent.right
            anchors.leftMargin:  12
            anchors.rightMargin: 12
            height: 1
            color:  theme.border
        }

        // ── User row ──────────────────────────────────────
        Item {
            id: userRow
            anchors.bottom: parent.bottom
            anchors.left:   parent.left
            anchors.right:  parent.right
            height: 52

            Row {
                anchors.left:           parent.left
                anchors.leftMargin:     collapsed ? 0 : 14
                anchors.verticalCenter: parent.verticalCenter
                width:                  collapsed ? parent.width : undefined
                spacing: 9

                // Avatar
                Rectangle {
                    width: 24; height: 24; radius: 12
                    color: theme.surface2
                    border.color: theme.border
                    border.width: 1
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.centerIn: parent
                        text:           "M"
                        font.family:    "Poppins"
                        font.pixelSize: 9
                        font.weight:    Font.SemiBold
                        color:          theme.textMuted
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text:           "mateo"
                    font.family:    "Poppins"
                    font.pixelSize: 11
                    color:          theme.textMuted
                    opacity:        root.collapsed ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }
            }
        }
    }
}
```

- [ ] **Step 2: Atualizar main.qml para instanciar Sidebar**

```qml
// src/qml/main.qml
import QtQuick
import QtQuick.Window

Window {
    id: root
    width: 1280
    height: 800
    minimumWidth: 960
    minimumHeight: 600
    title: "Trocker"
    visible: true

    property bool collapsed:   false
    property int  activeIndex: 0

    Theme { id: theme }

    Rectangle {
        anchors.fill: parent
        color: theme.bg

        Sidebar {
            id: sidebar
            anchors.top:    parent.top
            anchors.left:   parent.left
            anchors.bottom: parent.bottom
            theme:          theme
            collapsed:      root.collapsed
            activeIndex:    root.activeIndex
            onNavSelected:  (i) => root.activeIndex = i
            onToggleCollapse: root.collapsed = !root.collapsed
        }

        // Content placeholder
        Item {
            anchors.left:   sidebar.right
            anchors.top:    parent.top
            anchors.right:  parent.right
            anchors.bottom: parent.bottom

            Column {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:             root.activeIndex === 0 ? "Projects"
                                    : root.activeIndex === 1 ? "Tracker"
                                    : root.activeIndex === 2 ? "Homography"
                                    : root.activeIndex === 3 ? "Reports"
                                    : "Settings"
                    font.family:    "Rajdhani"
                    font.weight:    Font.Bold
                    font.pixelSize: 52
                    font.letterSpacing: 2
                    color:          theme.textPrimary
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text:           "content area"
                    font.family:    "Poppins"
                    font.pixelSize: 12
                    color:          theme.textMuted
                }
            }
        }
    }
}
```

- [ ] **Step 3: Rodar e verificar visualmente**

```bash
trocker\Scripts\python src\main.py
```

Checar:
- Sidebar aparece com fundo `#161619`
- Logo mark branco com "T" escuro visível
- 5 nav items com ícones e labels
- Item ativo (Projects) tem pill de fundo e barra esquerda
- Hover nos itens muda a cor suavemente
- User row no rodapé com avatar "M"

- [ ] **Step 4: Commit**

```bash
git add src/qml/Sidebar.qml src/qml/main.qml
git commit -m "feat: add Sidebar.qml with nav items, header and user row"
```

---

### Task 4: Adicionar botão de colapso

**Files:**
- Modify: `src/qml/Sidebar.qml`

Botão circular `28px` posicionado na borda direita da sidebar, centralizado verticalmente. Fica sobre o conteúdo (`z: 10`). Mostra `‹` quando expandida, `›` quando colapsada.

- [ ] **Step 1: Adicionar o botão ao Rectangle surface em Sidebar.qml**

Adicionar este bloco **dentro do Rectangle principal** (após o bloco do `userRow`), antes do fechamento do Rectangle:

```qml
        // ── Collapse toggle button ────────────────────────
        Rectangle {
            id: collapseBtn
            anchors.right:          parent.right
            anchors.rightMargin:    -14   // metade do botão fica fora
            anchors.verticalCenter: parent.verticalCenter
            width:  28; height: 28; radius: 14
            color:  btnHovered ? theme.surface2 : theme.surface
            border.color: theme.border
            border.width: 1
            z: 10

            Behavior on color { ColorAnimation { duration: 150 } }

            property bool btnHovered: false

            Text {
                anchors.centerIn: parent
                text:           root.collapsed ? "›" : "‹"
                font.pixelSize: 13
                color:          theme.textMuted
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape:  Qt.PointingHandCursor
                onEntered: parent.btnHovered = true
                onExited:  parent.btnHovered = false
                onClicked: root.toggleCollapse()
            }
        }
```

- [ ] **Step 2: Garantir que o Item raiz não tem `clip: true` bloqueando o botão**

O `clip: true` no `Item` raiz de Sidebar.qml vai cortar o botão que ultrapassa a borda. Remover `clip: true` do Item raiz. A animação de largura ainda funciona porque os filhos são limitados pela largura do Rectangle interno.

Linha a remover em `Sidebar.qml`:
```qml
    clip: true   // ← remover esta linha
```

- [ ] **Step 3: Rodar e verificar**

```bash
trocker\Scripts\python src\main.py
```

Checar:
- Botão aparece na borda direita da sidebar, centralizado verticalmente
- Mostra `‹` quando expandida
- Clique colapsa a sidebar em 280ms com animação suave
- Labels somem com fade durante o colapso
- Botão muda para `›` quando colapsada
- Clique novamente expande
- Hover no botão muda o fundo sutilmente

- [ ] **Step 4: Commit**

```bash
git add src/qml/Sidebar.qml
git commit -m "feat: add collapse toggle button to sidebar right edge"
```

---

### Task 5: Tooltip nos nav items quando colapsada

**Files:**
- Verify: `src/qml/NavItem.qml`

O ToolTip já está definido em NavItem.qml (Task 2). Este task verifica o comportamento e ajusta se necessário.

- [ ] **Step 1: Rodar app, colapsar sidebar e testar tooltips**

```bash
trocker\Scripts\python src\main.py
```

1. Clicar no botão `‹` para colapsar
2. Passar o mouse sobre cada ícone e aguardar 500ms
3. Verificar que o tooltip aparece com o nome correto ("Projects", "Tracker", etc.)

- [ ] **Step 2: Se o ToolTip não aparecer — adicionar import**

Se o tooltip não aparecer, verificar se `import QtQuick.Controls` está no topo de `NavItem.qml`. Já está incluído no código do Task 2.

- [ ] **Step 3: Commit final de ajustes**

```bash
git add src/qml/NavItem.qml
git commit -m "fix: verify tooltip behavior in collapsed nav items"
```

---

## Chunk 3: Polimento e entrega

### Task 6: Ajustes de alinhamento no estado colapsado

**Files:**
- Modify: `src/qml/Sidebar.qml`

Quando colapsada, o logomark e o avatar precisam estar centralizados em 64px.

- [ ] **Step 1: Verificar alinhamento visual da sidebar colapsada**

Com o app rodando e sidebar colapsada, confirmar:
- Logo mark (retângulo branco "T") está centralizado horizontalmente em 64px
- Dot verde do projeto ativo está centralizado (badge some com fade — OK)
- Ícones dos nav items estão centralizados (NavItem já trata isso via `horizontalAlignment`)
- Avatar "M" do user row está centralizado

- [ ] **Step 2: Corrigir centralização do header colapsado se necessário**

Se o logo mark não estiver centralizado quando colapsado, ajustar o `Column` do header para usar `anchors.horizontalCenter` no estado colapsado:

```qml
// Dentro do header Item, substituir o Column existente por:
Item {
    anchors.fill: parent
    anchors.margins: 14

    // Logo mark — sempre centralizado quando colapsado
    Rectangle {
        id: logoMark
        width: 26; height: 26; radius: 6
        color: theme.textPrimary
        anchors.horizontalCenter: root.collapsed ? parent.horizontalCenter : undefined
        anchors.left:             root.collapsed ? undefined : parent.left
        anchors.verticalCenter:   parent.verticalCenter

        Text {
            anchors.centerIn: parent
            text:           "T"
            font.family:    "Rajdhani"
            font.weight:    Font.Bold
            font.pixelSize: 14
            color:          theme.bg
        }
    }

    Text {
        anchors.left:           logoMark.right
        anchors.leftMargin:     8
        anchors.verticalCenter: parent.verticalCenter
        text:             "TROCKER"
        font.family:      "Rajdhani"
        font.weight:      Font.Bold
        font.pixelSize:   15
        font.letterSpacing: 3
        color:            theme.textPrimary
        opacity:          root.collapsed ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }
}
```

- [ ] **Step 3: Verificar e commitar**

```bash
trocker\Scripts\python src\main.py
```

```bash
git add src/qml/Sidebar.qml
git commit -m "fix: center sidebar elements in collapsed state"
```

---

### Task 7: Verificação final e commit de entrega

**Files:** todos os arquivos QML

- [ ] **Step 1: Rodar checklist visual completo**

```bash
trocker\Scripts\python src\main.py
```

| Item | Esperado |
|------|----------|
| Sidebar expandida | 220px, fundo `#161619`, borda direita sutil |
| Logo | Mark branco 26px + "TROCKER" Rajdhani Bold |
| Project badge | Dot verde + "Nenhum projeto ativo" |
| Nav items | 5 items, ícone + label, spacing correto |
| Active state | Pill de fundo + barra esquerda 2px branca |
| Hover | Pill aparece com 150ms de transição |
| Botão colapso | Círculo na borda direita, centralizado, mostra `‹` |
| Colapso | Anima em 280ms OutCubic até 64px |
| Labels | Somem com fade 200ms durante colapso |
| Ícones colapsados | Centralizados, tooltip após 500ms |
| Botão colapsado | Mostra `›`, clique expande |
| User row | Avatar "M" visível, nome some quando colapsado |
| Content area | Mostra nome da página ativa em Rajdhani 52px |
| Nav click | Muda activeIndex, content area atualiza |

- [ ] **Step 2: Commit final**

```bash
git add src/qml/
git commit -m "feat: complete sidebar redesign — collapsible, Arc-inspired, component-based"
```

---

## Resumo dos arquivos criados

| Arquivo | Responsabilidade |
|---------|-----------------|
| `src/qml/Theme.qml` | Tokens de cor e dimensões |
| `src/qml/NavItem.qml` | Item de navegação reutilizável |
| `src/qml/Sidebar.qml` | Sidebar completa com colapso |
| `src/qml/main.qml` | Orquestração de estado e layout |
