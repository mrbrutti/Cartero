module Cartero
module Commands
class Update < ::Cartero::Command
  def initialize
    super do |opts|

      opts.on("--update", "Update All") do
        @options.update = true
      end
      opts.on("--add", "Adds remote repository") do
        @options.add = true
      end

      opts.separator ""
      opts.separator "git options:"

      opts.on("-b", "--branch [BRANCH]", String,
      "Sets the repo/branch name to use for update") do |b|
        @options.branch = b
      end

      opts.on("-n", "--name REPO_NAME", String,
      "Sets the remote repository local name") do |n|
        @options.repo_name = n
      end
      opts.on("-u", "--url REPO_URL", String,
      "Sets the remote repository url") do |u|
        @options.repo_url = u
      end
    end
  end

  def setup
    @cartero_base_install = File.expand_path File.dirname __FILE__ + "/../../../../../../"
  end

  def run
    if @options.add
      puts "[*] - Adding remote Cartero repository to local git repository"
      system("git", "remote", "add", @options.repo_name, @options.repo_url)
    end
    if @options.update
      Dir.chdir(@cartero_base_install) do
        update_git(@options.branch)
        update_bundle
      end
    end
  end

  private
  def update_git(branch=nil)

    if branch
      r,b = branch.split("/")
      puts "[*] - Performing a diff against #{branch} Cartero git repository"
      system("git", "diff", branch, "--stat")
      puts "[*] - Updating Cartero from git repository"
      system("git", "reset", "--hard", "HEAD")
      system("git", "pull", r, b)
    else
      puts "[*] - Performing a diff against master Cartero git repository"
      system("git", "diff", "origin/master", "--stat")
      puts "[*] - Updating Cartero from git repository"
      system("git", "reset", "--hard", "HEAD")
      system("git", "pull")
    end
  end

  def update_bundle
    puts "[*] - Updating any possible new gem dependencies"
    require 'bundler'
    Bundler.with_clean_env do
      system("bundle", "install")
    end
  end
end
end
end
