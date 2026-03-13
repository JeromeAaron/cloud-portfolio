import type { APIRoute } from 'astro';
import satori from 'satori';
import { Resvg } from '@resvg/resvg-js';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

export const GET: APIRoute = async () => {
  // Read bundled TTF fonts — satori requires woff or TTF, not woff2
  const fontsDir = resolve('./src/fonts');
  const regular = readFileSync(resolve(fontsDir, 'JetBrainsMono-Regular.ttf')).buffer;
  const bold = readFileSync(resolve(fontsDir, 'JetBrainsMono-Bold.ttf')).buffer;

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const element: any = {
    type: 'div',
    props: {
      style: {
        width: '1200px',
        height: '630px',
        backgroundColor: '#020617',
        display: 'flex',
        flexDirection: 'column',
        justifyContent: 'center',
        padding: '80px 80px 80px 88px',
        fontFamily: 'JetBrains Mono',
        borderLeft: '8px solid #22d3ee',
        boxSizing: 'border-box',
      },
      children: [
        // $ whoami
        {
          type: 'p',
          props: {
            style: {
              color: '#22d3ee',
              fontSize: '22px',
              margin: '0 0 20px 0',
              fontWeight: 400,
            },
            children: '$ whoami',
          },
        },
        // Name
        {
          type: 'h1',
          props: {
            style: {
              color: '#f1f5f9',
              fontSize: '80px',
              fontWeight: 700,
              margin: '0 0 24px 0',
              lineHeight: 1.1,
            },
            children: 'Jerome Aaron',
          },
        },
        // Tagline
        {
          type: 'p',
          props: {
            style: {
              color: '#94a3b8',
              fontSize: '30px',
              fontWeight: 400,
              margin: '0 0 52px 0',
            },
            children: 'Cloud Engineer · IT Specialist · Washington DC',
          },
        },
        // Tech tags row
        {
          type: 'div',
          props: {
            style: { display: 'flex', gap: '14px' },
            children: ['AWS', 'Terraform', 'GitHub Actions', 'AWS SAA'].map((tag) => ({
              type: 'span',
              props: {
                style: {
                  backgroundColor: '#0f172a',
                  border: '1px solid #1e293b',
                  color: '#64748b',
                  fontSize: '20px',
                  padding: '8px 18px',
                  borderRadius: '6px',
                  fontWeight: 400,
                },
                children: tag,
              },
            })),
          },
        },
        // Site URL (bottom)
        {
          type: 'p',
          props: {
            style: {
              color: '#22d3ee',
              fontSize: '20px',
              fontWeight: 400,
              margin: '48px 0 0 0',
            },
            children: 'jeromeaaron.com',
          },
        },
      ],
    },
  };

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

  return new Response(png, {
    headers: { 'Content-Type': 'image/png' },
  });
};
