require "./prunedocker/*"
require "cli"
require "habitat"

# TODO: Write documentation for `Prunedocker.cr`
module Prunedocker
  class Prunedocker < Cli::Command
    class Options
      string ["-r", "--repo"], required: true, desc: "Dockerhub repository"
      string ["-p", "--password"], required: true, desc: "Dockerhub password"
      string ["-u", "--user"], required: true, desc: "Dockerhub Login"
      string ["-k", "--keep"], required: true, desc: "Keeps k tags in the repo. Will delete the remaining older tags"
      bool "--dry-run", desc: "Just lists tags that will be dropped without actually dropping them"
      help
    end

    def run
      Prune.configure do
        settings.password = options.password
        settings.user = options.user
        settings.repository = options.repo
        settings.keep = options.keep.to_i
        if options.dry_run?
          settings.dry = true
        else
          settings.dry = false
        end
      end
      prune = Prune.new
      prune.run
    end
  end
end

Prunedocker::Prunedocker.run ARGV
Habitat.raise_if_missing_settings!
