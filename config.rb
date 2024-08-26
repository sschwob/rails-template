run "if uname | grep -q 'Darwin'; then pgrep spring | xargs kill -9; fi"

# Gemfile
########################################
inject_into_file "Gemfile", before: "group :development, :test do" do
  <<~RUBY
    gem 'rack-cors', '~> 1.1', '>= 1.1.1'
    gem "autoprefixer-rails"
    gem "font-awesome-sass", "~> 6.1"
    gem "simple_form", github: "heartcombo/simple_form"
    gem 'bootstrap', '~> 5.2.2'
    gem 'devise'
    gem 'devise-i18n'

  RUBY
end

inject_into_file "Gemfile", after: 'gem "debug", platforms: %i[ mri mingw x64_mingw ]' do
<<-RUBY

  gem 'dotenv-rails', '~> 2.7', '>= 2.7.6'
  gem 'byebug', '~> 9.0', '>= 9.0.5'
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
RUBY
end

# Configs
########################################
environment "config.sass.inline_source_maps = true", env: 'development'
run "rm -r tmp/cache/assets"
run "curl -L https://raw.githubusercontent.com/sschwob/rails-template/main/config/fr.yml > config/locales/fr.yml"

configs = <<~RUBY

  config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
  config.i18n.default_locale = :fr
  config.time_zone = "Paris"
  config.active_record.default_timezone = :local

RUBY

environment configs

# Assets
########################################
run "rm -rf app/assets/stylesheets"
run "rm -rf vendor"
run "curl -L https://github.com/lewagon/rails-stylesheets/archive/master.zip > stylesheets.zip"
run "unzip stylesheets.zip -d app/assets && rm -f stylesheets.zip && rm -f app/assets/rails-stylesheets-master/README.md"
run "mv app/assets/rails-stylesheets-master app/assets/stylesheets"

inject_into_file "config/initializers/assets.rb", before: "# Precompile additional assets." do
  <<~RUBY
    Rails.application.config.assets.paths << Rails.root.join("node_modules")
  RUBY
end

# Layout
########################################

gsub_file(
  "app/views/layouts/application.html.erb",
  '<meta name="viewport" content="width=device-width,initial-scale=1">',
  '<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">'
)

# Flashes
########################################
file "app/views/shared/_flashes.html.erb", <<~HTML
  <% if notice %>
    <div class="alert alert-info alert-dismissible fade show m-1" role="alert">
      <%= notice %>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close">
      </button>
    </div>
  <% end %>
  <% if alert %>
    <div class="alert alert-warning alert-dismissible fade show m-1" role="alert">
      <%= alert %>
      <button type="button" class="btn-close" data-bs-dismiss="alert" aria-label="Close">
      </button>
    </div>
  <% end %>
HTML

run "curl -L https://raw.githubusercontent.com/lewagon/awesome-navbars/master/templates/_navbar_wagon.html.erb > app/views/shared/_navbar.html.erb"

inject_into_file "app/views/layouts/application.html.erb", after: "<body>" do
  <<~HTML

    <%= render "shared/navbar" %>
    <%= render "shared/flashes" %>
  HTML
end

# README
########################################
markdown_file_content = <<~MARKDOWN
  Rails app generated with [sschwob/rails-template](https://github.com/sschwob/rails-template)
MARKDOWN
file "README.md", markdown_file_content, force: true

# Generators
########################################
generators = <<~RUBY
  config.generators do |generate|
    generate.assets false
    generate.helper false
    generate.test_framework :rspec, fixture: false
  end
RUBY

environment generators

########################################
# After bundle
########################################
after_bundle do
  # Generators: db + simple form + pages controller
  ########################################
  rails_command "db:drop db:create db:migrate"
  generate("simple_form:install", "--bootstrap")
  run "curl -L https://raw.githubusercontent.com/sschwob/rails-template/main/config/simple_form.fr.yml > config/locales/simple_form.fr.yml"
  generate(:controller, "pages", "home", "--skip-routes", "--no-test-framework")

  # Routes
  ########################################
  route 'root to: "pages#home"'

  # Gitignore
  ########################################
  append_file ".gitignore", <<~TXT
    # Ignore .env file containing credentials.
    .env*

    # Ignore Mac and Linux file system files
    *.swp
    .DS_Store
  TXT

  # Devise install
  ########################################
  generate("devise:install")
  generate("devise:i18n:views")
  run "curl -L https://raw.githubusercontent.com/sschwob/rails-template/main/config/devise.fr.yml > config/locales/devise.fr.yml"

  gsub_file(
    "app/views/devise/registrations/new.html.erb",
    "<%= simple_form_for(resource, as: resource_name, url: registration_path(resource_name)) do |f| %>",
    "<%= simple_form_for(resource, as: resource_name, url: registration_path(resource_name), data: { turbo: :false }) do |f| %>"
  )
  gsub_file(
    "app/views/devise/sessions/new.html.erb",
    "<%= simple_form_for(resource, as: resource_name, url: session_path(resource_name)) do |f| %>",
    "<%= simple_form_for(resource, as: resource_name, url: session_path(resource_name), data: { turbo: :false }) do |f| %>"
  )
  
  # Application controller
  ########################################
  run "rm app/controllers/application_controller.rb"
  file "app/controllers/application_controller.rb", <<~RUBY
    class ApplicationController < ActionController::Base
      # TODO : Remove comment after create devise user model
      # before_action :authenticate_user!
    end
  RUBY

  # Testing
  ########################################
  generate("rspec:install")
  run "mkdir 'spec/support'"
  run "touch 'spec/factories.rb'"
  
  append_file ".rspec", <<~TXT
    --format documentation
  TXT

  file "spec/support/factory_bot.rb", <<~RUBY
    RSpec.configure do |config|
      config.include FactoryBot::Syntax::Methods
    end
  RUBY

  file "spec/support/chrome.rb", <<~RUBY
    RSpec.configure do |config|
      config.before(:each, type: :system) do
        if ENV["SHOW_BROWSER"] == "true"
          driven_by :selenium_chrome
        else
          driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]
        end
      end
    end
  RUBY

  inject_into_file "spec/rails_helper.rb", after: "require 'spec_helper'" do
<<-RUBY
  require_relative 'support/factory_bot'
  require_relative 'support/chrome'
RUBY
  end

    # Environments
  ########################################
  environment 'config.action_mailer.default_url_options = { host: "http://localhost:3000" }', env: "development"
  environment 'config.action_mailer.default_url_options = { host: "http://TODO_PUT_YOUR_DOMAIN_HERE" }', env: "production"

  # Yarn
  ########################################
  run "yarn add bootstrap @popperjs/core"
  append_file "app/javascript/application.js", <<~JS
    import "bootstrap"
  JS

  # Dotenv
  ########################################
  run "touch '.env'"

  # Git
  ########################################
  git :init
  git add: "."
  git commit: "-m 'Initial commit with template from https://github.com/sschwob/rails-template'"
end
