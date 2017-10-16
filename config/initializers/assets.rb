# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0.4'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

Rails.application.config.assets.precompile << Proc.new { |path, fn| fn =~ /vendor\/assets/ && !%w(.js .css).include?(File.extname(path)) }

Rails.application.config.assets.precompile += %w( .rtf )

Rails.application.config.assets.precompile << /\.(?:svg|eot|woff|ttf)\z/

Rails.application.config.assets.precompile += %w( stubs.css )

Rails.application.config.assets.precompile += %w( stubs.js )

Rails.application.config.assets.precompile += %w( backbone_client.js )

Rails.application.config.assets.paths << Rails.root.join('vendor', 'assets', 'fonts')
