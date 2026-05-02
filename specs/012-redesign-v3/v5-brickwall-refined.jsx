// V5 — Brick Wall (refined)
// Base: V3 brick metaphor. Adds:
// - "Session no. 142" eyebrow (from B)
// - "A note for today's session…" italic in-line note (from B)
// - "Firing · 0:02" pill (from D)
// - Brick-wall pattern background (instead of dot grid)

const v5Tokens = {
  bg: '#F2EDE3',
  bgDeeper: '#E8DFCE',
  card: '#FFFFFF',
  cardEdge: 'rgba(0,0,0,0.06)',
  ink: '#1B1612',
  ink2: '#5C544A',
  ink3: '#9A9089',
  hair: 'rgba(0,0,0,0.06)',

  brick1: '#B8543A',
  brick2: '#9C3E26',
  brickShade: '#7A2D18',
  mortar: '#E8DDC9',

  red: '#B43B2E',
  accent: '#C26B3F',

  font: '"Inter", -apple-system, system-ui, sans-serif',
  display: '"Instrument Serif", "Cooper", Georgia, serif',
  serif: '"Fraunces", Georgia, serif',
  mono: '"JetBrains Mono", ui-monospace, monospace',
};

// Brick-wall pattern as inline SVG dataURI (running bond).
// Two-row pattern: row1 bricks aligned, row2 offset by half-brick.
function v5BrickPatternDataURI() {
  // 60 wide × 30 tall. Brick 30×15, mortar lines 1px.
  const svg = `<svg xmlns='http://www.w3.org/2000/svg' width='60' height='30' viewBox='0 0 60 30'>
    <rect width='60' height='30' fill='%23E8DFCE'/>
    <g stroke='rgba(60,40,25,0.13)' stroke-width='1' fill='none' stroke-linecap='square'>
      <!-- horizontal mortar -->
      <path d='M0 0 H60 M0 15 H60 M0 30 H60'/>
      <!-- vertical mortar row 1 (0-15): joints at x=0,30,60 -->
      <path d='M0 0 V15 M30 0 V15 M60 0 V15'/>
      <!-- vertical mortar row 2 (15-30): joints offset by 15 -->
      <path d='M15 15 V30 M45 15 V30'/>
    </g>
  </svg>`;
  // Replace # with %23 already done; encode spaces
  return `url("data:image/svg+xml;utf8,${svg.replace(/\n\s*/g,'').replace(/#/g,'%23').replace(/"/g,"'")}")`;
}

function V5Header() {
  return (
    <div style={{ padding: '6px 18px 14px', position: 'relative' }}>
      {/* eyebrow row */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
        <div style={{
          fontFamily: v5Tokens.serif, fontStyle: 'italic',
          fontSize: 11, letterSpacing: 2, color: v5Tokens.ink3,
          textTransform: 'uppercase', fontWeight: 500,
        }}>
          Session no. 142
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '4px 10px', background: 'rgba(184,84,58,0.1)', borderRadius: 999 }}>
          <span style={{
            width: 6, height: 6, borderRadius: '50%', background: v5Tokens.brick1,
            boxShadow: `0 0 0 3px rgba(184,84,58,0.18)`,
          }}/>
          <span style={{ fontSize: 10, fontWeight: 700, letterSpacing: 1.4, color: v5Tokens.brick2, textTransform: 'uppercase' }}>
            Firing
          </span>
          <span style={{ width: 1, height: 9, background: 'rgba(184,84,58,0.3)' }}/>
          <span style={{
            fontFamily: v5Tokens.mono, fontSize: 11, fontWeight: 600,
            color: v5Tokens.brick2, fontVariantNumeric: 'tabular-nums',
          }}>
            0:02
          </span>
        </div>
      </div>

      {/* title + actions */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', gap: 12 }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontFamily: v5Tokens.display, fontSize: 34, fontWeight: 400,
            color: v5Tokens.ink, lineHeight: 1, letterSpacing: -0.6,
          }}>
            Full Body B
          </div>
        </div>
        <div style={{ display: 'flex', gap: 6 }}>
          <V5Btn>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M12 5v14M5 12h14"/></svg>
          </V5Btn>
          <V5Btn>
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2"><path d="M7 4v16M7 4l-3 3M7 4l3 3M17 20V4M17 20l-3-3M17 20l3-3"/></svg>
          </V5Btn>
          <button style={{
            background: v5Tokens.red, color: '#fff', border: 'none',
            padding: '8px 14px', borderRadius: 8, fontSize: 13, fontWeight: 600,
            cursor: 'pointer', display: 'flex', alignItems: 'center', gap: 6,
          }}>
            <span style={{ width: 6, height: 6, background: '#fff' }}/>End
          </button>
        </div>
      </div>

      {/* journal-style note */}
      <div style={{
        fontFamily: v5Tokens.serif, fontStyle: 'italic',
        fontSize: 14, color: v5Tokens.ink3, marginTop: 10,
        lineHeight: 1.4,
      }}>
        A note for today's session…
      </div>
    </div>
  );
}

