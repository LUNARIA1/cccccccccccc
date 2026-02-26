/* ========================================
   RisuAI Theme Studio — Main Application
   ======================================== */

// ============================================================
// STATE
// ============================================================
const state = {
    settings: loadSettings(),
    history: loadHistory(),
    chatSessions: loadChatSessions(),
    currentSessionId: null,
    chatMessages: [],
    isGenerating: false,
};

function defaultSettings() {
    return {
        provider: 'gemini',
        geminiSubProvider: 'aistudio',
        apiKey: '',
        vertexProjectId: '',
        vertexClientEmail: '',
        vertexPrivateKey: '',
        customApiUrl: '',
        customModelId: '',
        model: '',
        temperature: 0.7,
        geminiCodeExecution: false,
        geminiGrounding: false,
        geminiUrlContext: false,
    };
}

function loadSettings() {
    try {
        const s = JSON.parse(localStorage.getItem('risu-studio-settings'));
        return s ? { ...defaultSettings(), ...s } : defaultSettings();
    } catch { return defaultSettings(); }
}

function saveSettings() {
    localStorage.setItem('risu-studio-settings', JSON.stringify(state.settings));
}

function loadHistory() {
    try {
        return JSON.parse(localStorage.getItem('risu-studio-history')) || [];
    } catch { return []; }
}

function saveHistory() {
    localStorage.setItem('risu-studio-history', JSON.stringify(state.history));
}

function loadChatSessions() {
    try {
        return JSON.parse(localStorage.getItem('risu-studio-chat-sessions')) || [];
    } catch { return []; }
}

function saveChatSessions() {
    localStorage.setItem('risu-studio-chat-sessions', JSON.stringify(state.chatSessions));
}

// ============================================================
// DOM REFERENCES
// ============================================================
const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

const editorHtml = $('#editor-html');
const editorCss = $('#editor-css');
const previewWrapper = $('#preview-frame-wrapper');
const chatMessages = $('#chat-messages');
const chatInput = $('#chat-input');
const btnSend = $('#btn-send');

// ============================================================
// DEFAULT THEME (Apple-style)
// ============================================================
const DEFAULT_HTML = `{{#when {{equal::{{role}}::user}}}}
<div class="apple-msg-row apple-msg-sent" style="width:100%;">
    <div class="apple-msg-bubble apple-bubble-user">
        <risutextbox></risutextbox>
    </div>
</div>
{{:else}}
<div class="apple-msg-row apple-msg-received" style="width:100%;">
    <div class="apple-avatar-wrapper">
        <risuicon></risuicon>
    </div>
    <div class="apple-msg-content">
        <div class="apple-msg-header">
            <span class="apple-sender-name">{{char}}</span>
        </div>
        <div class="apple-msg-bubble apple-bubble-char">
            <risutextbox></risutextbox>
        </div>
        <div class="apple-msg-actions">
            <risubuttons></risubuttons>
            <risugeninfo></risugeninfo>
        </div>
    </div>
</div>
{{/when}}`;

const DEFAULT_CSS = `/* ═══════════════════════════════════════
   Apple-Inspired RisuAI Theme
   Soft, clean, and elegant
   ═══════════════════════════════════════ */

@import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');

:root {
    /* — Color Palette — */
    --apple-bg: #1c1c1e;
    --apple-surface: #2c2c2e;
    --apple-surface-hover: #3a3a3c;
    --apple-bubble-char: #2c2c2e;
    --apple-bubble-user: #0a84ff;
    --apple-text: #f5f5f7;
    --apple-text-secondary: #98989d;
    --apple-text-user: #ffffff;
    --apple-border: rgba(255, 255, 255, 0.08);
    --apple-accent: #0a84ff;
    --apple-green: #30d158;
    --apple-radius: 18px;

    /* — Font Colors (RisuAI CBS) — */
    --FontColorStandard: #f5f5f7;
    --FontColorBold: #ffffff;
    --FontColorItalic: #b0b0b5;
    --FontColorItalicBold: #c0c0c8;
    --FontColorQuote1: #64d2ff;
    --FontColorQuote2: #ffd60a;
}

/* — Chat Background — */
.risu-chat > div {
    padding: 0;
    margin: 0 auto;
    display: flex;
    justify-content: center;
    width: 100%;
}

.risu-chat > div > div {
    width: 100%;
    max-width: 640px;
    margin: 0 auto;
}

/* — Message Row — */
.apple-msg-row {
    display: flex;
    gap: 10px;
    padding: 3px 16px;
    animation: apple-fadeIn 0.35s ease-out;
}

@keyframes apple-fadeIn {
    from { opacity: 0; transform: translateY(6px); }
    to { opacity: 1; transform: translateY(0); }
}

.apple-msg-sent {
    justify-content: flex-end;
}

.apple-msg-received {
    justify-content: flex-start;
    align-items: flex-start;
}

/* — Avatar — */
.apple-avatar-wrapper {
    width: 36px;
    height: 36px;
    border-radius: 50%;
    overflow: hidden;
    flex-shrink: 0;
    margin-top: 22px;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
}

.apple-avatar-wrapper > *,
.apple-avatar-wrapper > * > *,
.apple-avatar-wrapper > * > * > * {
    width: 100% !important;
    height: 100% !important;
    border-radius: 50% !important;
    object-fit: cover !important;
}

/* — Message Content Wrapper — */
.apple-msg-content {
    display: flex;
    flex-direction: column;
    max-width: 75%;
    min-width: 0;
}

/* — Message Header — */
.apple-msg-header {
    display: flex;
    align-items: baseline;
    gap: 8px;
    padding: 0 4px;
    margin-bottom: 3px;
}

.apple-sender-name {
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    font-size: 13px;
    font-weight: 600;
    color: #f5f5f7;
    letter-spacing: -0.2px;
}

.apple-msg-time {
    font-family: 'Inter', -apple-system, sans-serif;
    font-size: 11px;
    color: #98989d;
    font-weight: 400;
}

/* — Bubble — */
.apple-msg-bubble {
    padding: 10px 14px;
    line-height: 1.55;
    font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
    font-size: 15px;
    letter-spacing: -0.1px;
    word-break: break-word;
    color: #f5f5f7;
}

.apple-bubble-char {
    background: #2c2c2e;
    color: #f5f5f7;
    border-radius: var(--apple-radius) var(--apple-radius) var(--apple-radius) 4px;
    border: 1px solid rgba(255, 255, 255, 0.08);
}

.apple-bubble-user {
    background: #0a84ff;
    color: #ffffff;
    border-radius: var(--apple-radius) var(--apple-radius) 4px var(--apple-radius);
    max-width: 75%;
}

/* — Text Formatting inside bubbles — */
.apple-msg-bubble .chattext,
.apple-msg-bubble .chattext p,
.apple-msg-bubble .chattext span,
.apple-msg-bubble .chattext div {
    color: #f5f5f7;
    margin: 3px 0;
    line-height: 1.55;
}

.apple-bubble-user .chattext,
.apple-bubble-user .chattext p,
.apple-bubble-user .chattext span,
.apple-bubble-user .chattext div {
    color: #ffffff;
}

.apple-msg-bubble .chattext em {
    color: #b0b0b5;
    font-style: italic;
}

.apple-msg-bubble .chattext strong {
    color: #ffffff;
    font-weight: 600;
}

.apple-msg-bubble .chattext mark[risu-mark="quote1"] {
    color: #64d2ff;
    background: rgba(100, 210, 255, 0.1);
    border-radius: 3px;
    padding: 1px 3px;
}

.apple-msg-bubble .chattext mark[risu-mark="quote2"] {
    color: #ffd60a;
    background: rgba(255, 214, 10, 0.1);
    border-radius: 3px;
    padding: 1px 3px;
}

.apple-msg-bubble .chattext blockquote {
    border-left: 3px solid #0a84ff;
    padding-left: 10px;
    margin: 6px 0;
    color: #98989d;
    font-style: italic;
}

/* — Markdown: Headings — */
.apple-msg-bubble .chattext h1,
.apple-msg-bubble .chattext h2,
.apple-msg-bubble .chattext h3,
.apple-msg-bubble .chattext h4,
.apple-msg-bubble .chattext h5,
.apple-msg-bubble .chattext h6 {
    color: #ffffff;
    font-weight: 700;
    line-height: 1.3;
    margin: 12px 0 6px 0;
}
.apple-msg-bubble .chattext h1 { font-size: 1.5em; }
.apple-msg-bubble .chattext h2 { font-size: 1.3em; }
.apple-msg-bubble .chattext h3 { font-size: 1.15em; }
.apple-msg-bubble .chattext h4,
.apple-msg-bubble .chattext h5,
.apple-msg-bubble .chattext h6 { font-size: 1em; }

/* — Markdown: Lists — */
.apple-msg-bubble .chattext ul,
.apple-msg-bubble .chattext ol {
    color: #f5f5f7;
    padding-left: 20px;
    margin: 6px 0;
}
.apple-msg-bubble .chattext ul { list-style-type: disc; }
.apple-msg-bubble .chattext ol { list-style-type: decimal; }
.apple-msg-bubble .chattext li {
    color: #f5f5f7;
    margin: 2px 0;
}

/* — Markdown: Inline Code — */
.apple-msg-bubble .chattext code {
    background: rgba(255, 255, 255, 0.1);
    color: #ff9f0a;
    padding: 1px 5px;
    border-radius: 4px;
    font-family: 'SF Mono', 'Menlo', 'Consolas', monospace;
    font-size: 0.9em;
}

/* — Markdown: Code Block — */
.apple-msg-bubble .chattext pre {
    background: rgba(0, 0, 0, 0.4);
    border: 1px solid rgba(255, 255, 255, 0.08);
    border-radius: 8px;
    padding: 12px;
    margin: 8px 0;
    overflow-x: auto;
}
.apple-msg-bubble .chattext pre code {
    background: transparent;
    color: #f5f5f7;
    padding: 0;
    font-size: 0.85em;
    line-height: 1.5;
}

/* — Markdown: Links — */
.apple-msg-bubble .chattext a {
    color: #0a84ff;
    text-decoration: underline;
    text-decoration-color: rgba(10, 132, 255, 0.4);
    transition: text-decoration-color 0.2s;
}
.apple-msg-bubble .chattext a:hover {
    text-decoration-color: #0a84ff;
}

/* — Markdown: Horizontal Rule — */
.apple-msg-bubble .chattext hr {
    border: none;
    border-top: 1px solid rgba(255, 255, 255, 0.12);
    margin: 12px 0;
}

/* — Markdown: Tables — */
.apple-msg-bubble .chattext table {
    width: 100%;
    border-collapse: collapse;
    margin: 8px 0;
    font-size: 0.9em;
}
.apple-msg-bubble .chattext th {
    color: #ffffff;
    font-weight: 600;
    text-align: left;
    padding: 6px 10px;
    border-bottom: 2px solid rgba(255, 255, 255, 0.15);
}
.apple-msg-bubble .chattext td {
    color: #f5f5f7;
    padding: 5px 10px;
    border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

/* — Tailwind prose 오버라이드 — */
.apple-msg-bubble .chattext h1,
.apple-msg-bubble .chattext h2,
.apple-msg-bubble .chattext h3,
.apple-msg-bubble .chattext h4,
.apple-msg-bubble .chattext h5,
.apple-msg-bubble .chattext h6,
.apple-msg-bubble .chattext ul,
.apple-msg-bubble .chattext ol,
.apple-msg-bubble .chattext li,
.apple-msg-bubble .chattext code,
.apple-msg-bubble .chattext pre,
.apple-msg-bubble .chattext a,
.apple-msg-bubble .chattext table,
.apple-msg-bubble .chattext th,
.apple-msg-bubble .chattext td,
.apple-msg-bubble .chattext hr {
    --tw-prose-headings: #ffffff;
    --tw-prose-links: #0a84ff;
    --tw-prose-code: #ff9f0a;
}

/* — Action Buttons — */
.apple-msg-actions {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 4px 4px 0;
    opacity: 0;
    transition: opacity 0.2s ease;
}

.apple-msg-row:hover .apple-msg-actions {
    opacity: 1;
}

.apple-msg-actions button {
    background: none !important;
    border: none !important;
    color: #98989d !important;
    cursor: pointer !important;
    padding: 4px !important;
    border-radius: 6px !important;
    transition: all 0.15s ease !important;
    font-size: 12px !important;
}

.apple-msg-actions button:hover {
    background: #3a3a3c !important;
    color: #f5f5f7 !important;
}

/* — Scrollbar — */
::-webkit-scrollbar {
    width: 6px;
}
::-webkit-scrollbar-track {
    background: transparent;
}
::-webkit-scrollbar-thumb {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 3px;
}
::-webkit-scrollbar-thumb:hover {
    background: rgba(255, 255, 255, 0.2);
}`;

