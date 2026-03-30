require 'yaml'

lock '~> 3.19'

set :application, 'alaveteli'
set :git_enable_submodules, true

# rbenv – Ruby version stored server-side in shared/rbenv-version
set :rbenv_type, :user

# Shared files/dirs driven by Alaveteli's config/general.yml (read locally).
# NOTE: Capistrano 3 stores shared files at shared/<full-path> (e.g.
# shared/config/general.yml), whereas Capistrano 2 stored them at
# shared/<basename>. Existing servers need files moved before the first v3
# deploy – see docs/deployment.md for migration steps.
local_config = YAML.load_file('config/general.yml')
set :linked_files, Array(local_config['SHARED_FILES'])
set :linked_dirs,  Array(local_config['SHARED_DIRECTORIES']).map { |d| d.chomp('/') }

namespace :themes do
  desc 'Install Alaveteli themes'
  task :install do
    on roles(:app) do
      within release_path do
        execute :bundle, :exec, :rake, "themes:install RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
end

namespace :xapian do
  desc 'Rebuild Xapian index (PublicBody, User, InfoRequestEvent)'
  task :destroy_and_rebuild_index do
    on roles(:app) do
      within current_path do
        execute :bundle, :exec, :rake,
                "xapian:destroy_and_rebuild_index models='PublicBody User InfoRequestEvent' RAILS_ENV=#{fetch(:rails_env)}"
      end
    end
  end
end

namespace :deploy do
  [:start, :stop, :restart].each do |t|
    desc "#{t.to_s.capitalize} Alaveteli via /etc/init.d/"
    task t do
      on roles(:app) do
        execute "/etc/init.d/#{fetch(:daemon_name)} #{t}"
      end
    end
  end

  namespace :assets do
    desc 'Symlink non-digest asset paths to most recent digest versions'
    task :link_non_digest do
      on roles(:app) do
        within release_path do
          execute :bundle, :exec, :rake, "assets:link_non_digest RAILS_ENV=#{fetch(:rails_env)}"
        end
      end
    end
  end

  desc 'Enable maintenance page'
  task :maintenance_on do
    on roles(:web) do
      within current_path do
        execute :touch, 'public/system/maintenance.html'
      end
    end
  end

  desc 'Disable maintenance page'
  task :maintenance_off do
    on roles(:web) do
      within current_path do
        execute :rm, '-f', 'public/system/maintenance.html'
      end
    end
  end
end

before 'deploy:assets:precompile', 'themes:install'
after  'deploy:assets:precompile', 'deploy:assets:link_non_digest'

# Put up a maintenance notice if doing a migration which could take a while
before 'deploy:migrate', 'deploy:maintenance_on'
after  'deploy:migrate', 'deploy:maintenance_off'
