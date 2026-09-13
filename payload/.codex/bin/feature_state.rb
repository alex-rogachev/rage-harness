#!/usr/bin/env ruby
# frozen_string_literal: true
require "json"
require "time"
require_relative "spec_repository"

class FeatureState
  def initialize(root = File.expand_path("../..", __dir__))
    @root = root
    @local = File.join(root, ".codex", "features")
    @current = File.join(@local, "current")
    @repo = SpecRepository.new(root)
  end

  def save(path, data)
    FileUtils.mkdir_p(File.dirname(path))
    temporary = "#{path}.tmp-#{Process.pid}"
    File.write(temporary, data)
    File.rename(temporary, path)
  ensure
    File.delete(temporary) if temporary && File.exist?(temporary)
  end

  def run(args)
    command = args.shift
    case command
    when "setup"
      @repo.setup
      puts "Specification source: #{@repo.path}"
      return
    when "sync"
      puts "Synced main: #{@repo.sync}"
      return
    when "create", "activate"
      @repo.validate!
      slug = args.shift
      directory = @repo.feature(slug)
      spec = File.join(directory, "spec.md")
      state_path = File.join(@local, slug, "state.yml")
      if File.exist?(state_path)
        existing = YAML.safe_load(File.read(state_path), aliases: false)
        raise "Legacy local feature exists. Migrate deliberately; see WORKFLOW_REFERENCE.md" unless existing["version"] == 2
      end
      if command == "create" && !File.exist?(directory)
        title = args.join(" ")
        title = slug.split("-").map(&:capitalize).join(" ") if title.empty?
        FileUtils.mkdir_p(directory)
        template = File.read(File.join(@repo.path, "templates", "feature.md"))
        template = template.sub(/^title:.*$/, "title: #{JSON.generate(title)}").sub(/^# Feature name$/, "# #{title}")
        save(spec, template)
      end
      raise "Missing canonical feature: #{spec}" unless File.file?(spec)
      unless File.exist?(state_path)
        FileUtils.mkdir_p(File.join(@local, slug, "evidence"))
        save(state_path, YAML.dump({"version" => 2, "feature" => slug, "phase" => "draft",
          "spec_path" => spec, "repository" => SpecRepository::URL, "task" => nil,
          "spec_sha256" => @repo.digest, "review" => {}, "approval" => {},
          "implementation" => {"paused_for_spec_gap" => false}, "verification" => {}}))
      end
      save(@current, slug + "\n")
      puts "Active feature: #{slug}; canonical document: #{spec}"
      return
    end

    raise usage unless command
    raise "No active feature; run activate FEATURE or create FEATURE TITLE" unless File.file?(@current)
    slug = File.read(@current).strip
    directory = @repo.feature(slug)
    state_path = File.join(@local, slug, "state.yml")
    state = YAML.safe_load(File.read(state_path), aliases: false)
    raise "Legacy local feature state: migrate explicitly using WORKFLOW_REFERENCE.md" unless state["version"] == 2
    spec = File.join(directory, "spec.md")
    phase = state.fetch("phase")
    raise "Invalid local phase" unless %w[draft approved implementing verified].include?(phase)
    if command == "current"
      puts slug
      return
    elsif command == "status"
      puts YAML.dump(state.merge("canonical_status" => @repo.status(spec), "current_sha256" => @repo.digest,
        "checkout_commit" => @repo.git("rev-parse", "HEAD"), "checkout_changes" => @repo.git("status", "--short")))
      return
    end

    case command
    when "select-task"
      raise "Reopen before selecting another task" unless phase == "draft"
      task = args.shift.to_s
      raise "Use a task filename under tasks/" unless /\A[0-9a-z][0-9a-z-]*\.md\z/.match?(task)
      raise "Missing task #{task}" unless File.file?(File.join(directory, "tasks", task))
      state["task"] = task
      state["approval"] = {}
      state["review"] = {}
    when "refresh"
      raise "Refresh requires draft" unless phase == "draft"
      state["spec_sha256"] = @repo.digest
      state["review"]["stale"] = state.dig("review", "reviewed_sha256") != state["spec_sha256"]
    when "record-review"
      verdict, report = args
      raise "Use ready, revisions_required, or blocked" unless %w[ready revisions_required blocked].include?(verdict)
      state["review"] = {"verdict" => verdict, "report_path" => evidence!(slug, report),
        "reviewed_sha256" => @repo.digest, "reviewed_at" => Time.now.utc.iso8601, "stale" => false}
    when "approve", "begin-implementation", "verify", "resume"
      expected = {"approve" => "draft", "begin-implementation" => "approved", "verify" => "implementing", "resume" => "implementing"}.fetch(command)
      raise "Expected #{expected}, got #{phase}" unless phase == expected
      # Fetch published main at each boundary; never silently use offline or
      # unpublished specifications as the implementation authority.
      commit = @repo.sync
      hash = @repo.digest
      raise "Canonical feature must have status: implementation" unless @repo.status(spec) == "implementation"
      raise "Select an incomplete task first" unless state["task"]
      raise "Selected task is not todo" unless @repo.status(File.join(directory, "tasks", state["task"])) == "todo"
      if command == "approve"
        raise "Published specification changed since inspection. Read it, refresh, then approve explicitly" unless state["spec_sha256"] == hash
        state["approval"] = {"approved_sha256" => hash, "approved_at" => Time.now.utc.iso8601, "commit" => commit, "task" => state["task"]}
        state["phase"] = "approved"
      else
        raise "Specification context changed; reopen, review changes, and approve again" unless state.dig("approval", "approved_sha256") == hash && state.dig("approval", "task") == state["task"]
        raise "Resolve the specification gap first" if command != "resume" && state.dig("implementation", "paused_for_spec_gap")
        if command == "begin-implementation"
          state["phase"] = "implementing"
        elsif command == "resume"
          raise "No paused gap" unless state.dig("implementation", "paused_for_spec_gap")
          state["implementation"]["paused_for_spec_gap"] = false
        else
          state["phase"] = "verified"
          state["verification"] = {"verified_sha256" => hash, "verified_at" => Time.now.utc.iso8601, "task" => state["task"]}
        end
      end
      state["spec_sha256"] = hash
    when "report-gap"
      raise "Report a gap during implementing" unless phase == "implementing"
      state["implementation"] = {"paused_for_spec_gap" => true, "gap_report_path" => evidence!(slug, args.shift)}
    when "reopen"
      state["phase"] = "draft"
      state["approval"] = {}
      state["last_verification"] = state["verification"] unless state["verification"].empty?
      state["verification"] = {}
      state["implementation"]["paused_for_spec_gap"] = false
      state["revision_reason"] = args.join(" ")
    else
      raise usage
    end
    state["updated_at"] = Time.now.utc.iso8601
    save(state_path, YAML.dump(state))
    puts "#{command}: #{slug}; local phase #{state['phase']}. Canonical documents were not modified."
  rescue StandardError => error
    warn "feature state error: #{error.message}"
    exit 1
  end

  def evidence!(slug, supplied)
    raise "Report path is required" unless supplied
    file = File.expand_path(supplied, @root)
    base = File.join(@local, slug, "evidence")
    raise "Report must exist under #{base}" unless File.file?(file) && File.realpath(file).start_with?(File.realpath(base) + "/")
    file
  end

  def usage
    "Usage: ruby .codex/bin/feature_state.rb setup | sync | create SLUG TITLE | activate SLUG | select-task FILE.md | current | status | refresh | record-review VERDICT REPORT | approve | begin-implementation | report-gap REPORT | reopen REASON | resume | verify"
  end
end

FeatureState.new.run(ARGV) if $PROGRAM_NAME == __FILE__
