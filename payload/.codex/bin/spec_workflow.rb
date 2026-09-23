#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "yaml"
require_relative "spec_repository"

class SpecWorkflow
  READY_STATUS = "ready-for-development"

  def initialize(root = File.expand_path("../..", __dir__))
    @root = root
    @repo = SpecRepository.new(root)
  end

  def run(args)
    command = args.shift

    case command
    when "setup"
      @repo.setup
      puts "Specification source: #{@repo.path}"
    when "sync"
      puts "Synced main: #{@repo.sync}"
    when "create"
      create_feature(args.shift, args.join(" "))
    when "status"
      task = task_file(args.shift)
      puts YAML.dump(
        "task" => task.delete_prefix(@repo.path + "/"),
        "task_status" => @repo.status(task),
        "checkout_commit" => @repo.git("rev-parse", "HEAD"),
        "checkout_changes" => @repo.git("status", "--short")
      )
    when "check-ready"
      task = task_file(args.shift)
      commit = @repo.sync
      status = @repo.status(task)
      raise "Task must have status: #{READY_STATUS}; got: #{status}" unless status == READY_STATUS
      puts YAML.dump(
        "task" => task.delete_prefix(@repo.path + "/"),
        "task_status" => status,
        "specification_commit" => commit
      )
    else
      raise usage
    end
  rescue StandardError => error
    warn "specification workflow error: #{error.message}"
    exit 1
  end

  private

  def create_feature(slug, title)
    @repo.validate!
    directory = @repo.feature(slug)
    spec = File.join(directory, "spec.md")
    raise "Feature already exists: #{slug}" if File.exist?(directory)

    title = slug.split("-").map(&:capitalize).join(" ") if title.empty?
    FileUtils.mkdir_p(directory)
    template = File.read(File.join(@repo.path, "templates", "feature.md"))
    template = template.sub(/^title:.*$/, "title: #{JSON.generate(title)}").sub(/^# Feature name$/, "# #{title}")
    File.write(spec, template)
    puts "Created draft specification: #{spec}"
  end

  def task_file(relative)
    @repo.validate!
    unless relative&.match?(%r{\Afeatures/[a-z0-9]+(?:-[a-z0-9]+)*/tasks/[0-9a-z][0-9a-z-]*\.md\z})
      raise "Use a repository-relative task path: features/SLUG/tasks/TASK.md"
    end

    file = File.join(@repo.path, relative)
    raise "Task cannot be a symlink: #{relative}" if File.symlink?(file)
    raise "Missing task: #{relative}" unless File.file?(file)
    raise "Task escapes specification checkout: #{relative}" unless File.realpath(file).start_with?(File.realpath(@repo.path) + "/")
    file
  end

  def usage
    "Usage: ruby .codex/bin/spec_workflow.rb setup | sync | create SLUG TITLE | status TASK_PATH | check-ready TASK_PATH"
  end
end

SpecWorkflow.new.run(ARGV) if $PROGRAM_NAME == __FILE__