// Provider-specific placeholder hints for model ID input
const MODEL_PLACEHOLDERS = {
    gemini: 'gemini-2.0-flash',
    claude: 'claude-sonnet-4-20250514',
    openai: 'gpt-4.1',
    custom: 'model-name',
};

// ============================================================
// SYSTEM PROMPT
// ============================================================
const SYSTEM_PROMPT = `당신은 RisuAI 테마 디자인 전문 AI 어시스턴트입니다. 사용자의 요청에 따라 RisuAI Custom HTML과 Custom CSS를 작성하거나 수정합니다.

## RisuAI 테마 구조
- **Custom HTML (Chatting HTML)**: 각 채팅 메시지의 레이아웃을 정의합니다. \`db.theme\`이 \`'customHTML'\`일 때 적용됩니다.
- **Custom CSS**: 전역 스타일을 정의합니다. 애플리케이션 전체에 적용됩니다.

## Custom HTML 특수 태그
이 태그들은 RisuAI 전용 Svelte 컴포넌트로 치환됩니다:
- \`<risutextbox></risutextbox>\` — 메시지 텍스트 내용이 렌더링되는 곳 (필수)
- \`<risuicon></risuicon>\` — 발신자의 아바타/아이콘 이미지
- \`<risubuttons></risubuttons>\` — 액션 버튼 행 (복사, 편집, 번역 등)
- \`<risugeninfo></risugeninfo>\` — 생성 메타데이터 (모델명, 토큰수 등)

### risuicon 아이콘 숨기기 대응
RisuAI에서 '아이콘 UI 숨기기'가 활성화되면 \`<risuicon>\`은 **아무것도 렌더링하지 않습니다** (빈 요소조차 없음). 하지만 \`<risuicon>\`을 감싸는 아바타 컨테이너 div는 Custom HTML에 직접 작성한 것이므로 **빈 채로 남아 공간을 차지합니다.**
반드시 아바타 컨테이너에 \`:empty\` 규칙을 추가하세요:
\`\`\`css
/* 아이콘 숨기기 대응: 내용물 없으면 컨테이너 숨김 */
.my-avatar-container:empty {
    display: none;
}
\`\`\`

## 🚨 중요: 부모 래퍼 구조 & 우측 정렬 문제
Custom HTML은 다음과 같은 중첩 flex 컨테이너 안에 렌더링됩니다:
\`\`\`html
<div class="flex max-w-full justify-center risu-chat">
    <div class="flexium items-start max-w-full grow">
        <div style="">  <!-- ⚠️ RisuAI가 자동 생성하는 보이지 않는 래퍼! width 없음! -->
            <!-- 여기에 Custom HTML이 렌더링됨 -->
        </div>
    </div>
</div>
\`\`\`
- \`.flexium\` = display: flex; flex-direction: row; justify-content: flex-start;
- **⚠️ 핵심 문제**: RisuAI가 Custom HTML 바깥에 **빈 \`<div style="">\`을 자동으로 추가**합니다. 이 div에는 width가 없어서 내용물 크기만큼만 줄어듭니다. 따라서 아무리 안쪽에서 \`justify-content: flex-end\`를 사용해도 **유저 메시지 우측 정렬이 작동하지 않습니다.**

### 필수 해결 패턴
1. **HTML**: 최상위에 고유 래퍼 클래스를 반드시 사용하세요:
\`\`\`html
{{#when {{equal::{{role}}::user}}}}
<div class="my-wrapper">  <!-- 고유 래퍼 -->
    <div class="my-row my-user">...</div>
</div>
{{:else}}
<div class="my-wrapper">
    <div class="my-row my-char">...</div>
</div>
{{/when}}
\`\`\`

2. **CSS**: \`:has()\` 선택자로 보이지 않는 부모 div의 너비를 강제 설정하세요:
\`\`\`css
/* 필수: RisuAI 자동 부모 div 너비 강제 */
.flexium:has(.my-wrapper) > div {
    width: 100%;
    flex: 1 1 100%;
}

.my-wrapper {
    width: 100%;
    display: block;
}
\`\`\`
이 패턴 없이는 유저 메시지의 우측 정렬이 **절대** 작동하지 않습니다.

## 지원되는 HTML 요소
블록: div, p, h1~h6, ul, ol, li, table, tr, td, th, pre, blockquote
인라인: span, a(target="_blank", https만), em, strong, u, del, code, button
Void: img, hr, br
특수: style (인라인 CSS 블록 지원)
목록에 없는 태그는 div로 폴백됩니다.

## CBS (Curly Bracket Syntax) — 소스코드 검증 완료
기본 변수:
- \`{{char}}\` / \`{{bot}}\` — 캐릭터 이름
- \`{{user}}\` — 사용자 이름
- \`{{role}}\` — 메시지 역할 ("user", "char")
- \`{{chatindex}}\` — 메시지 인덱스 (0-based)
- \`{{isfirstmsg}}\` — 첫 메시지이면 "1", 아니면 "0"

비교 함수 ("1" 또는 "0" 반환):
- \`{{equal::A::B}}\` — A와 B가 같으면 "1"
- \`{{notequal::A::B}}\` — A와 B가 다르면 "1"
- \`{{greater::A::B}}\` — A > B이면 "1"
- \`{{less::A::B}}\` — A < B이면 "1"

조건문 (#when):
- \`{{#when CONDITION}}...{{/when}}\` — CONDITION이 "1" 또는 "true"이면 표시
- \`{{#when CONDITION}}...{{:else}}...{{/when}}\` — else 포함
- 역할 기반 조건: \`{{#when {{equal::{{role}}::user}}}}\` — 사용자 메시지일 때

변수:
- \`{{getvar::name}}\` — 채팅 변수 읽기
- \`{{setvar::name::value}}\` — 채팅 변수 쓰기

## ⚡ 중요: risutextbox 내부 렌더링 구조
\`<risutextbox>\`는 RisuAI에서 다음 DOM 구조로 치환됩니다. **마크다운이 HTML로 변환**되어 렌더링됩니다:
\`\`\`html
<span class="chattext prose">
    <p>일반 텍스트</p>
    <p><strong>볼드</strong></p>
    <p><em>이탤릭</em></p>
    <p><mark risu-mark="quote1">"큰따옴표 대화문"</mark></p>
    <p><mark risu-mark="quote2">'작은따옴표 대화문'</mark></p>
    <blockquote>인용문</blockquote>
    <!-- 마크다운에서 변환되는 요소들 -->
    <h1>제목1</h1> <h2>제목2</h2> <h3>제목3</h3>
    <ul><li>순서 없는 목록</li></ul>
    <ol><li>순서 있는 목록</li></ol>
    <code>인라인 코드</code>
    <pre><code>코드 블록</code></pre>
    <a href="...">링크</a>
    <hr>
    <table><tr><th>헤더</th></tr><tr><td>셀</td></tr></table>
</span>
\`\`\`
⚠️ **중요**: chattext에는 Tailwind의 \`.prose\` 클래스가 적용되어 있어, \`--tw-prose-headings\`, \`--tw-prose-links\` 등의 기본 색상이 적용됩니다. 커스텀 테마에서는 이 prose 스타일도 반드시 오버라이드해야 합니다.
CSS에서 텍스트 스타일을 지정할 때 반드시 \`.chattext\`를 기준으로 선택자를 작성해야 합니다.

## ⚠️ CSS 필수 규칙 (반드시 준수)
1. **색상은 절대 var()만 사용하지 마세요.** RisuAI의 기본 테마 CSS가 덮어쓸 수 있습니다.
   - ❌ \`color: var(--my-text);\`
   - ✅ \`color: #504456;\`
   - 또는 \`:root\`에서 변수를 선언하되, \`.chattext\` 내부 요소에는 반드시 직접 색상값을 사용하세요.

2. **\`.chattext\` 내부 모든 요소에 명시적 color를 지정하세요:**
   \`\`\`css
   /* 필수: 기본 텍스트 색상 */
   .your-bubble .chattext,
   .your-bubble .chattext p,
   .your-bubble .chattext span,
   .your-bubble .chattext div {
       color: #504456;    /* 직접 색상값 */
   }
   
   /* 필수: 서식별 색상 */
   .your-bubble .chattext strong {
       color: #3C2E43;
       font-weight: 700;
   }
   .your-bubble .chattext em {
       color: #A396AD;
       font-style: italic;
   }
   
   /* 필수: 대화문 스타일 */
   .your-bubble .chattext mark[risu-mark="quote1"] {
       color: #5CA4BE;
       background: rgba(92, 164, 190, 0.15);
       border-radius: 4px;
       padding: 1px 4px;
   }
   .your-bubble .chattext mark[risu-mark="quote2"] {
       color: #A17DC2;
       background: rgba(161, 125, 194, 0.15);
       border-radius: 4px;
       padding: 1px 4px;
   }
   
   /* 필수: 인용문 */
   .your-bubble .chattext blockquote {
       border-left: 3px solid #86D2EE;
       padding-left: 10px;
       margin: 6px 0;
       color: #A396AD;
   }
   
   /* 필수: 마크다운 제목 */
   .your-bubble .chattext h1,
   .your-bubble .chattext h2,
   .your-bubble .chattext h3,
   .your-bubble .chattext h4,
   .your-bubble .chattext h5,
   .your-bubble .chattext h6 {
       color: #3C2E43;       /* 직접 색상값 */
       font-weight: 700;
       margin: 12px 0 6px 0;
   }
   .your-bubble .chattext h1 { font-size: 1.5em; }
   .your-bubble .chattext h2 { font-size: 1.3em; }
   .your-bubble .chattext h3 { font-size: 1.15em; }
   
   /* 필수: 목록 */
   .your-bubble .chattext ul,
   .your-bubble .chattext ol {
       color: #504456;
       padding-left: 20px;
       margin: 6px 0;
   }
   .your-bubble .chattext ul { list-style-type: disc; }
   .your-bubble .chattext ol { list-style-type: decimal; }
   .your-bubble .chattext li { color: #504456; }
   
   /* 필수: 코드 */
   .your-bubble .chattext code {
       background: rgba(0, 0, 0, 0.06);
       color: #D63384;
       padding: 1px 5px;
       border-radius: 4px;
       font-family: monospace;
       font-size: 0.9em;
   }
   .your-bubble .chattext pre {
       background: rgba(0, 0, 0, 0.05);
       border-radius: 8px;
       padding: 12px;
       margin: 8px 0;
       overflow-x: auto;
   }
   .your-bubble .chattext pre code {
       background: transparent;
       color: #504456;
       padding: 0;
   }
   
   /* 필수: 링크, 수평선, 테이블 */
   .your-bubble .chattext a { color: #0066CC; }
   .your-bubble .chattext hr { border-top: 1px solid rgba(0,0,0,0.1); }
   .your-bubble .chattext th,
   .your-bubble .chattext td {
       color: #504456;
       padding: 5px 10px;
       border-bottom: 1px solid rgba(0,0,0,0.08);
   }
   
   /* 필수: Tailwind prose 오버라이드 */
   .your-bubble .chattext {
       --tw-prose-headings: #3C2E43;
       --tw-prose-links: #0066CC;
       --tw-prose-code: #D63384;
   }
   \`\`\`

3. **유저 버블과 캐릭터 버블의 텍스트 색상이 다를 수 있으므로 각각 지정하세요.**

4. **\`--FontColorStandard\`, \`--FontColorBold\` 등의 변수는 \`:root\`에 선언하되, \`.chattext\` 선택자에서는 직접 색상을 쓰세요.** 이 변수들은 RisuAI 내부에서 참조하는 용도입니다.

## CSS 변수 (RisuAI 내부 참조용으로 :root에 선언)
텍스트/폰트 — 반드시 :root에 선언해야 RisuAI가 올바르게 인식합니다:
- \`--FontColorStandard\` — 일반 텍스트
- \`--FontColorBold\` — 볼드 텍스트
- \`--FontColorItalic\` — 이탤릭 텍스트
- \`--FontColorQuote1\` — 큰따옴표 대화문 스타일
- \`--FontColorQuote2\` — 작은따옴표 대화문 스타일

## 응답 규칙
1. HTML과 CSS를 수정할 때 반드시 다음 JSON 형식으로 응답에 포함하세요:
\`\`\`json
{"html": "여기에 전체 HTML", "css": "여기에 전체 CSS"}
\`\`\`
2. 부분 수정이 아닌 전체 HTML/CSS를 항상 포함하세요.
3. 설명은 한국어로 작성하세요.
4. 코드 변경사항을 간결하게 설명해주세요.
5. JSON 블록은 반드시 코드 블록(\`\`\`json ... \`\`\`) 안에 넣어주세요.
`;

