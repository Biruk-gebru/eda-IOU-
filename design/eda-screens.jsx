// EDA home-screen variants. All share editorial brutalist DNA inspired by the
// reference layout: warm paper background, hairline ink borders, no radii,
// stacked label/value rhythm, a single ochre accent. They differ in what they
// emphasize — balance, people, activity, or the act of starting a new entry.

const edaStyles = {
  // ---- shells ----
  screen: (paper, ink) => ({
    width: '100%',
    height: '100%',
    background: paper,
    color: ink,
    fontFamily: EDA.text,
    overflow: 'hidden',
    display: 'flex',
    flexDirection: 'column',
    position: 'relative',
  }),
  scroll: { flex: 1, overflowY: 'auto', overflowX: 'hidden' },

  // ---- header ----
  header: { display: 'flex', alignItems: 'center', gap: 12, padding: '20px 22px 14px' },
  avatar: (ink) => ({
    width: 36, height: 36, border: `1.5px solid ${ink}`,
    background: 'transparent', display: 'flex', alignItems: 'center',
    justifyContent: 'center', fontFamily: EDA.display, fontWeight: 600, fontSize: 13,
  }),
  greet: { fontSize: 11, fontWeight: 500, color: EDA.mute, letterSpacing: '0.04em', textTransform: 'uppercase' },
  name: { fontFamily: EDA.display, fontSize: 18, fontWeight: 600, lineHeight: 1.1, marginTop: 2 },

  bell: (ink) => ({
    width: 36, height: 36, border: `1.5px solid ${ink}`, background: 'transparent',
    display: 'grid', placeItems: 'center', cursor: 'pointer', position: 'relative',
  }),
  bellDot: (color) => ({ position: 'absolute', top: 6, right: 6, width: 7, height: 7, background: color, borderRadius: '50%' }),
};

// ── Tiny SVG glyphs (no emoji, no library) ──────────────────────────────────
const Glyph = {
  bell: (c='currentColor') => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6">
      <path d="M6 8a6 6 0 0 1 12 0c0 4 1.5 5.5 2 6.5H4c.5-1 2-2.5 2-6.5z"/>
      <path d="M10 19a2 2 0 0 0 4 0"/>
    </svg>
  ),
  plus: (c='currentColor') => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="2">
      <path d="M12 5v14M5 12h14"/>
    </svg>
  ),
  arrowUp: (c='currentColor') => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8">
      <path d="M7 17 17 7M9 7h8v8"/>
    </svg>
  ),
  arrowDown: (c='currentColor') => (
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8">
      <path d="M17 7 7 17M15 17H7V9"/>
    </svg>
  ),
  send: (c='currentColor') => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6">
      <path d="M3 12 21 4l-4 17-5-7-9-2z"/><path d="m12 14 5-9"/>
    </svg>
  ),
  receipt: (c='currentColor') => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6">
      <path d="M5 3h14v18l-3-2-3 2-3-2-3 2-2-1z"/><path d="M9 8h6M9 12h6M9 16h4"/>
    </svg>
  ),
  scan: (c='currentColor') => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6">
      <path d="M4 8V5a1 1 0 0 1 1-1h3M16 4h3a1 1 0 0 1 1 1v3M20 16v3a1 1 0 0 1-1 1h-3M8 20H5a1 1 0 0 1-1-1v-3"/>
      <path d="M4 12h16"/>
    </svg>
  ),
  group: (c='currentColor') => (
    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.6">
      <circle cx="9" cy="9" r="3"/><circle cx="17" cy="11" r="2.2"/>
      <path d="M3 19c.6-3 3-5 6-5s5.4 2 6 5M14.5 18c.5-2.5 2-4 3.5-4s2.5 1 3 3"/>
    </svg>
  ),
  chev: (c='currentColor') => (
    <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke={c} strokeWidth="1.8"><path d="m9 6 6 6-6 6"/></svg>
  ),
  dot: (c='currentColor') => (
    <svg width="6" height="6" viewBox="0 0 6 6"><circle cx="3" cy="3" r="3" fill={c}/></svg>
  ),
  spark: (c='currentColor') => (
    <svg width="68" height="22" viewBox="0 0 68 22" fill="none" stroke={c} strokeWidth="1.4">
      <path d="M2 16 9 11 14 14 22 6 28 9 36 4 44 12 52 7 60 13 66 9"/>
    </svg>
  ),
};

// ── Header (shared) ─────────────────────────────────────────────────────────
function ScreenHeader({ accent }) {
  return (
    <div style={edaStyles.header}>
      <div style={edaStyles.avatar(EDA.ink)}>{USER.initial}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={edaStyles.greet}>{USER.greeting}</div>
        <div style={edaStyles.name}>{USER.name}</div>
      </div>
      <button style={edaStyles.bell(EDA.ink)} aria-label="notifications">
        {Glyph.bell(EDA.ink)}
        <span style={edaStyles.bellDot(accent.fill)} />
      </button>
    </div>
  );
}

