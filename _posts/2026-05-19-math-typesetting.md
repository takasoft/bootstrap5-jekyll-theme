---
title: Math typesetting with KaTeX
date: 2026-05-19T12:00:00+00:00
layout: post
categories:
  - Demo
tags:
  - math
  - demo
---

Math is rendered to HTML at build time by kramdown's KaTeX engine — no
client-side JavaScript runs to display the equations. The layout
auto-detects pages with math and pulls in KaTeX's CSS only on those
pages, so no front-matter flag is needed.

Inline math uses `$$...$$` on the same line as text: $$ E = mc^2 $$.

Display math uses `$$...$$` on its own paragraph (blank lines around it):

$$
\int_{-\infty}^{\infty} e^{-x^2}\, dx = \sqrt{\pi}
$$

A longer equation that would otherwise overflow on mobile — the theme
adds horizontal-scroll on `.katex-display` so the page layout doesn't
get pushed wider than the viewport:

$$
\text{target} = P \cdot \left(1 + \tfrac{r}{12}\right)^{12t} + \frac{x}{12} \cdot \frac{\left(1 + \tfrac{r}{12}\right)^{12t} - 1}{r/12}
$$
