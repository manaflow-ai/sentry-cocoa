#!/usr/bin/env ruby
# frozen_string_literal: true

# Verify the release workflow's token boundary. The release job must use a read-only
# GITHUB_TOKEN and a repository-scoped GitHub App token for mutations.

require 'optparse'
require 'pathname'
require 'yaml'

options = {
  workflow: Pathname(__dir__).join('..', '.github', 'workflows', 'release.yml').expand_path
}

OptionParser.new do |parser|
  parser.banner = 'Usage: test-workflow-permissions.rb [--workflow PATH]'
  parser.on('--workflow PATH', 'Release workflow to verify') do |path|
    options[:workflow] = Pathname(path).expand_path
  end
end.parse!

abort "Unexpected arguments: #{ARGV.join(' ')}" unless ARGV.empty?

workflow_path = options[:workflow]
abort "Workflow not found: #{workflow_path}" unless workflow_path.file?

workflow = YAML.load_file(workflow_path)
jobs = workflow.fetch('jobs')
release_job = jobs.fetch('job_release')
permissions = release_job.fetch('permissions')

expected_permissions = {
  'actions' => 'read',
  'contents' => 'read'
}

unless permissions == expected_permissions
  abort "job_release permissions must be #{expected_permissions.inspect}, got #{permissions.inspect}"
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

puts "Workflow permission contract passed: #{workflow_path}"
