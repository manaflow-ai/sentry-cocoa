#!/usr/bin/env ruby
# frozen_string_literal: true

# Verify workflow token boundaries. Release mutations use a repository-scoped GitHub App token,
# while PR validation uses only read access to pull requests and write access to issue comments.

require 'optparse'
require 'pathname'
require 'yaml'

options = {
  workflow: Pathname(__dir__).join('..', '.github', 'workflows', 'release.yml').expand_path
}

OptionParser.new do |parser|
  parser.banner = 'Usage: test-workflow-permissions.rb [--workflow PATH]'
  parser.on('--workflow PATH', 'Workflow to verify (release.yml by default)') do |path|
    options[:workflow] = Pathname(path).expand_path
  end
end.parse!

abort "Unexpected arguments: #{ARGV.join(' ')}" unless ARGV.empty?

workflow_path = options[:workflow]
abort "Workflow not found: #{workflow_path}" unless workflow_path.file?

workflow = YAML.load_file(workflow_path)
jobs = workflow.fetch('jobs')
if workflow_path.basename.to_s == 'validate-pr.yml'
  validate_job = jobs.fetch('validate-pr')
  expected_permissions = {
    'contents' => 'read',
    'issues' => 'write',
    'pull-requests' => 'read'
  }
  unless validate_job.fetch('permissions') == expected_permissions
    abort "validate-pr permissions must be #{expected_permissions.inspect}, got #{validate_job.fetch('permissions').inspect}"
  end

  token_step = validate_job.fetch('steps').find { |step| step['id'] == 'app-token' }
  abort 'validate-pr must create a GitHub App token' unless token_step
  token_inputs = token_step.fetch('with')
  expected_token_permissions = {
    'repositories' => 'sentry-cocoa',
    'permission-issues' => 'write',
    'permission-metadata' => 'read',
    'permission-pull-requests' => 'read'
  }
  expected_token_permissions.each do |key, value|
    abort "GitHub App token input #{key} must be #{value.inspect}" unless token_inputs[key] == value
  end
elsif workflow_path.basename.to_s == 'changelog-preview.yml'
  changelog_job = jobs.fetch('changelog-preview')
  expected_permissions = {
    'contents' => 'read',
    'issues' => 'write',
    'pull-requests' => 'read'
  }
  unless changelog_job.fetch('permissions') == expected_permissions
    abort "changelog-preview permissions must be #{expected_permissions.inspect}, got #{changelog_job.fetch('permissions').inspect}"
  end

  checkout = changelog_job.fetch('steps').find do |step|
    step['uses'].to_s.start_with?('actions/checkout@')
  end
  abort 'changelog-preview must check out the base revision' unless checkout
  checkout_inputs = checkout.fetch('with')
  abort 'changelog-preview checkout must use the repository base SHA' unless checkout_inputs['ref'] == '${{ github.event.pull_request.base.sha }}'
  abort 'changelog-preview checkout must use the base repository' unless checkout_inputs['repository'] == '${{ github.repository }}'
  abort 'changelog-preview checkout must not persist credentials' unless checkout_inputs['persist-credentials'] == false

  abort 'changelog-preview must not inherit secrets' if changelog_job.fetch('secrets', nil)
else
  release_job = jobs.fetch('job_release')
  expected_permissions = {
    'actions' => 'read',
    'contents' => 'read'
  }
  unless release_job.fetch('permissions') == expected_permissions
    abort "job_release permissions must be #{expected_permissions.inspect}, got #{release_job.fetch('permissions').inspect}"
  end

  abort 'job_release must use the release environment' unless release_job['environment'] == 'release'

  steps = release_job.fetch('steps')
  token_step = steps.find { |step| step['id'] == 'token' }
  abort 'job_release must create a GitHub App token' unless token_step

  token_inputs = token_step.fetch('with')
  expected_token_permissions = {
    'repositories' => 'sentry-cocoa',
    'permission-contents' => 'write',
    'permission-issues' => 'write',
    'permission-pull-requests' => 'write'
  }

  expected_token_permissions.each do |key, value|
    abort "GitHub App token input #{key} must be #{value.inspect}" unless token_inputs[key] == value
  end

  checkout = steps.find do |step|
    step['uses'].to_s.start_with?('actions/checkout@') &&
      step.fetch('with', {})['token'] == '${{ steps.token.outputs.token }}'
  end
  abort 'job_release checkout must use the scoped App token' unless checkout
  abort 'job_release checkout must not persist credentials' unless checkout.fetch('with')['persist-credentials'] == false

  craft = steps.find { |step| step['uses'].to_s.start_with?('getsentry/craft@') }
  abort 'job_release must invoke Craft' unless craft
  unless craft.fetch('env', {})['GITHUB_TOKEN'] == '${{ steps.token.outputs.token }}'
    abort 'Craft must receive the scoped App token through GITHUB_TOKEN'
  end
end

puts "Workflow permission contract passed: #{workflow_path}"