// ============================================================
// PREVIEW
// ============================================================

// Sample preview content
const SAMPLE_MESSAGES = [
    {
        role: 'char',
        name: '캐릭터',
        text: `안녕하세요! 만나서 반가워요. 이것은 **일반 텍스트**와 다양한 서식의 예시입니다.\n"큰따옴표로 감싼 텍스트입니다" 그리고 '작은따옴표로 감싼 텍스트'도 있어요.\n*이탤릭 텍스트*와 **볼드 텍스트**, 그리고 ***이탤릭 볼드***도 테스트해 볼 수 있습니다.`,
    },
    {
        role: 'user',
        name: '사용자',
        text: `안녕! 반가워. 테마가 어떻게 보이는지 확인하고 있어.`,
    },
    {
        role: 'char',
        name: '캐릭터',
        text: `네! 이 프리뷰에서 다양한 서식을 확인할 수 있어요.\n> 이것은 인용문입니다.\n일반 텍스트도 잘 보이나요?`,
    },
    {
        role: 'char',
        name: '캐릭터',
        text: `## 마크다운 서식 테스트\n\n아래는 마크다운 요소들의 렌더링 예시입니다:\n\n- 첫 번째 항목\n- 두 번째 항목\n- **볼드 항목**\n\n인라인 \`코드\` 테스트입니다.\n\n---\n\n\`\`\`\nconst theme = 'custom';\nconsole.log(theme);\n\`\`\``,
    },
];

