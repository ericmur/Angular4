require 'fileutils'

namespace :theme do
  def copy_assets(regexp)
    Rails.application.assets.each_logical_path(regexp) do |name, path|
      asset = Rails.root.join('public', 'assets', name.gsub(/salient\//,''))
      FileUtils.mkdir_p(File.dirname(asset))
      FileUtils.cp path, asset
    end
  end

  desc 'Copy assets, that cant be used with digest'
  task nondigest: :environment do
    copy_assets /.+png/
    copy_assets /.+jpg/
    copy_assets /.+jpeg/
    copy_assets /.+gif/
    copy_assets /.+gif/
    copy_assets /.+eot/
    copy_assets /.+svg/
    copy_assets /.+ttf/
    copy_assets /.+woff/
  end
end

# Based on rake task from asset_sync gem
if Rake::Task.task_defined?("assets:precompile")
  Rake::Task["assets:precompile"].enhance do
    Rake::Task["theme:nondigest"].invoke # if defined?(Ckeditor) && Ckeditor.run_on_precompile?
  end
end