function V5Btn({ children }) {
  return (
    <button style={{
      width: 34, height: 34, borderRadius: 8, background: v5Tokens.card,
      border: `1px solid ${v5Tokens.cardEdge}`, color: v5Tokens.ink,
      cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
    }}>{children}</button>
  );
}

// A "laid" brick — completed set
function V5BrickSet({ idx, prev, weight, reps, offset = 0 }) {
  // Bricks are inset from the card edge by INSET, so the wall has
  // shoulder room. `offset` is signed: negative shifts left, positive
  // shifts right. Running-bond rows alternate around the centerline.
  const INSET = 8;
  return (
    <div style={{
      marginLeft: INSET + offset,
      marginRight: INSET - offset,
      background: `linear-gradient(180deg, ${v5Tokens.brick1} 0%, ${v5Tokens.brick2} 100%)`,
      borderRadius: 4,
      padding: '10px 12px',
      color: '#FBE8DA',
      display: 'grid',
      gridTemplateColumns: '14px 1fr auto auto',
      alignItems: 'center', gap: 10,
      boxShadow: `0 1px 0 ${v5Tokens.brickShade}, 0 2px 4px rgba(122,45,24,0.18)`,
      position: 'relative',
      overflow: 'hidden',
    }}>
      <div style={{
        position: 'absolute', inset: 0, opacity: 0.12,
        backgroundImage: 'radial-gradient(rgba(0,0,0,0.5) 0.6px, transparent 0.7px)',
        backgroundSize: '5px 5px',
        pointerEvents: 'none',
      }}/>
      <div style={{
        fontSize: 10, fontWeight: 700, letterSpacing: 1.2, opacity: 0.7,
        fontVariantNumeric: 'tabular-nums', position: 'relative',
      }}>{String(idx).padStart(2,'0')}</div>
      <div style={{ fontSize: 11, opacity: 0.7, fontFamily: v5Tokens.mono, fontVariantNumeric: 'tabular-nums', position: 'relative' }}>
        prev {prev}
      </div>
      <div style={{
        fontFamily: v5Tokens.mono, fontSize: 15, fontWeight: 700,
        fontVariantNumeric: 'tabular-nums', letterSpacing: -0.3, position: 'relative',
        whiteSpace: 'nowrap',
      }}>
        {weight}<span style={{ opacity: 0.5, fontWeight: 400 }}> lb</span>
      </div>
      <div style={{
        fontFamily: v5Tokens.mono, fontSize: 15, fontWeight: 700,
        fontVariantNumeric: 'tabular-nums', letterSpacing: -0.3, position: 'relative',
        minWidth: 32, textAlign: 'right', whiteSpace: 'nowrap',
      }}>
        ×{reps}
      </div>
    </div>
  );
}

function V5PendingSet({ idx, prev, weight, reps }) {
  return (
    <div style={{
      marginLeft: 8, marginRight: 8,
      background: v5Tokens.card,
      border: `1px dashed ${v5Tokens.hair}`,
      borderRadius: 4,
      padding: '10px 12px',
      display: 'grid',
      gridTemplateColumns: '14px 1fr 60px 50px',
      alignItems: 'center', gap: 10,
    }}>
      <div style={{
        fontSize: 10, fontWeight: 700, letterSpacing: 1.2, color: v5Tokens.ink3,
        fontVariantNumeric: 'tabular-nums',
      }}>{String(idx).padStart(2,'0')}</div>
      <div style={{ fontSize: 11, fontFamily: v5Tokens.mono, color: v5Tokens.ink3, fontVariantNumeric: 'tabular-nums' }}>
        prev {prev}
      </div>
      <V5Field value={weight} suffix="lb"/>
      <V5Field value={reps} prefix="×"/>
    </div>
  );
}

