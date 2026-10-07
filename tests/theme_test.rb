require "cgi"
require "fileutils"
require "jekyll"
require "open3"
require "rbconfig"
require "tmpdir"
require "yaml"

# Exercise rendered output using the existing Jekyll dependencies, without a
# browser, external services, or modifying the theme's sample content.
ROOT = File.expand_path("..", __dir__)
ENV["JEKYLL_ENV"] = "production"
Jekyll::PluginManager.require_from_bundler

def assert(condition, message)
  raise message unless condition
end

def meta(html, name)
  value = html[/<meta (?:name|property)="#{Regexp.escape(name)}" content="([^"]*)">/, 1]
  value && CGI.unescapeHTML(value)
end

def write_post(source, name, attributes, body)
  path = File.join(source, "_posts", name)
  File.write(path, attributes.to_yaml + "---\n\n" + body)
end

def build_site(source, destination, baseurl, **overrides)
  config = Jekyll.configuration({
    "source" => source,
    "destination" => destination,
    "config" => File.join(ROOT, "_config.yml"),
    "url" => "https://site.example.test",
    "baseurl" => baseurl,
    "title" => 'Demo "site" & notes',
    "description" => 'Site overview with "quotes" & details.',
    "paginate" => 2,
    "paginate_path" => "/articles/page:num/",
    "safe" => true,
    "quiet" => true,
    "cache_dir" => File.join(source, ".jekyll-cache")
  }.merge(overrides.transform_keys(&:to_s)))
  Jekyll::Site.new(config).process
end

