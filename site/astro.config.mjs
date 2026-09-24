// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  site: 'https://jeromeaaron.com',
  integrations: [sitemap()],
  // The CloudFront CSP only allows stylesheets from 'self' and Google Fonts,
  // so CSS must never be inlined into the HTML.
  build: {
    inlineStylesheets: 'never',
  },
  markdown: {
    // Prism highlights with CSS classes. Shiki (the default) uses inline
    // style attributes, which the CSP blocks.
    syntaxHighlight: 'prism',
  },
  vite: {
    plugins: [tailwindcss()]
  }
});