function V5Field({ value, suffix, prefix }) {
  return (
    <div style={{
      borderBottom: `1.5px solid ${v5Tokens.ink}`,
      padding: '4px 4px 2px',
      display: 'flex', alignItems: 'baseline', justifyContent: 'center', gap: 3,
      fontFamily: v5Tokens.mono, fontSize: 15, fontWeight: 600,
      color: v5Tokens.ink, fontVariantNumeric: 'tabular-nums',
    }}>
      {prefix && <span style={{ fontSize: 12, color: v5Tokens.ink3 }}>{prefix}</span>}
      {value}
      {suffix && <span style={{ fontSize: 11, color: v5Tokens.ink3 }}>{suffix}</span>}
    </div>
  );
}

function V5RestTimer() {
  return (
    <div style={{
      background: v5Tokens.mortar,
      borderRadius: 4,
      padding: '10px 12px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      border: `1px solid rgba(184,84,58,0.25)`,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
        <V5RestRing/>
        <div>
          <div style={{ fontSize: 9, fontWeight: 700, letterSpacing: 1.4, color: v5Tokens.brick2, textTransform: 'uppercase' }}>cooling</div>
          <div style={{ fontFamily: v5Tokens.mono, fontSize: 22, fontWeight: 700, color: v5Tokens.ink, fontVariantNumeric: 'tabular-nums', letterSpacing: -0.4, lineHeight: 1 }}>
            1:59
          </div>
        </div>
      </div>
      <button style={{
        background: 'transparent', border: 'none', color: v5Tokens.red,
        fontSize: 13, fontWeight: 600, cursor: 'pointer',
      }}>Skip</button>
    </div>
  );
}

function V5RestRing() {
  return (
    <svg width="28" height="28" viewBox="0 0 28 28">
      <circle cx="14" cy="14" r="11" fill="none" stroke="rgba(184,84,58,0.2)" strokeWidth="2.5"/>
      <circle cx="14" cy="14" r="11" fill="none" stroke={v5Tokens.brick1} strokeWidth="2.5"
        strokeDasharray="69" strokeDashoffset="20" strokeLinecap="round" transform="rotate(-90 14 14)"/>
    </svg>
  );
}

function V5Exercise({ name, sub, note, rest, sets, showRestAt }) {
  let brickIdx = 0;
  // Running bond — alternate rows shift in opposite directions around
  // the card centerline. Wall reads centered overall.
  const offsets = [-7, 7, -7, 7, -7];
  return (
    <div style={{
      background: v5Tokens.card,
      borderRadius: 14,
      margin: '12px 14px 0',
      padding: '14px 12px 10px',
      border: `1px solid ${v5Tokens.cardEdge}`,
      boxShadow: '0 1px 2px rgba(0,0,0,0.02)',
    }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', padding: '0 4px 10px' }}>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{
            fontFamily: v5Tokens.display, fontSize: 22, fontWeight: 400,
            color: v5Tokens.ink, lineHeight: 1.1, letterSpacing: -0.3,
          }}>{name}</div>
          {(sub || true) && (
            <div style={{ fontSize: 12, color: v5Tokens.ink3, marginTop: 4, lineHeight: 1.4 }}>
              {sub && <span>{sub}</span>}
              {sub && <span style={{ margin: '0 6px', opacity: 0.6 }}>·</span>}
              <span style={{
                fontFamily: v5Tokens.serif, fontStyle: 'italic',
                color: note ? v5Tokens.ink2 : v5Tokens.ink3,
                cursor: 'pointer',
              }}>
                {note || 'A note for this exercise…'}
              </span>
            </div>
          )}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, color: v5Tokens.ink3 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 11, fontFamily: v5Tokens.mono, fontVariantNumeric: 'tabular-nums' }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>
            {rest}s
          </div>
          <svg width="14" height="4" viewBox="0 0 14 4"><circle cx="2" cy="2" r="1.5" fill="currentColor"/><circle cx="7" cy="2" r="1.5" fill="currentColor"/><circle cx="12" cy="2" r="1.5" fill="currentColor"/></svg>
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
        {sets.map((s, i) => {
          const node = s.status === 'done'
            ? <V5BrickSet key={i} idx={i+1} prev={s.prev} weight={s.weight} reps={s.reps} offset={offsets[brickIdx++ % offsets.length]} />
            : <V5PendingSet key={i} idx={i+1} prev={s.prev} weight={s.weight} reps={s.reps} />;
          return (
            <React.Fragment key={i}>
              {showRestAt === i && <V5RestTimer/>}
              {node}
            </React.Fragment>
          );
        })}
      </div>

      <button style={{
        background: 'transparent', border: 'none', color: v5Tokens.brick1,
        fontSize: 13, fontWeight: 600, padding: '10px 4px 4px', cursor: 'pointer',
        display: 'flex', alignItems: 'center', gap: 6,
      }}>
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 5v14M5 12h14"/></svg>
        Lay another brick
      </button>
    </div>
  );
}

