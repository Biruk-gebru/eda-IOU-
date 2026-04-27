// Design tokens for the EDA redesign — editorial brutalist take inspired by
// the reference's geometric rhythm (no rounded corners, hairline black
// borders, generous breathing room) but recolored to fit eda's monochrome
// system. Single accent — muted ochre — via oklch.

const EDA = {
  // Backgrounds: warm-tinted paper, two stops
  paper:   '#EFECDF',           // app background — warm cream
  paperLo: '#E6E3D4',           // subtle inset
  ink:     '#16140F',           // foreground / borders
  inkSoft: '#3A352A',           // secondary text
  mute:    '#7A7363',           // tertiary text
  card:    '#FBFAF3',           // card surface (slight warm white)

  // Single accent — muted ochre. oklch-derived hues all share L≈0.78 C≈0.13
  accent:  '#D9A441',           // ochre default
  accentInk: '#16140F',         // ink reads on accent
  accentDeep: '#A87921',

  // States
  good:    '#1F6A3A',           // owed-to-you
  bad:     '#9A2A1F',           // you-owe (muted brick, not red-red)

  // Type
  display: "'Fraunces', 'Times New Roman', serif",
  text:    "'Inter', system-ui, sans-serif",
  mono:    "'JetBrains Mono', ui-monospace, monospace",
};

// Palette presets exposed via Tweaks. All share chroma/lightness — only hue varies.
const ACCENT_PRESETS = {
  ochre:   { fill: '#D9A441', deep: '#A87921', label: 'Ochre' },
  rust:    { fill: '#C46A3F', deep: '#8B4521', label: 'Rust'  },
  sage:    { fill: '#8FA876', deep: '#5E7449', label: 'Sage'  },
  ink:     { fill: '#2A2620', deep: '#000000', label: 'Ink'   },
  poppy:   { fill: '#D04B2E', deep: '#8B2D17', label: 'Poppy' },
};

// ── Sample data ───────────────────────────────────────────────────────────
const USER = {
  name: 'Enjelin Morgeana',
  initial: 'EM',
  greeting: 'Welcome back,',
};

const BALANCE = {
  net:    +312,           // net (positive = owed to you)
  youOwe: 1840,
  owedToYou: 2152,
  currency: 'ETB',
};

const TXNS = [
  { id: 't1', title: 'Ride to Bole airport',     who: 'with Selam',           when: 'Today, 09:14',         amount: -240,  status: 'pending',  group: 'Trip · Lalibela' },
  { id: 't2', title: 'Groceries — Shola Market', who: 'with Dawit, Hanna +1', when: 'Yesterday',            amount: -612,  status: 'approved', group: 'Flatmates' },
  { id: 't3', title: 'Concert tickets',          who: 'paid by Hanna',        when: 'Apr 22',               amount: +480,  status: 'applied',  group: 'Friends' },
  { id: 't4', title: 'Coffee · Tomoca',          who: 'with Selam',           when: 'Apr 21',               amount: -85,   status: 'applied',  group: null },
  { id: 't5', title: 'Rent split — May',         who: 'with Dawit, Hanna',    when: 'Apr 20',               amount: -4200, status: 'applied',  group: 'Flatmates' },
  { id: 't6', title: 'Movie night',              who: 'paid by Dawit',        when: 'Apr 18',               amount: +120,  status: 'applied',  group: 'Flatmates' },
];

const PEOPLE = [
  { name: 'Selam Tesfaye',  initial: 'ST', net:  +740,  txns: 14 },
  { name: 'Dawit Bekele',   initial: 'DB', net:  -1280, txns: 23 },
  { name: 'Hanna Girma',    initial: 'HG', net:  +610,  txns: 9  },
  { name: 'Yonas Alemu',    initial: 'YA', net:  +242,  txns: 4  },
];

const GROUPS = [
  { name: 'Flatmates',      members: 3, net: -540 },
  { name: 'Trip · Lalibela',members: 5, net: +180 },
  { name: 'Friends',        members: 8, net: +672 },
];

// Currency formatter
const fmt = (n, currency = 'ETB') => {
  const abs = Math.abs(n).toLocaleString('en-US');
  return `${currency} ${abs}`;
};
const fmtSigned = (n, currency = 'ETB') => {
  const sign = n >= 0 ? '+' : '−';
  return `${sign}${fmt(n, currency)}`;
};

Object.assign(window, { EDA, ACCENT_PRESETS, USER, BALANCE, TXNS, PEOPLE, GROUPS, fmt, fmtSigned });
