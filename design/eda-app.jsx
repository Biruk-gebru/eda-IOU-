// Top-level app: design canvas hosting all variants in iPhone frames, with a
// Tweaks panel for live accent / variant changes.

const { DesignCanvas, DCSection, DCArtboard } = window;
const { IOSDevice } = window;
const { TweaksPanel, TweakSection, TweakRadio, TweakToggle, TweakColor, useTweaks } = window;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "ochre",
  "customAccent": "#D9A441",
  "useCustom": false,
  "showFrames": true
}/*EDITMODE-END*/;

function FrameOrBare({ children, showFrames, label }) {
  if (showFrames) {
    return (
      <IOSDevice width={390} height={844}>
        {children}
      </IOSDevice>
    );
  }
  return (
    <div style={{ width: 390, height: 844, border: `1.5px solid ${EDA.ink}`, background: EDA.paper, overflow: 'hidden' }}>
      {children}
    </div>
  );
}

function App() {
  const [tweaks, setTweaks] = useTweaks(TWEAK_DEFAULTS);
  const preset = ACCENT_PRESETS[tweaks.accent] || ACCENT_PRESETS.ochre;
  const accent = tweaks.useCustom
    ? { fill: tweaks.customAccent, deep: tweaks.customAccent, label: 'Custom' }
    : preset;

  // The artboard width has to match what we render so the frame isn't cropped
  const artW = tweaks.showFrames ? 430 : 392;
  const artH = tweaks.showFrames ? 870 : 846;

  return (
    <React.Fragment>
      <DesignCanvas title="EDA — Home redesign" subtitle="Editorial brutalist · paper + ink + ochre">

        <DCSection id="home" title="Home — four directions">
          <DCArtboard id="ledger" label="A · Ledger — slab hero, 3 tiles, bordered list" width={artW} height={artH}>
            <FrameOrBare showFrames={tweaks.showFrames}><HomeLedger accent={accent} /></FrameOrBare>
          </DCArtboard>
          <DCArtboard id="stacked" label="B · Stacked — closest to reference rhythm" width={artW} height={artH}>
            <FrameOrBare showFrames={tweaks.showFrames}><HomeStacked accent={accent} /></FrameOrBare>
          </DCArtboard>
          <DCArtboard id="people" label="C · People-first — who do I owe?" width={artW} height={artH}>
            <FrameOrBare showFrames={tweaks.showFrames}><HomePeople accent={accent} /></FrameOrBare>
          </DCArtboard>
          <DCArtboard id="receipt" label="D · Receipt — most editorial" width={artW} height={artH}>
            <FrameOrBare showFrames={tweaks.showFrames}><HomeReceipt accent={accent} /></FrameOrBare>
          </DCArtboard>
        </DCSection>

        <DCSection id="flows" title="Companion flows (paired with any home variant)">
          <DCArtboard id="newiou" label="New IOU sheet" width={artW} height={artH}>
            <FrameOrBare showFrames={tweaks.showFrames}><NewIOU accent={accent} /></FrameOrBare>
          </DCArtboard>
          <DCArtboard id="detail" label="Transaction detail · pending approval" width={artW} height={artH}>
            <FrameOrBare showFrames={tweaks.showFrames}><TxnDetail accent={accent} /></FrameOrBare>
          </DCArtboard>
        </DCSection>

      </DesignCanvas>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Accent">
          <TweakRadio
            label="Preset"
            value={tweaks.accent}
            onChange={(v) => setTweaks({ accent: v, useCustom: false })}
            options={Object.entries(ACCENT_PRESETS).map(([k, v]) => ({ value: k, label: v.label }))}
          />
          <TweakToggle
            label="Use custom color"
            value={tweaks.useCustom}
            onChange={(v) => setTweaks({ useCustom: v })}
          />
          {tweaks.useCustom && (
            <TweakColor
              label="Custom"
              value={tweaks.customAccent}
              onChange={(v) => setTweaks({ customAccent: v })}
            />
          )}
        </TweakSection>

        <TweakSection label="Display">
          <TweakToggle
            label="iPhone frames"
            value={tweaks.showFrames}
            onChange={(v) => setTweaks({ showFrames: v })}
          />
        </TweakSection>
      </TweaksPanel>
    </React.Fragment>
  );
}

ReactDOM.createRoot(document.getElementById('root')).render(<App />);
