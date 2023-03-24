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

gem_group :test do
    gem "capybara"
    gem "selenium-webdriver"
    gem "webdrivers"
end

gsub_file("Gemfile", '# gem "sassc-rails"', 'gem "sassc-rails"')

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

file "app/assets/stylesheets/application.scss", <<~TXT
  // Graphical variables
  @import "config/fonts";
  @import "config/colors";
  @import "config/bootstrap_variables";
  // External libraries
  @import "bootstrap";
  @import "font-awesome";
  // Your CSS partials
  @import "components/index";
TXT

file "app/assets/stylesheets/components/_index.scss", <<~TXT
  // Import your components CSS files here.
  @import "form_legend_clear";
TXT

file "app/assets/stylesheets/components/_form_legend_clear.scss", <<~TXT
  // In bootstrap 5 legend floats left and requires the following element
  // to be cleared. In a radio button or checkbox group the element after
  // the legend will be the automatically generated hidden input; the fix
  // in https://github.com/twbs/bootstrap/pull/30345 applies to the hidden
  // input and has no visual effect. Here we try to fix matters by
  // applying the clear to the div wrapping the first following radio button
  // or checkbox.
  legend ~ div.form-check:first-of-type {
    clear: left;
  }
TXT

file "app/assets/stylesheets/config/_fonts.scss", <<~TXT
  // Import Google fonts
  @import url('https://fonts.googleapis.com/css?family=Nunito:400,700|Work+Sans:400,700&display=swap');
  // Define fonts for body and headers
  $body-font: "Work Sans", "Helvetica", "sans-serif";
  $headers-font: "Nunito", "Helvetica", "sans-serif";
  // To use a font file (.woff) uncomment following lines
  // @font-face {
  //   font-family: "Font Name";
  //   src: font-url('FontFile.eot');
  //   src: font-url('FontFile.eot?#iefix') format('embedded-opentype'),
  //        font-url('FontFile.woff') format('woff'),
  //        font-url('FontFile.ttf') format('truetype')
  // }
  // $my-font: "Font Name";
TXT

file "app/assets/stylesheets/config/_colors.scss", <<~TXT
  // Define variables for your color scheme
  // For example:
  $red: #FD1015;
  $blue: #0D6EFD;
  $yellow: #FFC65A;
  $orange: #E67E22;
  $green: #1EDD88;
  $gray: #0E0000;
  $light-gray: #F4F4F4;
TXT

file "app/assets/stylesheets/config/_bootstrap_variables.scss", <<~TXT
  // This is where you override default Bootstrap variables
  // 1. All Bootstrap variables are here => https://github.com/twbs/bootstrap/blob/master/scss/_variables.scss
  // 2. These variables are defined with default value (see https://robots.thoughtbot.com/sass-default)
  // 3. You can override them below!
  // General style
  $font-family-sans-serif:  $body-font;
  $headings-font-family:    $headers-font;
  $body-bg:                 $light-gray;
  $font-size-base: 1rem;
  // Colors
  $body-color: $gray;
  $primary:    $blue;
  $success:    $green;
  $info:       $yellow;
  $danger:     $red;
  $warning:    $orange;
  // Buttons & inputs' radius
  $border-radius:    2px;
  $border-radius-lg: 2px;
  $border-radius-sm: 2px;
  // Override other variables below!
TXT

inject_into_file "config/initializers/assets.rb", after: "# Rails.application.config.assets.paths << Emoji.images_path" do
  <<~RUBY
    Rails.application.config.assets.paths << Rails.root.join("node_modules")
  RUBY
end

inject_into_file "config/initializers/assets.rb", after: "# Rails.application.config.assets.precompile += %w( admin.js admin.css )" do
  <<~RUBY
    Rails.application.config.assets.precompile += %w( application.scss )
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

  # Bootstrap / Popper
  ########################################
  append_file "config/importmap.rb", <<~RUBY
    pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.0/dist/esm/index.js"
    pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.2.0/dist/js/bootstrap.esm.js"
  RUBY

  append_file "app/javascript/application.js", <<~JS
    import "@popperjs/core"
    import * as bootstrap from "bootstrap"
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