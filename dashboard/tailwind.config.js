/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#1B4332',
          light: '#2D6A4F',
          50: '#F0FDF4',
        },
        accent: {
          DEFAULT: '#D4A017',
          light: '#F59E0B',
        },
      },
    },
  },
  plugins: [],
};
