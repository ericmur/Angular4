class ApplicationMailer < ActionMailer::Base
  include ActionView::Helpers::AssetUrlHelper
  default from: "notification@docyt.com"
  layout 'mailer'
  before_action :add_logo_attachment!
  helper :application

  def email_address_for(key)
    Rails.settings['emails'][key.to_s]
  end

  def get_logo_asset_url
    asset_name = "logo-150x39.png"
    asset_host = Rails.application.config.action_controller.asset_host
    asset_prefix = Rails.application.config.assets.prefix
    asset_digest_path = Rails.application.assets[asset_name].digest_path
    [asset_host, asset_prefix, '/', asset_digest_path].join('')
  end

  private

  def add_logo_attachment!
    attachments.inline["logo.png"] = File.read("#{Rails.root}/app/assets/images/logo-150x39.png")
  end

end
