# frozen_string_literal: true
require "fileutils"
require "open3"
require "yaml"

class SpecRepository
  URL = "https://github.com/rage-rb-fans/rage-feature-specs.git"
  attr_reader :path
  def initialize(root)
    @path = File.join(root, ".codex", "specs-repository")
  end

  def git(*args)
    output, error, result = Open3.capture3("git", "-C", path, *args)
    raise "git #{args.first} failed: #{error.strip}" unless result.success?
    output.strip
  end

  def setup
    unless File.exist?(path)
      FileUtils.mkdir_p(File.dirname(path))
      _, error, result = Open3.capture3("git", "clone", "--branch", "main", URL, path)
      raise "Cannot clone specifications: #{error.strip}" unless result.success?
    end
    validate!
  end

  def validate!
    raise "Run spec_workflow.rb setup first" unless File.directory?(path)
    raise "Specification checkout cannot be a symlink" if File.symlink?(path)
    raise "Not a separate specification checkout" unless File.realpath(git("rev-parse", "--show-toplevel")) == File.realpath(path)
    origin = git("remote", "get-url", "origin")
    unless [URL, URL.delete_suffix(".git"), "git@github.com:rage-rb-fans/rage-feature-specs.git"].include?(origin)
      raise "Unexpected specification origin: #{origin}"
    end
    %w[AGENTS.md templates/feature.md templates/task.md templates/adr.md].each do |file|
      raise "Missing repository file: #{file}" unless File.file?(File.join(path, file))
    end
  end

  def sync
    validate!
    raise "Specification checkout has local changes; resolve them before syncing" unless git("status", "--porcelain").empty?
    raise "Switch the clean specification checkout to main before syncing" unless git("branch", "--show-current") == "main"
    git("fetch", "origin", "main")
    git("merge", "--ff-only", "origin/main")
    raise "Local main has unpublished commits" unless git("rev-parse", "HEAD") == git("rev-parse", "origin/main")
    git("rev-parse", "HEAD")
  end

  def feature(slug)
    raise "Use a lowercase kebab-case feature slug" unless /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/.match?(slug.to_s)
    directory = File.join(path, "features", slug)
    raise "Feature directory cannot be a symlink" if File.symlink?(directory)
    directory
  end

  def status(file)
    front = File.read(file).match(/\A---\r?\n(.*?)\r?\n---(?:\r?\n|\z)/m)
    raise "Missing front matter: #{file}" unless front
    data = YAML.safe_load(front[1], aliases: false)
    raise "Missing status: #{file}" unless data.is_a?(Hash) && data["status"].is_a?(String)
    data.fetch("status")
  end

end
