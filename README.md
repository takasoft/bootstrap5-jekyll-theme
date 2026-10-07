# Bootstrap 5 Jekyll Theme

Simple, modern Bootstrap 5 theme for Jekyll. A successor to [Bootstrap-4-Jekyll-Theme](https://github.com/takasoft/Bootstrap-4-Jekyll-Theme).

## Features

- Bootstrap **5.3.8** — no jQuery dependency, single bundle (includes Popper), loaded from jsDelivr CDN with SRI hashes
- **Build-time LaTeX** via kramdown + KaTeX — math is rendered to HTML at build time; no client-side JS engine at runtime
- Lazy-loaded **Mermaid** diagrams — only fetched on pages that contain a ` ```mermaid ` block
- Mobile-friendly long equations — `.katex-display` gets horizontal scroll instead of pushing the layout wide
- **Cloudflare Web Analytics** and **Google Analytics 4** — both controlled by `_config.yml` flags, both off by default
- Auto-generated **Related Posts** ranked by shared `tags` / `categories`
- Pagination, category pages, RSS/Atom feed, syntax highlighting
- Includes a GitHub Actions workflow for the two-repo deploy pattern (private source, public output)
- Page-aware Open Graph and Twitter cards, with optional preview images
- Optional pinned posts, without removing categories or numbered pagination
- Local-preview-safe navigation and assets, including project-site subpaths
- Development tab labels and automatic Markdown cache recovery for math

### What changed from Bootstrap-4-Jekyll-Theme?

- Bootstrap 4.3.1 → 5.3.8 (jQuery removed; ~15 KB gzip lighter and 2 fewer requests)
- Universal Analytics (deprecated) replaced with GA4 + Cloudflare Web Analytics
- Switched from dying `stackpath.bootstrapcdn.com` to `cdn.jsdelivr.net` with SRI integrity hashes
- Bootstrap 5 attribute renames applied throughout (`data-bs-toggle`, `ms-auto`, `visually-hidden`, etc.)
- CSS workaround for Bootstrap 5's default link underline on post titles
- Math rendering moved from client-side MathJax to build-time KaTeX (kramdown's `math_engine: katex`)
- Default deploy is now Actions-based two-repo setup so build-time math and arbitrary gems just work

### Page load: v4 vs v5

Measured against the home page CDN assets (Bootstrap CSS + JS + jQuery + Popper for v4; Bootstrap CSS + bundled JS for v5), gzipped over the wire:

|                       | v4 stack                    | v5 stack                | Delta             |
| --------------------- | --------------------------- | ----------------------- | ----------------- |
| Requests              | 12                          | 10                      | −2                |
| Total transfer (gzip) | ~365 KB                     | ~350 KB                 | −15 KB (−22% of Bootstrap stack) |
| jQuery                | required (~30 KB gzip)      | dropped                 | gone              |
| Popper                | separate script             | bundled into Bootstrap  | one fewer request |

Mermaid (~500 KB compressed) is loaded only when the page actually needs it. KaTeX CSS (~26 KB) is loaded only on pages where the layout detects KaTeX markup in the rendered content, and KaTeX fonts download on-demand only when a math glyph is rendered on screen.

## Recommended setup: private source, public deploy

This theme defaults to the **two-repo pattern**: keep your Jekyll source in a private repo, build it via GitHub Actions, and force-push the built `_site/` to a separate public repo that GitHub Pages serves. This unlocks build-time math (via `kramdown-math-katex`, which Pages-classic doesn't whitelist) and works for $0 on GitHub Free.

For the full walkthrough — why Pages won't build private repos on Free, the GitHub Actions workflow, the migration steps, and the gotchas — see: <https://takasoft.io/blog/hosting-private-jekyll-source-on-github-free>.

The included `.github/workflows/deploy.yml` is the workflow from that post, lightly templated. You'll edit two lines (the output repo, and optionally a CNAME).

### Quick start

1. **Create a private source repo from a copy of this theme.** A fork of a public repository cannot be made private. Use a separate repository if you want private source.

2. **Create a second public repo** to receive the built site. If you want a user site, name it `<your-username>.github.io`. Initialize with a single empty commit.

3. **Create a dedicated SSH deploy key pair** for the output repo. Add the public key in that repo's `Settings → Deploy keys`, with write access enabled. Store the private key only in the source repo's Actions secret `PAGES_DEPLOY_KEY`. Do not reuse another repository's key or commit either credentials or temporary private-key files.

4. **Edit `.github/workflows/deploy.yml`**: set `external_repository:` to your public repo (`your-username/your-username.github.io`), and uncomment `cname:` if you have a custom domain.

5. **Edit `_config.yml`**: update `title`, `tagline`, `description`, `url`. Set `baseurl: ""` for a user-site (apex) deployment, or `baseurl: /repo-name` for a project site.

6. **Push to the source branch configured in the workflow.** The workflow runs `JEKYLL_ENV=production bundle exec jekyll build --safe` and publishes `_site/` to the public repo's `gh-pages` branch as a single orphan commit.

7. **Enable Pages** on the public repo: `Settings → Pages → Source → gh-pages / (root)`.

The workflow's `GITHUB_TOKEN` has read-only access. The deploy key grants write
access to the separate output repo. It does not expire automatically, so review
and rotate it when access changes or exposure is suspected. Anyone holding the
private key can use it outside GitHub Actions.

For an existing token-based deployment, first add the new key and switch the
workflow. Confirm a successful deployment from the default branch before removing
the old secret. Removing a secret does not revoke the old token.

The output branch must allow the action's orphan updates. Follow your
repository's approval and branch policies rather than disabling protections.

```mermaid
flowchart LR
    Source["Private Jekyll source"] --> Build["Production safe build"]
    Build --> Output["Public gh-pages output"]
    Key["Dedicated output deploy key"] --> Output
    Output --> Pages["GitHub Pages"]
```

### Local preview

```shell
gem install jekyll bundler
bundle install
bundle exec jekyll serve
```

Node.js needs to be on `PATH` (the `kramdown-math-katex` gem calls KaTeX through ExecJS during builds with math). The GitHub Actions runner has Node preinstalled.

Use Ruby 3.3, matching [.ruby-version](.ruby-version). Local browser tabs include
`(dev)`, while production builds keep the normal site title. Internal navigation
and assets stay on the current origin, even when `url` names the production site.
The configured `baseurl` applies to links, icons, pagination, and the Atom feed.
Social metadata and Atom entry URLs remain absolute for external readers.

If Ruby is unavailable on Windows, start Docker Desktop and run from the
repository directory in PowerShell:

```powershell
docker run --rm --name jekyll-theme-preview `
  --publish 127.0.0.1:4000:4000 `
  --mount "type=bind,source=$($PWD.Path),target=/site" `
  --mount type=volume,source=jekyll-theme-gems,target=/usr/local/bundle `
  --workdir /site --env JEKYLL_ENV=development ruby:3.3 sh -lc `
  'apt-get update -qq && apt-get install -y --no-install-recommends nodejs && bundle install --jobs 4 --retry 2 && bundle exec jekyll serve --host 0.0.0.0 --port 4000 --force_polling'
```

Open <http://127.0.0.1:4000/bootstrap5-jekyll-theme/> with the default `baseurl`.
Use <http://127.0.0.1:4000/> if `baseurl` is empty. The port is available only on
this computer. The named volume retains gems, and polling detects changes through
the Windows bind mount. Stop with `docker stop jekyll-theme-preview`.

Restart the server after editing [_config.yml](_config.yml). If math renders as
raw delimiters, confirm Node.js and `kramdown-math-katex` are installed.
The [development cache hook](_plugins/clear_markdown_cache.rb) clears only
Jekyll's Markdown converter cache on each reset, including its memory cache and
configured disk location. It does not run in production or under `--safe`.
For a safe-mode preview, use `bundle exec jekyll clean` before rebuilding if needed.

### Checking theme changes

After `bundle install`, run the production build and the dependency-free Ruby
regression checks:

```shell
JEKYLL_ENV=production bundle exec jekyll build --safe
bundle exec ruby tests/theme_test.rb
```

In PowerShell, set `$env:JEKYLL_ENV = 'production'` before the build instead of
using the inline environment assignment. The checks build disposable synthetic
sites with both empty and nonempty `baseurl`, custom pagination paths, pinned
posts, social metadata, math, and cache behavior. They do not deploy anything.
The build excludes tests, documentation, dependencies, and caches from `_site/`.

## Writing posts

Drop a markdown file in `_posts/` named `YYYY-MM-DD-title.md`. Standard Jekyll front matter applies (`title`, `date`, `layout: post`, `categories`, `tags`).

### Pinned posts

Add `pinned: true` to a post's front matter to promote it above the chronological
listing on the first page. Pinned cards use the same titles, images, excerpts,
dates, and categories as ordinary cards.

A promoted post appears only once on the first page. It still appears at its
normal dated position on later pages, because `jekyll-paginate` counts all posts.
This keeps later pages populated and preserves existing page URLs and counts.
With no pinned posts, the normal listing is unchanged.

### Social link previews

The homepage advertises the site title and description. Posts advertise their
own title and excerpt, or a `description:` front-matter override. Other pages use
their page title and the site description unless overridden.

Set `image:` on a page or post to use its thumbnail for sharing. Optionally add
`social_image:` in [_config.yml](_config.yml) as the fallback. Both accept a
site-relative path or an absolute HTTPS URL. Supply your own image file.
Without an image, the theme emits a summary card and omits image metadata
instead of linking to a nonexistent default image. Image dimensions are not
assumed. Set `image_alt:` for thumbnail alternative text when needed.

### LaTeX math (build-time KaTeX)

Just use kramdown's `$$...$$` syntax — no front-matter flag required. Inline math goes on the same line as text; display math sits in its own paragraph with blank lines around it:

```markdown
Inline: $$ E = mc^2 $$.

Display:

$$
\int_0^\infty e^{-x^2}\, dx = \frac{\sqrt{\pi}}{2}
$$
```

The math is rendered to HTML at build time. The layout auto-detects pages that contain KaTeX markup and pulls in KaTeX's CSS only on those pages — non-math pages don't pay the ~26 KB cost. Readers don't need JavaScript enabled to see math; only the CSS file.

See `_posts/2026-05-19-math-typesetting.md` for a working example.

### Mermaid diagrams

Just write a fenced code block tagged `mermaid` — no flag needed; the loader in `_includes/footer.html` detects them automatically and lazy-imports Mermaid:

````markdown
```mermaid
flowchart LR
    A --> B
```
````

See `_posts/2026-05-19-mermaid-diagrams.md`.

### Categories (manual step)

For each new category, create `category/<name>.html`:

```markdown
---
layout: category
title: Category Name
category: category-name
---
```

### Related Posts

Add `tags:` and/or `categories:` to a post's front matter. The "Related Posts" section is auto-generated, ranked by overlap (more shared tags/categories = higher rank), with date as a tie-breaker. The section hides itself when no other post shares any tag/category.

### Embed a YouTube video

```liquid
{% include youtubePlayer.html id="video-id" %}
```

## Analytics

### Cloudflare Web Analytics

Privacy-friendly, no cookies, no consent banner. Sign up at <https://www.cloudflare.com/web-analytics/>, then set in `_config.yml`:

```yaml
cloudflare_analytics_token: your-token-here
```

### Google Analytics 4

Set your GA4 measurement ID in `_config.yml`:

```yaml
google_analytics: G-XXXXXXXXXX
```

## License

MIT. See [LICENSE](LICENSE).
