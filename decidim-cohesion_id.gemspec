# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("lib", __dir__)

require "decidim/cohesion_id/version"

Gem::Specification.new do |s|
  s.version = Decidim::CohesionId.version
  s.authors = ["Lorenzo Angelone"]
  s.email = ["l.angelone@kapusons.it"]
  s.license = "AGPL-3.0-or-later"
  s.homepage = "https://decidim.org"
  s.metadata = {
    "bug_tracker_uri" => "https://github.com/decidim/decidim/issues",
    "documentation_uri" => "https://docs.decidim.org/",
    "funding_uri" => "https://opencollective.com/decidim",
    "homepage_uri" => "https://decidim.org",
    "source_code_uri" => "https://github.com/kapusons/decidim-module-CohesionId.git"
  }
  s.required_ruby_version = "~> 3.1"

  s.name = "decidim-cohesion_id"
  s.summary = "A decidim CohesionID module"
  s.description = "CohesionID Integration for Decidim."

  s.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").select do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w(app/ config/ db/ lib/ LICENSE-AGPLv3.txt Rakefile README.md))
    end
  end

  s.add_dependency "decidim-core", "~> #{Decidim::CohesionId.version}"

  s.add_dependency "rexml", "~> 3.2"
  s.add_dependency 'omniauth', '~> 2.0'
  s.add_dependency "deface", '~> 1.9.0'
end