// ── Variant A — "Ledger" ────────────────────────────────────────────────────
// Editorial primary. Hero balance as a black slab with stacked label/value
// pairs (mirroring the reference's left-aligned label-on-top rhythm).
// 3-up tile row of primary actions. Transactions as bordered rectangles with
// right-aligned date and signed amount, no chevrons. Ochre CTA pinned bottom.
function HomeLedger({ accent }) {
  return (
    <div style={edaStyles.screen(EDA.paper, EDA.ink)}>
      <ScreenHeader accent={accent} />

      <div style={edaStyles.scroll}>
        {/* Hero slab */}
        <div style={{ margin: '6px 22px 0', border: `1.5px solid ${EDA.ink}`, background: EDA.ink, color: EDA.paper, padding: 22, position: 'relative' }}>
          <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.16em', textTransform: 'uppercase', color: '#A8A294' }}>Net balance · April</div>
          <div style={{ fontFamily: EDA.display, fontWeight: 600, fontSize: 44, lineHeight: 1, marginTop: 10, letterSpacing: '-0.02em' }}>
            {fmtSigned(BALANCE.net)}
          </div>
          <div style={{ display: 'flex', marginTop: 22, gap: 18 }}>
            <div style={{ flex: 1, borderTop: `1px solid #3a3528`, paddingTop: 10 }}>
              <div style={{ fontSize: 10, letterSpacing: '0.12em', textTransform: 'uppercase', color: '#A8A294' }}>You owe</div>
              <div style={{ fontFamily: EDA.display, fontSize: 22, fontWeight: 500, marginTop: 4 }}>{fmt(BALANCE.youOwe)}</div>
            </div>
            <div style={{ width: 1, background: '#3a3528' }} />
            <div style={{ flex: 1, borderTop: `1px solid #3a3528`, paddingTop: 10 }}>
              <div style={{ fontSize: 10, letterSpacing: '0.12em', textTransform: 'uppercase', color: '#A8A294' }}>Owed to you</div>
              <div style={{ fontFamily: EDA.display, fontSize: 22, fontWeight: 500, marginTop: 4 }}>{fmt(BALANCE.owedToYou)}</div>
            </div>
          </div>
          <div style={{ position: 'absolute', top: 14, right: 14, display: 'flex', gap: 4 }}>
            {Glyph.spark(accent.fill)}
          </div>
        </div>

        {/* Action tiles */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10, padding: '14px 22px 0' }}>
          {[
            { icon: Glyph.plus(EDA.ink),    label: 'New IOU',  fill: accent.fill, sub: 'Split or charge' },
            { icon: Glyph.send(EDA.ink),    label: 'Request',  fill: EDA.card,    sub: 'Ask to pay' },
            { icon: Glyph.scan(EDA.ink),    label: 'Scan',     fill: EDA.card,    sub: 'QR receipt' },
          ].map((t, i) => (
            <button key={i} style={{ aspectRatio: '1', border: `1.5px solid ${EDA.ink}`, background: t.fill, padding: 12, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', textAlign: 'left', cursor: 'pointer' }}>
              {t.icon}
              <div>
                <div style={{ fontFamily: EDA.display, fontSize: 15, fontWeight: 600 }}>{t.label}</div>
                <div style={{ fontSize: 10, color: EDA.inkSoft, marginTop: 2 }}>{t.sub}</div>
              </div>
            </button>
          ))}
        </div>

        {/* Section header */}
        <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', padding: '24px 22px 10px' }}>
          <div style={{ fontFamily: EDA.display, fontSize: 22, fontWeight: 600 }}>Recent activity</div>
          <button style={{ border: 'none', background: 'none', fontSize: 11, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', cursor: 'pointer', color: EDA.ink, textDecoration: 'underline', textUnderlineOffset: 4 }}>See all</button>
        </div>

        {/* Txn list — bordered rectangles, no radius */}
        <div style={{ padding: '0 22px 100px', display: 'flex', flexDirection: 'column', gap: 8 }}>
          {TXNS.slice(0, 5).map(t => (
            <div key={t.id} style={{ border: `1.5px solid ${EDA.ink}`, background: EDA.card, padding: '14px 16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 12 }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontFamily: EDA.display, fontSize: 16, fontWeight: 600, lineHeight: 1.25 }}>{t.title}</div>
                  <div style={{ fontSize: 11, color: EDA.mute, marginTop: 4, fontFamily: EDA.mono, letterSpacing: '-0.01em' }}>
                    {t.who}{t.group ? ` · ${t.group}` : ''}
                  </div>
                </div>
                <div style={{ textAlign: 'right', flexShrink: 0 }}>
                  <div style={{ fontFamily: EDA.display, fontWeight: 600, fontSize: 16, color: t.amount >= 0 ? EDA.good : EDA.ink }}>
                    {fmtSigned(t.amount)}
                  </div>
                  <div style={{ fontSize: 10, color: EDA.mute, marginTop: 4, letterSpacing: '0.04em', textTransform: 'uppercase' }}>{t.when}</div>
                </div>
              </div>
              {t.status === 'pending' && (
                <div style={{ marginTop: 10, paddingTop: 10, borderTop: `1px dashed ${EDA.ink}`, display: 'flex', alignItems: 'center', gap: 6, fontSize: 10, fontWeight: 600, letterSpacing: '0.1em', textTransform: 'uppercase' }}>
                  {Glyph.dot(accent.fill)} Awaiting your approval
                </div>
              )}
            </div>
          ))}
        </div>
      </div>

      {/* Pinned CTA */}
      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, padding: '12px 22px 20px', background: `linear-gradient(to top, ${EDA.paper} 60%, transparent)` }}>
        <button style={{ width: '100%', border: `1.5px solid ${EDA.ink}`, background: accent.fill, color: EDA.ink, padding: '16px', fontFamily: EDA.display, fontSize: 16, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, boxShadow: `4px 4px 0 ${EDA.ink}` }}>
          {Glyph.plus(EDA.ink)} Start a new IOU
        </button>
      </div>
    </div>
  );
}

// ── Variant B — "People-first" ──────────────────────────────────────────────
// Reorders the rhythm: balance compressed to a single line, then a horizontal
// scroll of person-cards (the people you owe/are owed by, ranked). Activity
// becomes a dense table-like list with monospace columns. For users who think
// "who owes me?" before "what did I spend?".
function HomePeople({ accent }) {
  const sorted = [...PEOPLE].sort((a, b) => Math.abs(b.net) - Math.abs(a.net));
  return (
    <div style={edaStyles.screen(EDA.paper, EDA.ink)}>
      <ScreenHeader accent={accent} />

      <div style={edaStyles.scroll}>
        {/* One-line balance */}
        <div style={{ padding: '6px 22px 18px' }}>
          <div style={{ fontSize: 10, fontWeight: 600, letterSpacing: '0.16em', textTransform: 'uppercase', color: EDA.mute }}>Your net position</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 12, marginTop: 6 }}>
            <div style={{ fontFamily: EDA.display, fontSize: 52, fontWeight: 600, lineHeight: 1, letterSpacing: '-0.03em', color: BALANCE.net >= 0 ? EDA.good : EDA.bad }}>
              {fmtSigned(BALANCE.net)}
            </div>
          </div>
          <div style={{ marginTop: 10, fontSize: 12, color: EDA.inkSoft, fontFamily: EDA.mono }}>
            owe {fmt(BALANCE.youOwe)} · owed {fmt(BALANCE.owedToYou)}
          </div>
        </div>

        {/* People row */}
        <div style={{ padding: '0 22px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <div style={{ fontFamily: EDA.display, fontSize: 18, fontWeight: 600 }}>People</div>
          <span style={{ fontSize: 11, color: EDA.mute, fontFamily: EDA.mono }}>{PEOPLE.length} active</span>
        </div>
        <div style={{ display: 'flex', gap: 10, padding: '12px 22px 4px', overflowX: 'auto' }}>
          {sorted.map(p => {
            const positive = p.net >= 0;
            return (
              <div key={p.name} style={{ minWidth: 150, border: `1.5px solid ${EDA.ink}`, background: positive ? accent.fill : EDA.card, padding: 14, display: 'flex', flexDirection: 'column', gap: 12 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ width: 32, height: 32, border: `1.2px solid ${EDA.ink}`, background: EDA.paper, display: 'grid', placeItems: 'center', fontFamily: EDA.display, fontSize: 12, fontWeight: 600 }}>{p.initial}</div>
                  <span style={{ fontSize: 9, fontWeight: 600, letterSpacing: '0.12em', textTransform: 'uppercase' }}>{positive ? 'owes you' : 'you owe'}</span>
                </div>
                <div>
                  <div style={{ fontFamily: EDA.display, fontSize: 20, fontWeight: 600, lineHeight: 1.1 }}>{p.name.split(' ')[0]}</div>
                  <div style={{ fontFamily: EDA.display, fontSize: 22, fontWeight: 500, marginTop: 8 }}>{fmt(Math.abs(p.net))}</div>
                  <div style={{ fontSize: 10, color: EDA.inkSoft, marginTop: 2, fontFamily: EDA.mono }}>{p.txns} txns</div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Groups strip */}
        <div style={{ padding: '20px 22px 8px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between' }}>
          <div style={{ fontFamily: EDA.display, fontSize: 18, fontWeight: 600 }}>Groups</div>
        </div>
        <div style={{ padding: '0 22px', display: 'flex', flexDirection: 'column', borderTop: `1.5px solid ${EDA.ink}`, borderBottom: `1.5px solid ${EDA.ink}` }}>
          {GROUPS.map((g, i) => (
            <div key={g.name} style={{ display: 'grid', gridTemplateColumns: '1fr auto auto', alignItems: 'center', gap: 14, padding: '12px 0', borderTop: i === 0 ? 'none' : `1px solid ${EDA.ink}` }}>
              <div>
                <div style={{ fontFamily: EDA.display, fontSize: 15, fontWeight: 600 }}>{g.name}</div>
                <div style={{ fontSize: 11, color: EDA.mute, fontFamily: EDA.mono, marginTop: 2 }}>{g.members} members</div>
              </div>
              <div style={{ fontFamily: EDA.display, fontWeight: 600, fontSize: 15, color: g.net >= 0 ? EDA.good : EDA.bad }}>{fmtSigned(g.net)}</div>
              {Glyph.chev(EDA.ink)}
            </div>
          ))}
        </div>

        {/* Activity table */}
        <div style={{ padding: '20px 22px 8px' }}>
          <div style={{ fontFamily: EDA.display, fontSize: 18, fontWeight: 600 }}>Latest</div>
        </div>
        <div style={{ padding: '0 22px 100px' }}>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', fontSize: 10, color: EDA.mute, padding: '6px 0', borderBottom: `1.5px solid ${EDA.ink}`, letterSpacing: '0.12em', textTransform: 'uppercase', fontFamily: EDA.mono }}>
            <span>Description</span><span>Amount</span>
          </div>
          {TXNS.slice(0, 6).map((t, i) => (
            <div key={t.id} style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 14, padding: '12px 0', borderBottom: `1px solid ${EDA.ink}` }}>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontSize: 14, fontWeight: 500, lineHeight: 1.2 }}>{t.title}</div>
                <div style={{ fontSize: 10, color: EDA.mute, marginTop: 3, fontFamily: EDA.mono, letterSpacing: '-0.01em' }}>{t.who} · {t.when}</div>
              </div>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontFamily: EDA.mono, fontSize: 14, fontWeight: 500, color: t.amount >= 0 ? EDA.good : EDA.ink }}>{fmtSigned(t.amount)}</div>
                {t.status === 'pending' && <div style={{ fontSize: 9, color: accent.deep, fontWeight: 700, letterSpacing: '0.1em', textTransform: 'uppercase', marginTop: 3 }}>Pending</div>}
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, padding: '12px 22px 20px', background: `linear-gradient(to top, ${EDA.paper} 60%, transparent)` }}>
        <button style={{ width: '100%', border: `1.5px solid ${EDA.ink}`, background: accent.fill, color: EDA.ink, padding: '16px', fontFamily: EDA.display, fontSize: 16, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10, boxShadow: `4px 4px 0 ${EDA.ink}` }}>
          {Glyph.plus(EDA.ink)} New IOU
        </button>
      </div>
    </div>
  );
}

// ── Variant C — "Receipt" ───────────────────────────────────────────────────
// Most editorial. Single column treats the home like a printed ledger: a
// large display number, a hand-set rule, monospace columns for the activity.
// Two outline action tiles, no hero color. Ochre reserved for the floating
// FAB pinned over the rule.
function HomeReceipt({ accent }) {
  return (
    <div style={edaStyles.screen(EDA.paper, EDA.ink)}>
      <ScreenHeader accent={accent} />

      <div style={edaStyles.scroll}>
        {/* Receipt-style numerator */}
        <div style={{ padding: '20px 22px 0' }}>
          <div style={{ fontSize: 10, letterSpacing: '0.16em', textTransform: 'uppercase', color: EDA.mute, fontFamily: EDA.mono }}>EDA · April 2026</div>
          <div style={{ fontFamily: EDA.display, fontSize: 14, fontWeight: 500, marginTop: 16, lineHeight: 1.4 }}>
            You are <span style={{ background: accent.fill, padding: '0 6px' }}>net positive</span> this month, with {PEOPLE.filter(p=>p.net>0).length} people owing you{' '}
            <span style={{ fontWeight: 700 }}>{fmt(BALANCE.owedToYou)}</span> and you owing {PEOPLE.filter(p=>p.net<0).length} others{' '}
            <span style={{ fontWeight: 700 }}>{fmt(BALANCE.youOwe)}</span>.
          </div>

          <div style={{ fontFamily: EDA.display, fontSize: 88, fontWeight: 600, lineHeight: 0.95, marginTop: 22, letterSpacing: '-0.04em' }}>
            {fmtSigned(BALANCE.net)}
          </div>
          <div style={{ fontSize: 11, color: EDA.mute, fontFamily: EDA.mono, marginTop: 6 }}>net · all-time</div>
        </div>

        {/* Receipt rule with ochre stamp */}
        <div style={{ position: 'relative', margin: '28px 0 18px' }}>
          <div style={{ height: 1.5, background: EDA.ink }} />
          <div style={{ position: 'absolute', top: -18, right: 22, transform: 'rotate(-6deg)', border: `1.5px solid ${EDA.ink}`, background: accent.fill, padding: '6px 12px', fontFamily: EDA.display, fontSize: 11, fontWeight: 700, letterSpacing: '0.12em', textTransform: 'uppercase' }}>
            12 settled · 3 pending
          </div>
        </div>

        {/* Two-action row, outlined */}
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 0, margin: '0 22px', border: `1.5px solid ${EDA.ink}` }}>
          <button style={{ borderRight: `1.5px solid ${EDA.ink}`, background: 'transparent', padding: 16, display: 'flex', alignItems: 'center', gap: 10, fontFamily: EDA.display, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>
            {Glyph.plus(EDA.ink)} New IOU
          </button>
          <button style={{ background: 'transparent', padding: 16, display: 'flex', alignItems: 'center', gap: 10, fontFamily: EDA.display, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>
            {Glyph.send(EDA.ink)} Request
          </button>
        </div>

        {/* Monospace ledger */}
        <div style={{ padding: '24px 22px 0' }}>
          <div style={{ fontFamily: EDA.display, fontSize: 18, fontWeight: 600, marginBottom: 12 }}>Recent</div>
        </div>
        <div style={{ padding: '0 22px 100px', fontFamily: EDA.mono, fontSize: 12 }}>
          {TXNS.slice(0, 6).map((t, i) => (
            <div key={t.id} style={{ display: 'grid', gridTemplateColumns: '54px 1fr auto', gap: 12, padding: '10px 0', borderTop: i === 0 ? 'none' : `1px dashed ${EDA.ink}`, alignItems: 'center' }}>
              <div style={{ color: EDA.mute, letterSpacing: '0.04em' }}>{t.when.split(',')[0].toUpperCase().slice(0, 6)}</div>
              <div style={{ minWidth: 0 }}>
                <div style={{ fontFamily: EDA.text, fontSize: 13, fontWeight: 500, lineHeight: 1.2 }}>{t.title}</div>
                <div style={{ fontSize: 10, color: EDA.mute, marginTop: 2 }}>{t.who}</div>
              </div>
              <div style={{ textAlign: 'right', fontSize: 13, fontWeight: 500, color: t.amount >= 0 ? EDA.good : EDA.ink }}>
                {t.amount >= 0 ? '+' : '−'}{Math.abs(t.amount).toLocaleString()}
              </div>
            </div>
          ))}
          <div style={{ borderTop: `1.5px solid ${EDA.ink}`, marginTop: 8, paddingTop: 10, display: 'flex', justifyContent: 'space-between', fontFamily: EDA.text, fontSize: 11, color: EDA.mute, letterSpacing: '0.08em', textTransform: 'uppercase' }}>
            <span>End of page</span>
            <span>p. 1 / 12</span>
          </div>
        </div>
      </div>

      {/* Floating square FAB */}
      <button style={{ position: 'absolute', right: 22, bottom: 24, width: 64, height: 64, border: `1.5px solid ${EDA.ink}`, background: accent.fill, cursor: 'pointer', display: 'grid', placeItems: 'center', boxShadow: `4px 4px 0 ${EDA.ink}` }}>
        {Glyph.plus(EDA.ink)}
      </button>
    </div>
  );
}

// ── Variant D — "Stacked" ───────────────────────────────────────────────────
// Closest in spirit to the reference's overall layout: header → big colored
// hero with stacked label/value and a small object on the right → 4-up icon
// tile row → bordered transaction list with right-aligned date → bottom
// pinned CTA. Uses ochre as the hero fill so the structural similarity reads,
// while the type, copywriting and details are distinctly editorial.
function HomeStacked({ accent }) {
  return (
    <div style={edaStyles.screen(EDA.paper, EDA.ink)}>
      <ScreenHeader accent={accent} />

      <div style={edaStyles.scroll}>
        {/* Hero — accent fill */}
        <div style={{ margin: '6px 22px 0', border: `1.5px solid ${EDA.ink}`, background: accent.fill, color: EDA.ink, padding: 22, position: 'relative' }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.18em', textTransform: 'uppercase' }}>Total balance</div>
          <div style={{ fontFamily: EDA.display, fontSize: 38, fontWeight: 700, lineHeight: 1, marginTop: 8, letterSpacing: '-0.02em' }}>
            {fmtSigned(BALANCE.net)}
          </div>

          <div style={{ marginTop: 22, fontSize: 10, fontWeight: 700, letterSpacing: '0.18em', textTransform: 'uppercase' }}>Active accounts</div>
          <div style={{ fontFamily: EDA.display, fontSize: 24, fontWeight: 600, lineHeight: 1, marginTop: 6, fontVariantNumeric: 'tabular-nums', letterSpacing: '0.04em' }}>
            04 · 12 · 03 · 27
          </div>

          {/* Geometric mark in corner — square, no faux-logo */}
          <div style={{ position: 'absolute', top: 16, right: 16, width: 36, height: 36, border: `1.5px solid ${EDA.ink}`, background: 'transparent', display: 'grid', placeItems: 'center' }}>
            <div style={{ width: 14, height: 14, background: EDA.ink }} />
          </div>
        </div>

        {/* 4-up tiles */}
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 8, padding: '12px 22px 0' }}>
          {[
            { icon: Glyph.plus(EDA.ink),    label: 'New' },
            { icon: Glyph.send(EDA.ink),    label: 'Request' },
            { icon: Glyph.group(EDA.ink),   label: 'Groups' },
            { icon: Glyph.scan(EDA.ink),    label: 'Scan' },
          ].map((t, i) => (
            <button key={i} style={{ aspectRatio: '1', border: `1.5px solid ${EDA.ink}`, background: i === 0 ? accent.fill : EDA.card, padding: 10, display: 'flex', flexDirection: 'column', justifyContent: 'space-between', textAlign: 'left', cursor: 'pointer' }}>
              {t.icon}
              <div style={{ fontFamily: EDA.display, fontSize: 12, fontWeight: 600 }}>{t.label}</div>
            </button>
          ))}
        </div>

        {/* List title */}
        <div style={{ padding: '22px 22px 10px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
          <div style={{ fontFamily: EDA.display, fontSize: 22, fontWeight: 600 }}>Transactions</div>
        </div>

        <div style={{ padding: '0 22px 100px', display: 'flex', flexDirection: 'column', gap: 8 }}>
          {TXNS.slice(0, 5).map(t => (
            <div key={t.id} style={{ border: `1.5px solid ${EDA.ink}`, background: EDA.card, padding: '14px 16px' }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 12 }}>
                <div style={{ minWidth: 0 }}>
                  <div style={{ fontSize: 14, fontWeight: 600 }}>{t.title}</div>
                  <div style={{ fontSize: 11, color: EDA.mute, marginTop: 6, lineHeight: 1.5 }}>
                    Start: {t.when}<br/>
                    {t.who}{t.group ? ` · ${t.group}` : ''}<br/>
                    Fair: {fmt(Math.abs(t.amount))}
                  </div>
                </div>
                <div style={{ fontSize: 11, color: EDA.mute, flexShrink: 0, fontVariantNumeric: 'tabular-nums' }}>{t.when.split(',')[0]}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, padding: '12px 22px 20px', background: `linear-gradient(to top, ${EDA.paper} 60%, transparent)` }}>
        <button style={{ width: '100%', border: `1.5px solid ${EDA.ink}`, background: accent.fill, color: EDA.ink, padding: '16px', fontFamily: EDA.display, fontSize: 16, fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}>
          Start a New IOU
        </button>
      </div>
    </div>
  );
}

// ── Companion screens ──────────────────────────────────────────────────────

// Transaction detail (timeline)
function TxnDetail({ accent }) {
  return (
    <div style={edaStyles.screen(EDA.paper, EDA.ink)}>
      <div style={{ padding: '20px 22px 16px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: `1.5px solid ${EDA.ink}` }}>
        <button style={{ width: 36, height: 36, border: `1.5px solid ${EDA.ink}`, background: 'transparent', display: 'grid', placeItems: 'center', cursor: 'pointer' }}>
          <span style={{ fontFamily: EDA.display, fontSize: 16, fontWeight: 600 }}>←</span>
        </button>
        <div style={{ flex: 1, fontFamily: EDA.display, fontSize: 14, fontWeight: 600 }}>Transaction</div>
        <div style={{ fontSize: 10, fontFamily: EDA.mono, color: EDA.mute }}>#A8E2-0421</div>
      </div>

      <div style={edaStyles.scroll}>
        <div style={{ padding: 22 }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.16em', textTransform: 'uppercase', color: EDA.mute }}>Pending approval</div>
          <div style={{ fontFamily: EDA.display, fontSize: 28, fontWeight: 600, lineHeight: 1.1, marginTop: 8, letterSpacing: '-0.01em' }}>Ride to Bole airport</div>
          <div style={{ fontFamily: EDA.display, fontSize: 44, fontWeight: 600, marginTop: 16, letterSpacing: '-0.02em' }}>{fmt(480)}</div>
          <div style={{ fontFamily: EDA.mono, fontSize: 11, color: EDA.mute, marginTop: 4 }}>paid by you · split equally · 2 people</div>
        </div>

        <div style={{ margin: '0 22px', border: `1.5px solid ${EDA.ink}`, background: EDA.card }}>
          {[
            { name: 'You', initial: 'EM', share: 240, status: 'Paid' },
            { name: 'Selam Tesfaye', initial: 'ST', share: 240, status: 'Owes you' },
          ].map((p, i) => (
            <div key={p.name} style={{ display: 'grid', gridTemplateColumns: 'auto 1fr auto', gap: 12, padding: 14, borderTop: i === 0 ? 'none' : `1px solid ${EDA.ink}`, alignItems: 'center' }}>
              <div style={{ width: 32, height: 32, border: `1.2px solid ${EDA.ink}`, display: 'grid', placeItems: 'center', fontFamily: EDA.display, fontSize: 12, fontWeight: 600 }}>{p.initial}</div>
              <div>
                <div style={{ fontFamily: EDA.display, fontSize: 14, fontWeight: 600 }}>{p.name}</div>
                <div style={{ fontSize: 11, color: EDA.mute, fontFamily: EDA.mono, marginTop: 2 }}>{p.status}</div>
              </div>
              <div style={{ fontFamily: EDA.display, fontSize: 16, fontWeight: 600 }}>{fmt(p.share)}</div>
            </div>
          ))}
        </div>

        <div style={{ padding: '24px 22px 12px', fontFamily: EDA.display, fontSize: 18, fontWeight: 600 }}>Timeline</div>
        <div style={{ padding: '0 22px 110px' }}>
          {[
            { t: 'Now',             label: 'Awaiting Selam',     dot: accent.fill },
            { t: 'Today, 09:14',    label: 'You paid · ETB 480',  dot: EDA.ink },
            { t: 'Today, 09:12',    label: 'IOU created',         dot: EDA.ink },
          ].map((e, i) => (
            <div key={i} style={{ display: 'grid', gridTemplateColumns: 'auto 1fr', gap: 14, padding: '12px 0', borderTop: i === 0 ? `1.5px solid ${EDA.ink}` : `1px dashed ${EDA.ink}`, alignItems: 'flex-start' }}>
              <div style={{ width: 10, height: 10, border: `1.2px solid ${EDA.ink}`, background: e.dot, marginTop: 6 }} />
              <div>
                <div style={{ fontFamily: EDA.mono, fontSize: 10, color: EDA.mute, letterSpacing: '0.06em', textTransform: 'uppercase' }}>{e.t}</div>
                <div style={{ fontSize: 14, fontWeight: 500, marginTop: 2 }}>{e.label}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, padding: '12px 22px 20px', background: EDA.paper, borderTop: `1.5px solid ${EDA.ink}`, display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        <button style={{ border: `1.5px solid ${EDA.ink}`, background: 'transparent', padding: 14, fontFamily: EDA.display, fontSize: 14, fontWeight: 600, cursor: 'pointer' }}>Decline</button>
        <button style={{ border: `1.5px solid ${EDA.ink}`, background: accent.fill, padding: 14, fontFamily: EDA.display, fontSize: 14, fontWeight: 600, cursor: 'pointer', boxShadow: `3px 3px 0 ${EDA.ink}` }}>Approve</button>
      </div>
    </div>
  );
}

// New IOU sheet
function NewIOU({ accent }) {
  return (
    <div style={edaStyles.screen(EDA.paper, EDA.ink)}>
      <div style={{ padding: '20px 22px 16px', display: 'flex', alignItems: 'center', gap: 12, borderBottom: `1.5px solid ${EDA.ink}` }}>
        <button style={{ width: 36, height: 36, border: `1.5px solid ${EDA.ink}`, background: 'transparent', display: 'grid', placeItems: 'center', cursor: 'pointer', fontFamily: EDA.display, fontSize: 16, fontWeight: 600 }}>×</button>
        <div style={{ flex: 1, fontFamily: EDA.display, fontSize: 16, fontWeight: 600 }}>New IOU</div>
      </div>

      <div style={edaStyles.scroll}>
        <div style={{ padding: 22 }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.16em', textTransform: 'uppercase', color: EDA.mute }}>Amount</div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginTop: 6 }}>
            <span style={{ fontFamily: EDA.mono, fontSize: 14, color: EDA.mute }}>ETB</span>
            <input defaultValue="612" style={{ flex: 1, fontFamily: EDA.display, fontSize: 56, fontWeight: 600, border: 'none', outline: 'none', background: 'transparent', color: EDA.ink, letterSpacing: '-0.02em', padding: 0 }} />
          </div>
          <div style={{ height: 1.5, background: EDA.ink, marginTop: 4 }} />
        </div>

        <div style={{ padding: '0 22px' }}>
          <Field label="What for?" placeholder="e.g. Groceries — Shola Market" defaultValue="Groceries — Shola" />
          <Field label="Group / context" placeholder="—" defaultValue="Flatmates" pill />
        </div>

        <div style={{ padding: '8px 22px 0' }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.16em', textTransform: 'uppercase', color: EDA.mute, marginBottom: 8 }}>Split with</div>
          <div style={{ border: `1.5px solid ${EDA.ink}`, background: EDA.card }}>
            {PEOPLE.slice(0, 3).map((p, i) => (
              <label key={p.name} style={{ display: 'grid', gridTemplateColumns: 'auto 1fr auto auto', gap: 12, padding: 14, borderTop: i === 0 ? 'none' : `1px solid ${EDA.ink}`, alignItems: 'center', cursor: 'pointer' }}>
                <div style={{ width: 32, height: 32, border: `1.2px solid ${EDA.ink}`, display: 'grid', placeItems: 'center', fontFamily: EDA.display, fontSize: 12, fontWeight: 600 }}>{p.initial}</div>
                <div style={{ fontSize: 14, fontWeight: 500 }}>{p.name}</div>
                <div style={{ fontFamily: EDA.mono, fontSize: 13 }}>{i < 2 ? '204' : '—'}</div>
                <div style={{ width: 22, height: 22, border: `1.5px solid ${EDA.ink}`, background: i < 2 ? accent.fill : 'transparent', display: 'grid', placeItems: 'center' }}>
                  {i < 2 && <span style={{ fontFamily: EDA.display, fontWeight: 700, fontSize: 14 }}>✓</span>}
                </div>
              </label>
            ))}
          </div>
        </div>

        {/* Split mode */}
        <div style={{ padding: '18px 22px 0' }}>
          <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.16em', textTransform: 'uppercase', color: EDA.mute, marginBottom: 8 }}>Split method</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', border: `1.5px solid ${EDA.ink}` }}>
            {['Equal', 'By share', 'Exact'].map((m, i) => (
              <button key={m} style={{ borderRight: i < 2 ? `1.5px solid ${EDA.ink}` : 'none', background: i === 0 ? EDA.ink : 'transparent', color: i === 0 ? EDA.paper : EDA.ink, padding: 14, fontFamily: EDA.display, fontSize: 13, fontWeight: 600, cursor: 'pointer' }}>{m}</button>
            ))}
          </div>
        </div>

        <div style={{ height: 100 }} />
      </div>

      <div style={{ position: 'absolute', left: 0, right: 0, bottom: 0, padding: '12px 22px 20px', background: EDA.paper, borderTop: `1.5px solid ${EDA.ink}` }}>
        <button style={{ width: '100%', border: `1.5px solid ${EDA.ink}`, background: accent.fill, color: EDA.ink, padding: 16, fontFamily: EDA.display, fontSize: 16, fontWeight: 600, cursor: 'pointer', boxShadow: `4px 4px 0 ${EDA.ink}` }}>
          Send IOU · {fmt(612)}
        </button>
      </div>
    </div>
  );
}

function Field({ label, placeholder, defaultValue, pill }) {
  return (
    <div style={{ marginBottom: 18 }}>
      <div style={{ fontSize: 10, fontWeight: 700, letterSpacing: '0.16em', textTransform: 'uppercase', color: EDA.mute, marginBottom: 6 }}>{label}</div>
      {pill ? (
        <div style={{ display: 'inline-flex', alignItems: 'center', gap: 8, border: `1.5px solid ${EDA.ink}`, padding: '8px 12px', background: EDA.card, fontFamily: EDA.display, fontWeight: 600, fontSize: 14 }}>
          <span style={{ width: 6, height: 6, background: EDA.ink, borderRadius: '50%' }} />
          {defaultValue}
        </div>
      ) : (
        <input defaultValue={defaultValue} placeholder={placeholder} style={{ width: '100%', border: 'none', borderBottom: `1.5px solid ${EDA.ink}`, outline: 'none', background: 'transparent', padding: '8px 0', fontFamily: EDA.display, fontSize: 18, fontWeight: 500, color: EDA.ink }} />
      )}
    </div>
  );
}

Object.assign(window, {
  HomeLedger, HomePeople, HomeReceipt, HomeStacked, TxnDetail, NewIOU, Glyph,
});