function renderPreview() {
    const html = editorHtml.value;
    const css = editorCss.value;

    if (!html.trim() && !css.trim()) {
        previewWrapper.innerHTML = `
            <div style="display:flex;flex-direction:column;align-items:center;justify-content:center;min-height:300px;color:var(--text-muted);text-align:center;gap:8px;">
                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" opacity="0.3"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="9" y1="9" x2="15" y2="15"/><line x1="15" y1="9" x2="9" y2="15"/></svg>
                <p style="font-size:13px;">HTML/CSS를 입력하면 여기에 미리보기가 표시됩니다</p>
            </div>`;
        return;
    }

    let previewHtml = '';
    for (const msg of SAMPLE_MESSAGES) {
        let msgHtml = html;

        // ★ Process conditionals FIRST (before replacing {{role}} etc.)
        // These regex patterns match the literal "{{role}}" text, so they must
        // run before variable substitution replaces it with "char"/"user".
        msgHtml = processCbsConditionals(msgHtml, msg.role);
        msgHtml = processLegacyConditionals(msgHtml, msg);

        // Then replace CBS variable placeholders with sample data
        msgHtml = msgHtml.replace(/\{\{char\}\}/g, msg.name === '캐릭터' ? '캐릭터' : '사용자');
        msgHtml = msgHtml.replace(/\{\{user\}\}/g, '사용자');
        msgHtml = msgHtml.replace(/\{\{bot\}\}/g, msg.name === '캐릭터' ? '캐릭터' : '사용자');
        msgHtml = msgHtml.replace(/\{\{role\}\}/g, msg.role);
        msgHtml = msgHtml.replace(/\{\{chatindex\}\}/g, String(SAMPLE_MESSAGES.indexOf(msg)));
        msgHtml = msgHtml.replace(/\{\{messagetime\}\}/g, new Date().toLocaleTimeString('ko-KR'));
        msgHtml = msgHtml.replace(/\{\{lastmessageid\}\}/g, String(SAMPLE_MESSAGES.length - 1));

        // Replace <risutextbox> with formatted text
        const formattedText = formatMessageText(msg.text);
        msgHtml = msgHtml.replace(/<risutextbox><\/risutextbox>/gi, `<div class="chattext">${formattedText}</div>`);

        // Replace <risuicon> with avatar image (char.png or user.png)
        const avatarSrc = msg.role === 'char' ? 'char.png' : 'user.png';
        msgHtml = msgHtml.replace(/<risuicon><\/risuicon>/gi,
            `<img src="${avatarSrc}" alt="${msg.name}" style="width:100%;height:100%;object-fit:cover;border-radius:inherit;">`);

        // Replace <risubuttons> with sample buttons
        msgHtml = msgHtml.replace(/<risubuttons><\/risubuttons>/gi,
            `<div style="display:flex;gap:1rem;align-items:center;">
                <button style="background:none;border:none;cursor:pointer;opacity:0.5;padding:4px;">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>
                </button>
                <button style="background:none;border:none;cursor:pointer;opacity:0.5;padding:4px;">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                </button>
            </div>`);

        // Replace <risugeninfo> with sample generation metadata
        msgHtml = msgHtml.replace(/<risugeninfo><\/risugeninfo>/gi,
            `<span style="font-size:11px;color:var(--apple-text-secondary, #98989d);opacity:0.6;margin-left:4px;">gemini-2.0-flash · 128 tokens</span>`);

        previewHtml += `
            <div class="flex max-w-full justify-center risu-chat" style="display:flex;max-width:100%;justify-content:center;">
                <div class="flexium items-start max-w-full grow" style="display:flex;flex-direction:row;justify-content:flex-start;align-items:flex-start;max-width:100%;flex-grow:1;">
                    ${msgHtml}
                </div>
            </div>`;
    }

    previewWrapper.innerHTML = `
        <style>${css}</style>
        <div class="preview-risu-chat">
            <div class="preview-chat-bg">
                ${previewHtml}
            </div>
        </div>`;
}

