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
        alignItems: 'center',
        justifyContent: 'center',
        fontFamily: 'JetBrains Mono',
      },
      children: [
        // Name
        {
          type: 'p',
          props: {
            style: {
              color: '#f1f5f9',
              fontSize: '96px',
              fontWeight: 700,
              margin: '0 0 28px 0',
              lineHeight: 1,
            },
            children: 'Jerome Aaron',
          },
        },
        // Title
        {
          type: 'p',
          props: {
            style: {
              color: '#22d3ee',
              fontSize: '40px',
              fontWeight: 400,
              margin: '0',
            },
            children: 'Cloud Engineer',
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