Dir.mktmpdir("jekyll-theme-test-") do |temp|
  source = File.join(temp, "source")
  FileUtils.mkdir_p(File.join(source, "_posts"))
  %w[_includes _layouts _plugins public category index.html archive.html atom.xml about.md 404.html].each do |entry|
    FileUtils.cp_r(File.join(ROOT, entry), source)
  end

  # A fake dependency template reproduces why custom excludes must retain
  # vendor/bundle. Nothing from this directory should be parsed or published.
  %w[tests vendor/bundle/_posts node_modules].each do |entry|
    FileUtils.mkdir_p(File.join(source, entry))
    File.write(File.join(source, entry, "0000-00-00-private-template.md"), "---\nlayout: post\n---\nExcluded")
  end
  File.write(File.join(source, "README.md"), "Build-only documentation")
  File.write(File.join(source, "about.md"), "---\nlayout: page\ntitle: About\npermalink: /about\n---\n\nExample page.")

  5.times do |index|
    number = index + 1
    attrs = {
      "layout" => "post",
      "title" => "Post #{number}",
      "categories" => ["AI"],
      "tags" => ["demo"],
      "pinned" => number == 1 || number == 5
    }
    if number == 5
      attrs["title"] = 'Post "five" & details'
      attrs["description"] = 'A <strong>bold</strong> "summary" & details.'
      attrs["image"] = "/public/assets/ai-brain.jpg"
      attrs["image_alt"] = 'An "example" image'
    elsif number == 4
      attrs["image"] = "https://images.example.test/preview.png"
    end
    write_post(source, "2020-01-0#{number}-post-#{number}.md", attrs,
               "Excerpt for post #{number} with R&D.\n\n$$ E = mc^2 $$\n")
  end

  ["", "/theme"].each do |baseurl|
    destination = File.join(temp, baseurl.empty? ? "apex" : "subpath")
    build_site(source, destination, baseurl)
    home = File.read(File.join(destination, "index.html"))
    second = File.read(File.join(destination, "articles", "page2", "index.html"))
    third = File.read(File.join(destination, "articles", "page3", "index.html"))
    post = File.read(File.join(destination, "post-5.html"))
    unillustrated = File.read(File.join(destination, "post-3.html"))
    external_image = File.read(File.join(destination, "post-4.html"))
    about = File.read(File.join(destination, "about.html"))
    feed = File.read(File.join(destination, "atom.xml"))

    assert(home.include?('class="pinned-posts"'), "Pinned section missing")
    assert(home.scan('class="post post-pinned"').size == 2, "Both pins must be promoted")
    assert(home.scan('class="post-title">Post &quot;five&quot; &amp; details').size == 1, "Recent pin duplicated on home")
    assert(home.include?('class="post-title">Post 4'), "Regular card missing")
    assert(!second.include?('class="pinned-posts"'), "Pins repeated above page two")
    assert(third.include?('class="post-title">Post 1'), "Old pin lost from its chronological page")
    assert(home.include?("href=\"#{baseurl}/articles/page2/\""), "Custom next page path missing")
    assert(second.include?("href=\"#{baseurl}/\""), "Previous page must return home")
    assert(third.include?("href=\"#{baseurl}/articles/page2/\""), "Custom previous page path missing")
    assert(home.include?("href=\"#{baseurl}/category/AI\""), "Card categories lost")
    assert(post.include?("href=\"#{baseurl}/category/AI\""), "Post categories lost")
    assert(post.include?('class="related"'), "Related posts lost")
    assert(post.include?('class="katex"') && post.include?("katex.min.css"), "Build-time math or CSS missing")
    assert(!home.include?("(dev)"), "Production title has development label")

    assert(meta(home, "og:title") == 'Demo "site" & notes', "Homepage must advertise site title")
    assert(meta(home, "og:description") == 'Site overview with "quotes" & details.', "Homepage description leaked a post excerpt")
    assert(meta(home, "twitter:card") == "summary", "No-image homepage must use summary card")
    assert(meta(home, "og:image").nil?, "Missing default image advertised")
    assert(meta(post, "og:type") == "article", "Post type missing")
    assert(meta(post, "og:title") == 'Post "five" & details', "Post title not escaped")
    assert(meta(post, "og:description") == 'A bold "summary" & details.', "Description override not normalized")
    assert(meta(post, "og:image") == "https://site.example.test#{baseurl}/public/assets/ai-brain.jpg", "Local social image URL incorrect")
    assert(meta(post, "og:image:width").nil?, "Image dimensions must not be assumed")
    %w[description og:description twitter:description].each do |name|
      assert(meta(unillustrated, name) == "Excerpt for post 3 with R&D.", "Post excerpt entities double-escaped in #{name}")
    end
    assert(meta(unillustrated, "og:image").nil?, "Image leaked between posts")
    assert(meta(external_image, "og:image") == "https://images.example.test/preview.png", "Absolute social image URL changed")
    assert(meta(about, "og:title") == "About", "Static page title missing")
    assert(meta(home, "og:url") == "https://site.example.test#{baseurl}/", "Homepage social URL incorrect")
    assert(feed.include?("href=\"https://site.example.test#{baseurl}/atom.xml\""), "Feed self URL missing baseurl")
    assert(feed.include?("href=\"https://site.example.test#{baseurl}/post-5\""), "Feed post URL missing baseurl")

    Dir.glob(File.join(destination, "**", "*.html")).each do |file|
      html = File.read(file)
      assert(!html.match?(/(?:href|src)="https:\/\/site\.example\.test/), "Internal link escaped preview in #{file}")
    end
    assert(home.include?("href=\"#{baseurl}/public/css/main.css\""), "Stylesheet path incorrect")
    assert(home.include?("href=\"#{baseurl}/public/apple-touch-icon-144-precomposed.png\""), "Touch icon path incorrect")
    assert(home.include?("href=\"#{baseurl}/atom.xml\""), "Feed discovery path incorrect")
    assert(post.include?("src=\"#{baseurl}/public/assets/ai-brain.jpg\""), "Post thumbnail path incorrect")
    %w[README.md tests vendor node_modules].each do |entry|
      assert(!File.exist?(File.join(destination, entry)), "Build-only content published: #{entry}")
    end
  end

  destination = File.join(temp, "fallback")
  build_site(source, destination, "/theme", social_image: "/public/assets/ai-brain.jpg")
  home = File.read(File.join(destination, "index.html"))
  assert(meta(home, "og:image") == "https://site.example.test/theme/public/assets/ai-brain.jpg", "Configured fallback image missing")
  assert(meta(home, "twitter:card") == "summary_large_image", "Image card missing")

  Dir.glob(File.join(source, "_posts", "*.md")).each do |file|
    File.write(file, File.read(file).gsub("pinned: true", "pinned: false"))
  end
  ENV["JEKYLL_ENV"] = "development"
  build_site(source, destination, "", safe: false)
  home = File.read(File.join(destination, "index.html"))
  assert(!home.include?('class="pinned-posts"'), "Unpinned site has a pinned section")
  assert(home.scan('class="post-title"').size == 2, "Unpinned pagination changed")
  assert(home.include?("(dev)"), "Development title label missing")
end

# Separate processes prevent hook registration from one environment from
# contaminating another. Check memory and disk with a non-default cache path.
cache_check = <<~'RUBY'
  require "jekyll"
  require "tmpdir"
  Dir.mktmpdir("jekyll-cache-test-") do |source|
    site = Jekyll::Site.new(Jekyll.configuration(
      "source" => source, "quiet" => true,
      "cache_dir" => File.join(source, "custom-cache"), "safe" => ARGV[1] == "safe"
    ))
    markdown = Jekyll::Cache.new("Jekyll::Converters::Markdown")
    other = Jekyll::Cache.new("Other")
    markdown["stale"] = "raw math delimiters"
    other["keep"] = "unrelated cache"
    FileUtils.mkdir_p(File.join(source, "_plugins"))
    FileUtils.cp(ARGV[0], File.join(source, "_plugins", "clear_markdown_cache.rb"))
    site.plugin_manager.conscientious_require
    site.reset
    should_keep = Jekyll.env == "production" || site.safe
    raise "Wrong Markdown cache behavior" unless markdown.key?("stale") == should_keep
    raise "Unrelated cache cleared" unless other.key?("keep")
    files = Dir.glob(File.join(source, "custom-cache", "Jekyll", "Cache", "Jekyll--Converters--Markdown", "**", "*")).select { |file| File.file?(file) }
    should_keep_disk = should_keep && !site.safe
    raise "Disk cache behavior differs" unless files.empty? == !should_keep_disk
  end
RUBY
[%w[development unsafe], %w[production unsafe], %w[development safe]].each do |environment, mode|
  output, status = Open3.capture2e(
    { "JEKYLL_ENV" => environment }, RbConfig.ruby, "-e", cache_check,
    File.join(ROOT, "_plugins", "clear_markdown_cache.rb"), mode
  )
  assert(status.success?, "Cache regression (#{environment}, #{mode}): #{output}")
end

workflow = YAML.load_file(File.join(ROOT, ".github", "workflows", "deploy.yml"))
assert(workflow.fetch("permissions") == { "contents" => "read" }, "Workflow token must be read-only")
steps = workflow.fetch("jobs").fetch("build-deploy").fetch("steps")
build = steps.find { |step| step["name"] == "Build site" }
deploy = steps.find { |step| step["name"] == "Deploy to public Pages repo" }
assert(build.fetch("env").fetch("JEKYLL_ENV") == "production", "Workflow must build for production")
assert(build.fetch("run").include?("--safe"), "Deployment must use a safe build")
assert(deploy.fetch("with").fetch("deploy_key") == '${{ secrets.PAGES_DEPLOY_KEY }}', "Deploy key not wired")
assert(!deploy.fetch("with").key?("personal_token"), "Obsolete deployment token still configured")
puts "Theme regressions passed."
