import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Heliograph',
  description: 'Game design and technical documentation for Heliograph.',
  base: process.env.VITEPRESS_BASE ?? '/',
  cleanUrls: true,
  lastUpdated: true,
  themeConfig: {
    nav: [
      { text: 'Play the game', link: 'https://github.com/KnightRider2070/heliograph/releases' },
      {
        text: 'Design',
        items: [
          { text: 'Game Design', link: '/game-design' },
          { text: 'Story and Narrative', link: '/story' },
          { text: 'Theme and Art Direction', link: '/theme-and-art-direction' },
          { text: 'Editing Levels', link: '/level-editing' },
          { text: 'Audio Production', link: '/audio-production' },
          { text: 'Asset Reuse Plan', link: '/asset-plan' },
          { text: 'Visual Asset Generation', link: '/visual-asset-generation' },
          { text: 'Jam Levels', link: '/level-design' },
        ],
      },
      {
        text: 'Engineering',
        items: [
          { text: 'Architecture', link: '/architecture' },
          { text: 'Physics and Engine Systems', link: '/physics-and-engine' },
        ],
      },
      { text: 'Development', link: '/development' },
    ],
    sidebar: [
      { text: 'Overview', link: '/' },
      {
        text: 'Design',
        items: [
          { text: 'Game Design', link: '/game-design' },
          { text: 'Story and Narrative', link: '/story' },
          { text: 'Theme and Art Direction', link: '/theme-and-art-direction' },
          { text: 'Editing Levels', link: '/level-editing' },
          { text: 'Audio Production', link: '/audio-production' },
          { text: 'Asset Reuse Plan', link: '/asset-plan' },
          { text: 'Visual Asset Generation', link: '/visual-asset-generation' },
          { text: 'Jam Level Design', link: '/level-design' },
        ],
      },
      {
        text: 'Engineering',
        items: [
          { text: 'Technical Architecture', link: '/architecture' },
          { text: 'Physics and Engine Systems', link: '/physics-and-engine' },
          { text: 'Development Guide', link: '/development' },
        ],
      },
    ],
    search: { provider: 'local' },
    outline: { level: [2, 3] },
    docFooter: { prev: 'Previous', next: 'Next' },
  },
})