function V5TabBar() {
  const tabs = [
    { id: 'workouts', label: 'Workouts', icon: (<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M6 4v16M18 4v16M4 8h2M4 16h2M18 8h2M18 16h2M6 12h12"/></svg>) },
    { id: 'history', label: 'History', icon: (<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><path d="M12 6v6l4 2"/></svg>) },
    { id: 'exercises', label: 'Exercises', icon: (<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/></svg>) },
    { id: 'profile', label: 'Profile', icon: (<svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><circle cx="12" cy="8" r="4"/><path d="M4 22c0-4.4 3.6-8 8-8s8 3.6 8 8"/></svg>) },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 18, left: 14, right: 14,
      background: 'rgba(255,255,255,0.94)',
      backdropFilter: 'blur(20px)',
      borderRadius: 14, padding: '6px',
      display: 'flex',
      border: `1px solid ${v5Tokens.cardEdge}`,
      boxShadow: '0 10px 30px rgba(0,0,0,0.08)',
      zIndex: 5,
    }}>
      {tabs.map((t, i) => {
        const a = i === 0;
        return (
          <div key={t.id} style={{
            flex: 1, padding: '8px 4px', display: 'flex', flexDirection: 'column',
            alignItems: 'center', gap: 2,
            background: a ? '#F4E5D7' : 'transparent',
            color: a ? v5Tokens.brick2 : v5Tokens.ink3,
            borderRadius: 10, fontSize: 10, fontWeight: 600,
          }}>
            {t.icon}
            <span>{t.label}</span>
          </div>
        );
      })}
    </div>
  );
}

function V5Screen({ state = 'untouched' }) {
  const setsUntouched = [
    { prev: '25 lb × 10', weight: 25, reps: 10, status: 'pending' },
    { prev: '35 lb × 7',  weight: 35, reps: 7,  status: 'pending' },
    { prev: '35 lb × 7',  weight: 35, reps: 7,  status: 'pending' },
    { prev: '35 lb × 7',  weight: 35, reps: 7,  status: 'pending' },
  ];
  const setsPartial = [
    { prev: '25 lb × 10', weight: 25, reps: 10, status: 'done' },
    { prev: '35 lb × 7',  weight: 35, reps: 7,  status: 'done' },
    { prev: '35 lb × 7',  weight: 35, reps: 7,  status: 'pending' },
    { prev: '35 lb × 7',  weight: 35, reps: 7,  status: 'pending' },
  ];
  const sets = state === 'partial' ? setsPartial : setsUntouched;
  const showRestAt = state === 'partial' ? 2 : undefined;

  return (
    <div style={{
      width: '100%', height: '100%',
      background: v5Tokens.bgDeeper,
      backgroundImage: v5BrickPatternDataURI(),
      backgroundSize: '60px 30px',
      fontFamily: v5Tokens.font,
      overflow: 'auto',
      paddingTop: 56, paddingBottom: 100,
    }}>
      <V5Header/>
      <V5Exercise
        name="Single-arm low row"
        sub="Plate-loaded"
        note="Furthest arm setting"
        rest={120}
        sets={sets}
        showRestAt={showRestAt}
      />
      <V5Exercise
        name="Romanian Deadlift"
        sub="Barbell"
        rest={120}
        sets={[
          { prev: '65 lb × 10',  weight: 65,  reps: 10, status: 'pending' },
          { prev: '125 lb × 7',  weight: 125, reps: 7,  status: 'pending' },
        ]}
      />
      <V5TabBar/>
    </div>
  );
}

window.V5Screen = V5Screen;