function processCbsConditionals(html, role) {
    // {{#when {{equal::{{role}}::VALUE}}}}...CONTENT...{{:else}}...ALT...{{/when}}
    const whenEqualRegex = /\{\{#when\s+\{\{equal::\{\{role\}\}::(\w+)\}\}\}\}([\s\S]*?)(?:\{\{:else\}\}([\s\S]*?))?\{\{\/when\}\}/g;
    html = html.replace(whenEqualRegex, (_, val, content, altContent) => {
        return role === val ? content : (altContent || '');
    });

    // {{#when {{not_equal::{{role}}::VALUE}}}}
    const whenNotEqualRegex = /\{\{#when\s+\{\{not_equal::\{\{role\}\}::(\w+)\}\}\}\}([\s\S]*?)(?:\{\{:else\}\}([\s\S]*?))?\{\{\/when\}\}/g;
    html = html.replace(whenNotEqualRegex, (_, val, content, altContent) => {
        return role !== val ? content : (altContent || '');
    });

    return html;
}

function processLegacyConditionals(html, msg) {
    // {{#if {{equal::{{role}}::char}}}} ... {{/if}} or {{/}}
    // Simple pattern matching for the most common cases
    const ifEqualRegex = /\{\{#if\s+\{\{equal::\{\{role\}\}::(\w+)\}\}\s*\}\}([\s\S]*?)\{\{\/(?:if)?\}\}/g;
    html = html.replace(ifEqualRegex, (_, val, content) => {
        return msg.role === val ? content : '';
    });

    const ifNotEqualRegex = /\{\{#if\s+\{\{not_equal::\{\{role\}\}::(\w+)\}\}\s*\}\}([\s\S]*?)\{\{\/(?:if)?\}\}/g;
    html = html.replace(ifNotEqualRegex, (_, val, content) => {
        return msg.role !== val ? content : '';
    });

    return html;
}

function formatMessageText(text) {
    let result = escapeHtml(text);

    // Code blocks (``` ... ```) — process FIRST before other formatting
    result = result.replace(/```([\s\S]*?)```/g, (_, code) => {
        return `</p><pre><code>${code.replace(/<br>/g, '\n').trim()}</code></pre><p>`;
    });

    // Inline code (`code`)
    result = result.replace(/`([^`]+)`/g, '<code>$1</code>');

    // Headings (### before ## before #)
    result = result.replace(/^#{3}\s+(.*)$/gm, '</p><h3>$1</h3><p>');
    result = result.replace(/^#{2}\s+(.*)$/gm, '</p><h2>$1</h2><p>');
    result = result.replace(/^#{1}\s+(.*)$/gm, '</p><h1>$1</h1><p>');

    // Horizontal rule (--- or ***)
    result = result.replace(/^(-{3,}|\*{3,})$/gm, '</p><hr><p>');

    // Unordered list items (- item)
    result = result.replace(/(?:^|\n)((?:- .*(?:\n|$))+)/g, (_, block) => {
        const items = block.trim().split('\n').map(line =>
            `<li>${line.replace(/^- /, '')}</li>`
        ).join('');
        return `</p><ul>${items}</ul><p>`;
    });

    // Ordered list items (1. item)
    result = result.replace(/(?:^|\n)((?:\d+\. .*(?:\n|$))+)/g, (_, block) => {
        const items = block.trim().split('\n').map(line =>
            `<li>${line.replace(/^\d+\. /, '')}</li>`
        ).join('');
        return `</p><ol>${items}</ol><p>`;
    });

    // Links [text](url)
    result = result.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href=\'$2\' target=\'_blank\'>$1</a>');

    // Bold italic
    result = result.replace(/\*\*\*(.*?)\*\*\*/g, '<strong><em>$1</em></strong>');
    // Bold
    result = result.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    // Italic
    result = result.replace(/\*(.*?)\*/g, '<em>$1</em>');
    // Blockquote
    result = result.replace(/^&gt;\s?(.*)$/gm, '</p><blockquote>$1</blockquote><p>');
    // Double quotes
    result = result.replace(/&quot;(.*?)&quot;/g, '<mark risu-mark="quote1">"$1"</mark>');
    result = result.replace(/"(.*?)"/g, '<mark risu-mark="quote1">"$1"</mark>');
    // Single quotes (Korean style)
    result = result.replace(/&#x27;(.*?)&#x27;/g, '<mark risu-mark="quote2">\'$1\'</mark>');
    result = result.replace(/'(.*?)'/g, '<mark risu-mark="quote2">\'$1\'</mark>');
    // Line breaks
    result = result.replace(/\n/g, '<br>');

    // Clean up empty <p></p> tags
    result = `<p>${result}</p>`;
    result = result.replace(/<p><\/p>/g, '');
    result = result.replace(/<p><br>/g, '<p>');

    return result;
}

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

// ============================================================
// EDITOR TABS
// ============================================================
$$('.editor-tab').forEach(tab => {
    tab.addEventListener('click', () => {
        $$('.editor-tab').forEach(t => t.classList.remove('active'));
        $$('.editor-panel').forEach(p => p.classList.remove('active'));
        tab.classList.add('active');
        const panel = $(`#editor-${tab.dataset.tab}-panel`);
        if (panel) panel.classList.add('active');
    });
});

// Auto-refresh preview on input
let previewDebounce = null;
editorHtml.addEventListener('input', () => {
    clearTimeout(previewDebounce);
    previewDebounce = setTimeout(renderPreview, 300);
});
editorCss.addEventListener('input', () => {
    clearTimeout(previewDebounce);
    previewDebounce = setTimeout(renderPreview, 300);
});

$('#btn-preview-refresh').addEventListener('click', renderPreview);

// ============================================================
// RESIZE HANDLES
// ============================================================
setupVerticalResize();
setupHorizontalResize();

function setupVerticalResize() {
    const handle = $('#panel-resize-handle');
    const leftPanel = $('#left-panel');
    const rightPanel = $('#right-panel');
    let startX, leftW, rightW;

    handle.addEventListener('mousedown', (e) => {
        e.preventDefault();
        handle.classList.add('active');
        startX = e.clientX;
        leftW = leftPanel.offsetWidth;
        rightW = rightPanel.offsetWidth;
        document.addEventListener('mousemove', onMouseMove);
        document.addEventListener('mouseup', onMouseUp);
    });

    function onMouseMove(e) {
        const dx = e.clientX - startX;
        const newLeft = leftW + dx;
        const newRight = rightW - dx;
        if (newLeft >= 320 && newRight >= 300) {
            leftPanel.style.flex = 'none';
            leftPanel.style.width = newLeft + 'px';
            rightPanel.style.width = newRight + 'px';
        }
    }
    function onMouseUp() {
        handle.classList.remove('active');
        document.removeEventListener('mousemove', onMouseMove);
        document.removeEventListener('mouseup', onMouseUp);
    }
}

function setupHorizontalResize() {
    const handle = $('#editor-resize-handle');
    const preview = $('#preview-area');
    const editor = $('#editor-area');
    let startY, previewH, editorH;

    handle.addEventListener('mousedown', (e) => {
        e.preventDefault();
        handle.classList.add('active');
        startY = e.clientY;
        previewH = preview.offsetHeight;
        editorH = editor.offsetHeight;
        document.addEventListener('mousemove', onMouseMove);
        document.addEventListener('mouseup', onMouseUp);
    });

    function onMouseMove(e) {
        const dy = e.clientY - startY;
        const newPreview = previewH + dy;
        const newEditor = editorH - dy;
        if (newPreview >= 200 && newEditor >= 120) {
            preview.style.flex = 'none';
            preview.style.height = newPreview + 'px';
            editor.style.height = newEditor + 'px';
        }
    }
    function onMouseUp() {
        handle.classList.remove('active');
        document.removeEventListener('mousemove', onMouseMove);
        document.removeEventListener('mouseup', onMouseUp);
    }
}

// ============================================================
// SETTINGS MODAL
// ============================================================
$('#btn-settings').addEventListener('click', () => openModal('settings-modal'));
$('#btn-history').addEventListener('click', () => {
    renderHistoryList();
    openModal('history-modal');
});
$('#btn-export').addEventListener('click', () => {
    $('#export-html-content').textContent = editorHtml.value;
    $('#export-css-content').textContent = editorCss.value;
    openModal('export-modal');
});
$('#btn-new-chat').addEventListener('click', startNewChat);
$('#btn-chat-sessions').addEventListener('click', () => {
    renderChatSessionsList();
    openModal('chat-sessions-modal');
});

$$('.modal-close').forEach(btn => {
    btn.addEventListener('click', () => {
        const id = btn.dataset.close;
        closeModal(id);
    });
});

$$('.modal-overlay').forEach(overlay => {
    overlay.addEventListener('click', (e) => {
        if (e.target === overlay) closeModal(overlay.id);
    });
});

function openModal(id) {
    $(`#${id}`).classList.remove('hidden');
    if (id === 'settings-modal') populateSettingsUI();
}

function closeModal(id) {
    $(`#${id}`).classList.add('hidden');
}

// Provider/model dynamic fields
const providerSelect = $('#llm-provider');
const geminiSubSelect = $('#gemini-subprovider');
const modelInput = $('#llm-model');
const tempRange = $('#llm-temperature');
const tempValue = $('#temperature-value');

providerSelect.addEventListener('change', updateProviderFields);
geminiSubSelect.addEventListener('change', updateGeminiSubFields);
tempRange.addEventListener('input', () => {
    tempValue.textContent = tempRange.value;
});

// Visibility toggle
$$('.toggle-visibility').forEach(btn => {
    btn.addEventListener('click', () => {
        const target = $(`#${btn.dataset.target}`);
        target.type = target.type === 'password' ? 'text' : 'password';
    });
});

function populateSettingsUI() {
    const s = state.settings;
    providerSelect.value = s.provider;
    geminiSubSelect.value = s.geminiSubProvider;
    $('#llm-apikey').value = s.apiKey;
    $('#vertex-project-id').value = s.vertexProjectId;
    $('#vertex-client-email').value = s.vertexClientEmail;
    $('#vertex-private-key').value = s.vertexPrivateKey;
    $('#custom-api-url').value = s.customApiUrl;
    $('#custom-model-id').value = s.customModelId;
    modelInput.value = s.model || '';
    $('#gemini-code-execution').checked = s.geminiCodeExecution || false;
    $('#gemini-grounding').checked = s.geminiGrounding || false;
    $('#gemini-url-context').checked = s.geminiUrlContext || false;
    tempRange.value = s.temperature;
    tempValue.textContent = s.temperature;
    updateProviderFields();
}

function updateProviderFields() {
    const provider = providerSelect.value;
    // Show/hide groups
    $('#gemini-subprovider-group').classList.toggle('hidden', provider !== 'gemini');
    $('#custom-api-fields').classList.toggle('hidden', provider !== 'custom');
    $('#gemini-tools-group').classList.toggle('hidden', provider !== 'gemini');

    if (provider === 'gemini') {
        updateGeminiSubFields();
    } else {
        $('#apikey-group').classList.remove('hidden');
        $('#vertex-fields').classList.add('hidden');
    }

    // Update model input placeholder
    modelInput.placeholder = MODEL_PLACEHOLDERS[provider] || 'model-id';
}

function updateGeminiSubFields() {
    const sub = geminiSubSelect.value;
    if (sub === 'vertex') {
        $('#apikey-group').classList.add('hidden');
        $('#vertex-fields').classList.remove('hidden');
    } else {
        $('#apikey-group').classList.remove('hidden');
        $('#vertex-fields').classList.add('hidden');
    }
}

$('#btn-save-settings').addEventListener('click', () => {
    state.settings.provider = providerSelect.value;
    state.settings.geminiSubProvider = geminiSubSelect.value;
    state.settings.apiKey = $('#llm-apikey').value;
    state.settings.vertexProjectId = $('#vertex-project-id').value;
    state.settings.vertexClientEmail = $('#vertex-client-email').value;
    state.settings.vertexPrivateKey = $('#vertex-private-key').value;
    state.settings.customApiUrl = $('#custom-api-url').value;
    state.settings.customModelId = $('#custom-model-id').value;
    state.settings.model = modelInput.value.trim();
    state.settings.geminiCodeExecution = $('#gemini-code-execution').checked;
    state.settings.geminiGrounding = $('#gemini-grounding').checked;
    state.settings.geminiUrlContext = $('#gemini-url-context').checked;
    state.settings.temperature = parseFloat(tempRange.value);
    saveSettings();
    closeModal('settings-modal');
    showToast('설정이 저장되었습니다.', 'success');
});

// ============================================================
// HISTORY
// ============================================================
function addHistoryEntry() {
    const entry = {
        id: Date.now(),
        time: new Date().toLocaleString('ko-KR', {
            year: 'numeric', month: '2-digit', day: '2-digit',
            hour: '2-digit', minute: '2-digit', second: '2-digit',
        }),
        html: editorHtml.value,
        css: editorCss.value,
    };
    state.history.unshift(entry);
    // Keep last 50
    if (state.history.length > 50) state.history = state.history.slice(0, 50);
    saveHistory();
}

function renderHistoryList() {
    const list = $('#history-list');
    if (state.history.length === 0) {
        list.innerHTML = '<p class="history-empty">아직 저장된 히스토리가 없습니다.</p>';
        return;
    }
    list.innerHTML = state.history.map(entry => `
        <div class="history-item" data-id="${entry.id}">
            <div class="history-item-info">
                <div class="history-item-time">${entry.time}</div>
                <div class="history-item-preview">${escapeHtml((entry.html || '').substring(0, 80))}...</div>
            </div>
            <button class="history-item-delete" data-delete-id="${entry.id}" title="삭제">&times;</button>
        </div>
    `).join('');

    // Click to restore
    list.querySelectorAll('.history-item').forEach(item => {
        item.addEventListener('click', (e) => {
            if (e.target.closest('.history-item-delete')) return;
            const id = parseInt(item.dataset.id);
            const entry = state.history.find(h => h.id === id);
            if (entry) {
                editorHtml.value = entry.html;
                editorCss.value = entry.css;
                renderPreview();
                closeModal('history-modal');
                showToast('히스토리를 불러왔습니다.', 'success');
            }
        });
    });

    // Delete
    list.querySelectorAll('.history-item-delete').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            const id = parseInt(btn.dataset.deleteId);
            state.history = state.history.filter(h => h.id !== id);
            saveHistory();
            renderHistoryList();
        });
    });
}

// ============================================================
// EXPORT
// ============================================================
$('#btn-copy-html').addEventListener('click', () => {
    navigator.clipboard.writeText(editorHtml.value).then(() => showToast('HTML 복사됨!', 'success'));
});
$('#btn-copy-css').addEventListener('click', () => {
    navigator.clipboard.writeText(editorCss.value).then(() => showToast('CSS 복사됨!', 'success'));
});

// ============================================================
// TOAST
// ============================================================
function showToast(message, type = '') {
    const toast = document.createElement('div');
    toast.className = `toast ${type}`;
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
}

// ============================================================
// CHAT
// ============================================================

// Attachment state
const pendingAttachments = []; // { file, name, type, base64, dataUrl }
const fileInput = $('#file-input');
const attachPreview = $('#attachment-preview');

// File attach button
$('#btn-attach').addEventListener('click', () => fileInput.click());

fileInput.addEventListener('change', () => {
    handleFiles(fileInput.files);
    fileInput.value = ''; // reset so same file can be re-selected
});

// Drag & drop on chat input area
const chatInputArea = $('#chat-input-area');
chatInputArea.addEventListener('dragover', (e) => {
    e.preventDefault();
    chatInputArea.style.borderColor = 'var(--accent-primary)';
});
chatInputArea.addEventListener('dragleave', () => {
    chatInputArea.style.borderColor = '';
});
chatInputArea.addEventListener('drop', (e) => {
    e.preventDefault();
    chatInputArea.style.borderColor = '';
    if (e.dataTransfer.files.length) handleFiles(e.dataTransfer.files);
});

// Paste image from clipboard
chatInput.addEventListener('paste', (e) => {
    const items = e.clipboardData?.items;
    if (!items) return;
    const files = [];
    for (const item of items) {
        if (item.kind === 'file') {
            files.push(item.getAsFile());
        }
    }
    if (files.length > 0) handleFiles(files);
});

function handleFiles(fileList) {
    for (const file of fileList) {
        if (pendingAttachments.length >= 5) {
            showToast('최대 5개 파일까지 첨부 가능합니다.', 'error');
            break;
        }
        if (file.size > 20 * 1024 * 1024) {
            showToast(`파일이 너무 큽니다 (20MB 제한): ${file.name}`, 'error');
            continue;
        }
        readFileAsBase64(file).then(({ base64, dataUrl }) => {
            const attachment = {
                file,
                name: file.name,
                type: file.type,
                base64,
                dataUrl,
            };
            pendingAttachments.push(attachment);
            renderAttachmentPreview();
        });
    }
}

