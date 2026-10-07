# Re-render Markdown during local rebuilds after math-engine or runtime changes.
# Use Jekyll's API to clear both memory and disk at the configured cache location,
# leaving unrelated caches alone. Safe builds do not load local plugins.
unless Jekyll.env == "production"
  Jekyll::Hooks.register :site, :after_reset do |_site|
    Jekyll::Cache.new("Jekyll::Converters::Markdown").clear
  end
end
