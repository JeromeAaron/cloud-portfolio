import type { APIRoute } from 'astro';
import satori from 'satori';
import { Resvg } from '@resvg/resvg-js';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

// Social preview image (LinkedIn, Slack, etc.), rendered at build time.
// Colors match the site's dark theme tokens in global.css.
const C = {
  bg: '#0B0E13',
  tile: '#12161D',
  line: '#2E3846',
  fg: '#E8ECF2',
  fg2: '#C3CAD5',
  muted: '#8E99AA',
  accent: '#93B4FF',
  ok: '#4ADE80',
};

// Small helper so the element tree below stays readable.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const h = (type: string, style: Record<string, unknown>, children?: any): any => ({
  type,
  props: { style, children },
});

export const GET: APIRoute = async () => {
  // Satori needs TTF or WOFF, not WOFF2.
  const fontsDir = resolve('./src/fonts');
  const regular = readFileSync(resolve(fontsDir, 'JetBrainsMono-Regular.ttf')).buffer;
  const bold = readFileSync(resolve(fontsDir, 'JetBrainsMono-Bold.ttf')).buffer;

  const chip = (text: string) =>
    h('div', {
      display: 'flex', padding: '10px 18px', borderRadius: '12px',
      border: `2px solid ${C.line}`, backgroundColor: C.tile, color: C.fg2, fontSize: '24px',
    }, text);

  const element = h('div', {
    width: '1200px', height: '630px', display: 'flex', flexDirection: 'column',
    justifyContent: 'space-between', padding: '64px 72px',
    backgroundColor: C.bg, fontFamily: 'JetBrains Mono',
    backgroundImage: 'radial-gradient(circle at 100% 0%, rgba(147,180,255,0.18), rgba(11,14,19,0) 55%)',
  }, [
    // Top row: monogram and domain
    h('div', { display: 'flex', alignItems: 'center', justifyContent: 'space-between' }, [
      h('div', {
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        width: '76px', height: '76px', borderRadius: '18px',
        backgroundColor: C.fg, color: C.bg, fontSize: '30px', fontWeight: 700,
      }, 'JA'),
      h('div', { display: 'flex', alignItems: 'center', color: C.muted, fontSize: '26px' }, [
        h('div', { display: 'flex', width: '14px', height: '14px', borderRadius: '7px', backgroundColor: C.ok, marginRight: '14px' }),
        'jeromeaaron.com',
      ]),
    ]),
    // Name and role
    h('div', { display: 'flex', flexDirection: 'column' }, [
      h('div', { display: 'flex', color: C.fg, fontSize: '92px', fontWeight: 700, lineHeight: 1, letterSpacing: '-3px' }, 'Jerome Aaron'),
      h('div', { display: 'flex', color: C.accent, fontSize: '36px', marginTop: '24px' }, 'Federal IT Specialist · Cloud Engineer'),
    ]),
    // Credentials
    h('div', { display: 'flex', gap: '14px' }, [
      chip('AWS Solutions Architect'),
      chip('Security+'),
      chip('Terraform'),
      chip('GitHub Actions'),
    ]),
  ]);

  const svg = await satori(element, {
    width: 1200,
    height: 630,
    fonts: [
      { name: 'JetBrains Mono', data: regular, weight: 400, style: 'normal' },
      { name: 'JetBrains Mono', data: bold, weight: 700, style: 'normal' },
    ],
  });

  const png = new Resvg(svg, { fitTo: { mode: 'width', value: 1200 } })
    .render()
    .asPng();

  // Response wants a plain Uint8Array, not a Node Buffer.
  return new Response(new Uint8Array(png), {
    headers: { 'Content-Type': 'image/png' },
  });
};