function readFileAsBase64(file) {
    return new Promise((resolve) => {
        const reader = new FileReader();
        reader.onload = () => {
            const dataUrl = reader.result;
            const base64 = dataUrl.split(',')[1];
            resolve({ base64, dataUrl });
        };
        reader.readAsDataURL(file);
    });
}

function renderAttachmentPreview() {
    if (pendingAttachments.length === 0) {
        attachPreview.classList.add('hidden');
        attachPreview.innerHTML = '';
        return;
    }
    attachPreview.classList.remove('hidden');
    attachPreview.innerHTML = pendingAttachments.map((att, i) => {
        const isImage = att.type.startsWith('image/');
        if (isImage) {
            return `<div class="attachment-item image-item">
                <img src="${att.dataUrl}" class="attachment-thumb" alt="${escapeHtml(att.name)}">
                <button class="attachment-remove" data-idx="${i}" title="제거">&times;</button>
            </div>`;
        }
        const icon = att.type.includes('pdf') ? '📄' : '📎';
        return `<div class="attachment-item">
            <span>${icon}</span>
            <span class="attachment-name">${escapeHtml(att.name)}</span>
            <button class="attachment-remove" data-idx="${i}" title="제거">&times;</button>
        </div>`;
    }).join('');

    attachPreview.querySelectorAll('.attachment-remove').forEach(btn => {
        btn.addEventListener('click', () => {
            pendingAttachments.splice(parseInt(btn.dataset.idx), 1);
            renderAttachmentPreview();
        });
    });
}

function clearAttachments() {
    pendingAttachments.length = 0;
    renderAttachmentPreview();
}

// Auto-resize input
chatInput.addEventListener('input', () => {
    chatInput.style.height = 'auto';
    chatInput.style.height = Math.min(chatInput.scrollHeight, 120) + 'px';
});

// Enter to send (Shift+Enter for newline)
chatInput.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage();
    }
});

btnSend.addEventListener('click', sendMessage);

// Suggestion chips
$$('.suggestion-chip').forEach(chip => {
    chip.addEventListener('click', () => {
        chatInput.value = chip.dataset.suggestion;
        sendMessage();
    });
});

async function sendMessage() {
    const text = chatInput.value.trim();
    if (!text || state.isGenerating) return;

    // Validate settings
    const s = state.settings;
    const provider = s.provider;
    if (provider !== 'custom') {
        if (provider === 'gemini' && s.geminiSubProvider === 'vertex') {
            if (!s.vertexProjectId || !s.vertexClientEmail || !s.vertexPrivateKey) {
                showToast('Vertex AI 설정을 먼저 완료해주세요.', 'error');
                return;
            }
        } else if (provider === 'gemini' || provider === 'claude' || provider === 'openai') {
            if (!s.apiKey) {
                showToast('API Key를 먼저 설정해주세요.', 'error');
                openModal('settings-modal');
                return;
            }
        }
    } else {
        if (!s.customApiUrl || !s.apiKey) {
            showToast('Custom API 설정을 완료해주세요.', 'error');
            return;
        }
    }

    // Remove welcome message
    const welcome = chatMessages.querySelector('.chat-welcome');
    if (welcome) welcome.remove();

    // Capture attachments before clearing
    const attachments = [...pendingAttachments];
    clearAttachments();

    // Build display text with attachment indicators
    let displayText = text;
    if (attachments.length > 0) {
        const names = attachments.map(a => a.type.startsWith('image/') ? `🖼️ ${a.name}` : `📎 ${a.name}`);
        displayText = names.join(', ') + '\n\n' + text;
    }

    // Add user message
    addChatMessage('user', displayText);
    state.chatMessages.push({
        role: 'user', content: text, attachments: attachments.map(a => ({
            name: a.name, type: a.type, base64: a.base64
        }))
    });
    chatInput.value = '';
    chatInput.style.height = 'auto';

    // Show typing indicator
    state.isGenerating = true;
    btnSend.disabled = true;
    setStatus('loading', '생성 중...');
    const typingEl = addTypingIndicator();

    try {
        // Build messages with context
        const contextMsg = buildContextMessage();
        const messages = [
            { role: 'system', content: SYSTEM_PROMPT },
            ...state.chatMessages.map(m => ({
                role: m.role === 'user' ? 'user' : 'assistant',
                content: m.content,
                attachments: m.attachments || [],
            })),
        ];
        // Inject context into the latest user message
        const lastIdx = messages.length - 1;
        messages[lastIdx].content = contextMsg + '\n\n' + messages[lastIdx].content;

        const response = await callLLM(messages);

        // Remove typing
        typingEl.remove();

        // Parse response for code blocks
        const { explanation, html, css } = parseAssistantResponse(response);

        // Add assistant message
        addChatMessage('assistant', explanation, html, css);
        state.chatMessages.push({ role: 'assistant', content: response });

        // Save history on every LLM response
        addHistoryEntry();

        // Auto-save chat session
        saveCurrentSession();

        setStatus('ready', '준비됨');
    } catch (err) {
        typingEl.remove();
        addChatMessage('assistant', `❌ 오류가 발생했습니다: ${err.message}`);
        setStatus('error', '오류 발생');
        console.error('LLM Error:', err);
    } finally {
        state.isGenerating = false;
        btnSend.disabled = false;
    }
}

function buildContextMessage() {
    const html = editorHtml.value;
    const css = editorCss.value;
    if (!html && !css) return '[현재 HTML/CSS가 비어있습니다.]';
    return `[현재 상태]
\`\`\`html
${html}
\`\`\`
\`\`\`css
${css}
\`\`\``;
}

function addChatMessage(role, text, html, css) {
    const msgDiv = document.createElement('div');
    msgDiv.className = `chat-msg ${role}`;

    const avatar = role === 'assistant' ? '✦' : '👤';

    // Format text: convert markdown-like syntax
    let formattedText = text;
    // Don't escape HTML for assistant messages that may contain code blocks
    if (role === 'assistant') {
        formattedText = formatAssistantMessage(text);
    } else {
        formattedText = `<p>${escapeHtml(text).replace(/\n/g, '<br>')}</p>`;
    }

    msgDiv.innerHTML = `
        <div class="chat-msg-avatar">${avatar}</div>
        <div class="chat-msg-bubble">
            <div class="chat-msg-content">${formattedText}</div>
            ${(html !== undefined || css !== undefined) ? `
                <button class="apply-changes-btn" onclick="applyChanges(this)" 
                    data-html="${html !== undefined ? encodeURIComponent(html) : ''}" 
                    data-css="${css !== undefined ? encodeURIComponent(css) : ''}">
                    ✨ 변경사항 적용
                </button>
            ` : ''}
        </div>
    `;

    chatMessages.appendChild(msgDiv);
    chatMessages.scrollTop = chatMessages.scrollHeight;
}

function formatAssistantMessage(text) {
    // Simple markdown formatting
    let result = escapeHtml(text);

    // Code blocks
    result = result.replace(/```(\w*)\n?([\s\S]*?)```/g, (_, lang, code) => {
        return `<pre><code>${code.trim()}</code></pre>`;
    });

    // Inline code
    result = result.replace(/`([^`]+)`/g, '<code>$1</code>');

    // Bold
    result = result.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');

    // Italic
    result = result.replace(/\*(.*?)\*/g, '<em>$1</em>');

    // Line breaks -> paragraphs
    const paragraphs = result.split(/\n\n+/);
    result = paragraphs.map(p => {
        if (p.startsWith('<pre>')) return p;
        return `<p>${p.replace(/\n/g, '<br>')}</p>`;
    }).join('');

    return result;
}

function addTypingIndicator() {
    const div = document.createElement('div');
    div.className = 'chat-msg assistant';
    div.innerHTML = `
        <div class="chat-msg-avatar">✦</div>
        <div class="chat-msg-bubble">
            <div class="chat-msg-content">
                <div class="typing-indicator">
                    <span></span><span></span><span></span>
                </div>
            </div>
        </div>
    `;
    chatMessages.appendChild(div);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    return div;
}

function setStatus(type, text) {
    const dot = $('.status-dot');
    const statusText = $('.status-text');
    dot.className = 'status-dot';
    if (type === 'loading') dot.classList.add('loading');
    if (type === 'error') dot.classList.add('error');
    statusText.textContent = text;
}

function parseAssistantResponse(response) {
    let html, css;
    let explanation = response;

    // Try to extract JSON code block
    const jsonMatch = response.match(/```json\s*\n?([\s\S]*?)```/);
    if (jsonMatch) {
        try {
            const parsed = JSON.parse(jsonMatch[1]);
            if (parsed.html !== undefined) html = parsed.html;
            if (parsed.css !== undefined) css = parsed.css;
            // Remove the JSON block from explanation
            explanation = response.replace(/```json\s*\n?[\s\S]*?```/, '').trim();
        } catch (e) {
            console.warn('Failed to parse JSON from response:', e);
        }
    }

    // If no JSON block, try to extract separate html/css code blocks
    if (html === undefined && css === undefined) {
        const htmlMatch = response.match(/```html\s*\n?([\s\S]*?)```/);
        const cssMatch = response.match(/```css\s*\n?([\s\S]*?)```/);
        if (htmlMatch) {
            html = htmlMatch[1].trim();
            explanation = explanation.replace(/```html\s*\n?[\s\S]*?```/, '').trim();
        }
        if (cssMatch) {
            css = cssMatch[1].trim();
            explanation = explanation.replace(/```css\s*\n?[\s\S]*?```/, '').trim();
        }
    }

    return { explanation, html, css };
}

// Global function for apply button
window.applyChanges = function (btn) {
    const html = btn.dataset.html ? decodeURIComponent(btn.dataset.html) : null;
    const css = btn.dataset.css ? decodeURIComponent(btn.dataset.css) : null;

    if (html) editorHtml.value = html;
    if (css) editorCss.value = css;

    renderPreview();
    showToast('변경사항이 적용되었습니다!', 'success');

    // Visual feedback
    btn.textContent = '✅ 적용됨';
    btn.disabled = true;
    btn.style.opacity = '0.6';
};

// ============================================================
// LLM API CALLS (Client-side)
// ============================================================

async function callLLM(messages) {
    const s = state.settings;
    const provider = s.provider;

    switch (provider) {
        case 'gemini':
            return s.geminiSubProvider === 'vertex'
                ? callVertexAI(messages)
                : callGeminiAIStudio(messages);
        case 'claude':
            return callClaude(messages);
        case 'openai':
            return callOpenAI(messages);
        case 'custom':
            return callCustomAPI(messages);
        default:
            throw new Error('알 수 없는 프로바이더입니다.');
    }
}

// --- Gemini AI Studio ---
async function callGeminiAIStudio(messages) {
    const s = state.settings;
    const model = s.model || 'gemini-2.0-flash';
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${s.apiKey}`;

    // Convert messages to Gemini format
    const systemInstruction = messages.find(m => m.role === 'system')?.content || '';
    const contents = messages
        .filter(m => m.role !== 'system')
        .map(m => {
            const parts = [{ text: m.content }];
            // Add attachments as inline data
            if (m.attachments && m.attachments.length > 0) {
                for (const att of m.attachments) {
                    if (att.type.startsWith('image/') || att.type === 'application/pdf') {
                        parts.push({
                            inline_data: {
                                mime_type: att.type,
                                data: att.base64,
                            }
                        });
                    } else {
                        // Text files: decode and include as text
                        try {
                            const decoded = atob(att.base64);
                            parts[0].text += `\n\n[첨부: ${att.name}]\n${decoded}`;
                        } catch { /* skip */ }
                    }
                }
            }
            return {
                role: m.role === 'user' ? 'user' : 'model',
                parts,
            };
        });

    const body = {
        systemInstruction: { parts: [{ text: systemInstruction }] },
        contents,
        generationConfig: {
            temperature: s.temperature,
            maxOutputTokens: 65000,
        },
    };

    // Add Gemini tools
    const tools = [];
    if (s.geminiCodeExecution) {
        tools.push({ code_execution: {} });
    }
    if (s.geminiGrounding) {
        tools.push({ google_search: {} });
    }
    if (s.geminiUrlContext) {
        tools.push({ url_context: {} });
    }
    if (tools.length > 0) {
        body.tools = tools;
    }

    const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    });

    if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error?.message || `Gemini API 오류 (${res.status})`);
    }

    const data = await res.json();
    return data.candidates?.[0]?.content?.parts?.[0]?.text || '응답을 받지 못했습니다.';
}

// --- Vertex AI ---
async function callVertexAI(messages) {
    // Note: Vertex AI requires OAuth2 tokens which need server-side JWT signing.
    // For pure client-side, we'd need to use the API key approach or implement
    // JWT signing in the browser using the private key.
    // This implementation uses a simplified approach with direct API key if available.
    throw new Error(
        'Vertex AI는 OAuth2 인증이 필요하여 순수 클라이언트 사이드에서 직접 호출이 어렵습니다. ' +
        'Google AI Studio 프로바이더를 사용하시거나, 프록시 서버를 구성해주세요.'
    );
}

// --- Claude ---
async function callClaude(messages) {
    const s = state.settings;
    const model = s.model || 'claude-sonnet-4-20250514';

    const systemContent = messages.find(m => m.role === 'system')?.content || '';
    const apiMessages = messages
        .filter(m => m.role !== 'system')
        .map(m => {
            const role = m.role === 'user' ? 'user' : 'assistant';
            // Build content with possible attachments
            if (m.attachments && m.attachments.length > 0) {
                const contentParts = [];
                for (const att of m.attachments) {
                    if (att.type.startsWith('image/')) {
                        contentParts.push({
                            type: 'image',
                            source: {
                                type: 'base64',
                                media_type: att.type,
                                data: att.base64,
                            }
                        });
                    } else {
                        try {
                            const decoded = atob(att.base64);
                            contentParts.push({ type: 'text', text: `[첨부: ${att.name}]\n${decoded}` });
                        } catch { /* skip */ }
                    }
                }
                contentParts.push({ type: 'text', text: m.content });
                return { role, content: contentParts };
            }
            return { role, content: m.content };
        });

    const body = {
        model,
        max_tokens: 8192,
        temperature: s.temperature,
        system: systemContent,
        messages: apiMessages,
    };

    // Claude API requires server-side proxy due to CORS
    // Try direct call first (works if user has a proxy set up)
    const res = await fetch('https://api.anthropic.com/v1/messages', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'x-api-key': s.apiKey,
            'anthropic-version': '2023-06-01',
            'anthropic-dangerous-direct-browser-access': 'true',
        },
        body: JSON.stringify(body),
    });

    if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error?.message || `Claude API 오류 (${res.status})`);
    }

    const data = await res.json();
    return data.content?.[0]?.text || '응답을 받지 못했습니다.';
}

// --- OpenAI ---
async function callOpenAI(messages) {
    const s = state.settings;
    const model = s.model || 'gpt-4.1';

    const body = {
        model,
        temperature: s.temperature,
        max_tokens: 8192,
        messages: messages.map(m => {
            // Build content with possible attachments
            if (m.attachments && m.attachments.length > 0) {
                const contentParts = [];
                for (const att of m.attachments) {
                    if (att.type.startsWith('image/')) {
                        contentParts.push({
                            type: 'image_url',
                            image_url: { url: `data:${att.type};base64,${att.base64}` }
                        });
                    } else {
                        try {
                            const decoded = atob(att.base64);
                            contentParts.push({ type: 'text', text: `[첨부: ${att.name}]\n${decoded}` });
                        } catch { /* skip */ }
                    }
                }
                contentParts.push({ type: 'text', text: m.content });
                return { role: m.role, content: contentParts };
            }
            return { role: m.role, content: m.content };
        }),
    };

    const res = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${s.apiKey}`,
        },
        body: JSON.stringify(body),
    });

    if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error?.message || `OpenAI API 오류 (${res.status})`);
    }

    const data = await res.json();
    return data.choices?.[0]?.message?.content || '응답을 받지 못했습니다.';
}

// --- Custom API (OpenAI Compatible) ---
async function callCustomAPI(messages) {
    const s = state.settings;

    const body = {
        model: s.customModelId || 'default',
        temperature: s.temperature,
        max_tokens: 8192,
        messages: messages.map(m => {
            if (m.attachments && m.attachments.length > 0) {
                const contentParts = [];
                for (const att of m.attachments) {
                    if (att.type.startsWith('image/')) {
                        contentParts.push({
                            type: 'image_url',
                            image_url: { url: `data:${att.type};base64,${att.base64}` }
                        });
                    } else {
                        try {
                            const decoded = atob(att.base64);
                            contentParts.push({ type: 'text', text: `[첨부: ${att.name}]\n${decoded}` });
                        } catch { /* skip */ }
                    }
                }
                contentParts.push({ type: 'text', text: m.content });
                return { role: m.role, content: contentParts };
            }
            return { role: m.role, content: m.content };
        }),
    };

    const headers = {
        'Content-Type': 'application/json',
    };
    if (s.apiKey) {
        headers['Authorization'] = `Bearer ${s.apiKey}`;
    }

    const res = await fetch(s.customApiUrl, {
        method: 'POST',
        headers,
        body: JSON.stringify(body),
    });

    if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error?.message || `Custom API 오류 (${res.status})`);
    }

    const data = await res.json();
    return data.choices?.[0]?.message?.content || '응답을 받지 못했습니다.';
}

// ============================================================
// CHAT SESSION MANAGEMENT
// ============================================================
function saveCurrentSession() {
    // Don't save empty sessions
    if (state.chatMessages.length === 0) return;

    const firstUserMsg = state.chatMessages.find(m => m.role === 'user');
    const title = firstUserMsg
        ? firstUserMsg.content.substring(0, 50) + (firstUserMsg.content.length > 50 ? '...' : '')
        : '새 대화';

    if (state.currentSessionId) {
        // Update existing session
        const idx = state.chatSessions.findIndex(s => s.id === state.currentSessionId);
        if (idx !== -1) {
            state.chatSessions[idx].messages = [...state.chatMessages];
            state.chatSessions[idx].title = title;
            state.chatSessions[idx].updatedAt = Date.now();
        }
    } else {
        // Create new session
        const session = {
            id: Date.now(),
            title,
            messages: [...state.chatMessages],
            createdAt: Date.now(),
            updatedAt: Date.now(),
        };
        state.chatSessions.unshift(session);
        state.currentSessionId = session.id;
    }

    // Keep max 30 sessions
    if (state.chatSessions.length > 30) {
        state.chatSessions = state.chatSessions.slice(0, 30);
    }
    saveChatSessions();
}

function startNewChat() {
    // Save current chat first
    saveCurrentSession();

    // Clear chat
    state.chatMessages = [];
    state.currentSessionId = null;
    chatMessages.innerHTML = `
        <div class="chat-welcome">
            <div class="welcome-icon">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                    <path d="M12 2L2 7l10 5 10-5-10-5z"/>
                    <path d="M2 17l10 5 10-5"/>
                    <path d="M2 12l10 5 10-5"/>
                </svg>
            </div>
            <h2>RisuAI Theme Studio</h2>
            <p>테마를 만들어 볼까요? 원하는 디자인을 설명해주세요.</p>
            <div class="welcome-suggestions">
                <button class="suggestion-chip" data-suggestion="트위터(X) 스타일의 테마를 만들어줘">🐦 트위터 스타일</button>
                <button class="suggestion-chip" data-suggestion="디스코드 스타일의 테마를 만들어줘">💬 디스코드 스타일</button>
                <button class="suggestion-chip" data-suggestion="카카오톡 스타일의 테마를 만들어줘">💛 카카오톡 스타일</button>
                <button class="suggestion-chip" data-suggestion="iMessage 스타일의 테마를 만들어줘">📱 iMessage 스타일</button>
            </div>
        </div>`;

    // Re-attach suggestion chip listeners
    chatMessages.querySelectorAll('.suggestion-chip').forEach(chip => {
        chip.addEventListener('click', () => {
            chatInput.value = chip.dataset.suggestion;
            sendMessage();
        });
    });

    showToast('새 대화를 시작합니다.', 'success');
}

function loadSession(sessionId) {
    // Save current first
    saveCurrentSession();

    const session = state.chatSessions.find(s => s.id === sessionId);
    if (!session) return;

    state.currentSessionId = session.id;
    state.chatMessages = [...session.messages];

    // Rebuild chat UI
    chatMessages.innerHTML = '';
    for (const msg of state.chatMessages) {
        if (msg.role === 'user') {
            addChatMessage('user', msg.content);
        } else {
            const { explanation, html, css } = parseAssistantResponse(msg.content);
            addChatMessage('assistant', explanation, html, css);
        }
    }

    closeModal('chat-sessions-modal');
    showToast('대화를 불러왔습니다.', 'success');
}

function deleteSession(sessionId) {
    state.chatSessions = state.chatSessions.filter(s => s.id !== sessionId);
    if (state.currentSessionId === sessionId) {
        state.currentSessionId = null;
    }
    saveChatSessions();
    renderChatSessionsList();
}

function renderChatSessionsList() {
    const list = $('#chat-sessions-list');
    if (state.chatSessions.length === 0) {
        list.innerHTML = '<p class="history-empty">저장된 대화가 없습니다.</p>';
        return;
    }

    list.innerHTML = state.chatSessions.map(session => {
        const date = new Date(session.updatedAt).toLocaleString('ko-KR', {
            month: '2-digit', day: '2-digit', hour: '2-digit', minute: '2-digit'
        });
        const msgCount = session.messages.length;
        const isActive = session.id === state.currentSessionId;
        return `
            <div class="session-item${isActive ? ' active-session' : ''}" data-session-id="${session.id}">
                <div class="session-item-info">
                    <div class="session-item-title">${escapeHtml(session.title)}</div>
                    <div class="session-item-meta">
                        <span>${date}</span>
                        <span>${msgCount}개 메시지</span>
                    </div>
                </div>
                <button class="session-item-delete" data-delete-session="${session.id}" title="삭제">&times;</button>
            </div>`;
    }).join('');

    // Click to load
    list.querySelectorAll('.session-item').forEach(item => {
        item.addEventListener('click', (e) => {
            if (e.target.closest('.session-item-delete')) return;
            loadSession(parseInt(item.dataset.sessionId));
        });
    });

    // Delete
    list.querySelectorAll('.session-item-delete').forEach(btn => {
        btn.addEventListener('click', (e) => {
            e.stopPropagation();
            deleteSession(parseInt(btn.dataset.deleteSession));
        });
    });
}

// ============================================================
// KEYBOARD SHORTCUTS
// ============================================================
document.addEventListener('keydown', (e) => {
    // Escape to close modals
    if (e.key === 'Escape') {
        $$('.modal-overlay:not(.hidden)').forEach(m => m.classList.add('hidden'));
    }
});

// ============================================================
// WORKSPACE MANAGEMENT
// ============================================================

// New workspace — reset everything
$('#btn-new-workspace').addEventListener('click', () => {
    if (!confirm('새 작업을 시작하시겠습니까?\n현재 편집 중인 HTML/CSS와 채팅 기록이 초기화됩니다.')) return;

    editorHtml.value = DEFAULT_HTML;
    editorCss.value = DEFAULT_CSS;
    localStorage.setItem('risu-studio-html', DEFAULT_HTML);
    localStorage.setItem('risu-studio-css', DEFAULT_CSS);

    // Reset chat
    state.chatMessages = [];
    state.currentSessionId = null;
    chatMessages.innerHTML = `
        <div class="chat-welcome">
            <div class="welcome-icon">
                <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                    <path d="M12 2L2 7l10 5 10-5-10-5z" />
                    <path d="M2 17l10 5 10-5" />
                    <path d="M2 12l10 5 10-5" />
                </svg>
            </div>
            <h2>RisuAI Theme Studio</h2>
            <p>테마를 만들어 볼까요? 원하는 디자인을 설명해주세요.</p>
            <div class="welcome-suggestions">
                <button class="suggestion-chip" data-suggestion="트위터(X) 스타일의 테마를 만들어줘">🐦 트위터 스타일</button>
                <button class="suggestion-chip" data-suggestion="디스코드 스타일의 테마를 만들어줘">💬 디스코드 스타일</button>
                <button class="suggestion-chip" data-suggestion="카카오톡 스타일의 테마를 만들어줘">💛 카카오톡 스타일</button>
                <button class="suggestion-chip" data-suggestion="iMessage 스타일의 테마를 만들어줘">📱 iMessage 스타일</button>
            </div>
        </div>`;
    // Re-bind suggestion chips
    $$('.suggestion-chip').forEach(chip => {
        chip.addEventListener('click', () => {
            chatInput.value = chip.dataset.suggestion;
            sendMessage();
        });
    });

    renderPreview();
    showToast('새 작업이 시작되었습니다.', 'success');
});

// Export workspace as JSON
$('#btn-export-workspace').addEventListener('click', () => {
    const workspace = {
        version: 1,
        exportedAt: new Date().toISOString(),
        html: editorHtml.value,
        css: editorCss.value,
        chatMessages: state.chatMessages.map(m => ({
            role: m.role,
            content: m.content,
            // Exclude base64 attachments to keep file size small
        })),
    };

    const blob = new Blob([JSON.stringify(workspace, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
    a.href = url;
    a.download = `risu-theme-${timestamp}.json`;
    a.click();
    URL.revokeObjectURL(url);
    showToast('작업을 JSON으로 내보냈습니다.', 'success');
});

// Import workspace from JSON
const workspaceImportInput = $('#workspace-import-input');
$('#btn-import-workspace').addEventListener('click', () => workspaceImportInput.click());

workspaceImportInput.addEventListener('change', () => {
    const file = workspaceImportInput.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = () => {
        try {
            const workspace = JSON.parse(reader.result);
            if (!workspace.html && !workspace.css) {
                throw new Error('유효한 작업 파일이 아닙니다.');
            }

            if (!confirm('가져온 작업으로 현재 편집 내용을 덮어쓰시겠습니까?')) return;

            // Load HTML/CSS
            editorHtml.value = workspace.html || '';
            editorCss.value = workspace.css || '';
            localStorage.setItem('risu-studio-html', editorHtml.value);
            localStorage.setItem('risu-studio-css', editorCss.value);

            // Load chat messages
            if (workspace.chatMessages && workspace.chatMessages.length > 0) {
                state.chatMessages = workspace.chatMessages;
                state.currentSessionId = null;

                // Rebuild chat UI
                chatMessages.innerHTML = '';
                for (const msg of state.chatMessages) {
                    if (msg.role === 'user') {
                        addChatMessage('user', msg.content);
                    } else {
                        const { explanation, html, css } = parseAssistantResponse(msg.content);
                        addChatMessage('assistant', explanation, html, css);
                    }
                }
            } else {
                state.chatMessages = [];
                chatMessages.innerHTML = '<div class="chat-welcome"><p>채팅 기록이 없는 작업 파일입니다.</p></div>';
            }

            renderPreview();
            showToast(`"${file.name}" 작업을 불러왔습니다.`, 'success');
        } catch (err) {
            showToast(`파일 읽기 오류: ${err.message}`, 'error');
        }
    };
    reader.readAsText(file);
    workspaceImportInput.value = '';
});

// ============================================================
// INIT
// ============================================================
function init() {
    // Load saved editor content, or use default theme
    const savedHtml = localStorage.getItem('risu-studio-html');
    const savedCss = localStorage.getItem('risu-studio-css');

    // Use default Apple theme if no saved or empty content exists
    if (!savedHtml && !savedCss) {
        editorHtml.value = DEFAULT_HTML;
        editorCss.value = DEFAULT_CSS;
    } else {
        editorHtml.value = savedHtml || '';
        editorCss.value = savedCss || '';
    }

    // Auto-save editor content
    editorHtml.addEventListener('input', () => {
        localStorage.setItem('risu-studio-html', editorHtml.value);
    });
    editorCss.addEventListener('input', () => {
        localStorage.setItem('risu-studio-css', editorCss.value);
    });

    renderPreview();
}

init();
