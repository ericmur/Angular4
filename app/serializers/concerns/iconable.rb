require 'active_support/concern'

module Iconable
  extend ActiveSupport::Concern

  delegate :params, to: :scope

  def screen_scale
    @screen_scale = params[:scale].present? ? params[:scale].to_i : 3

    if @screen_scale < 1
      @screen_scale = 1
    elsif @screen_scale > 3
      @screen_scale = 3
    end

    @screen_scale
  end

  def icon_url
    icon_name  = iconable_object.read_attribute("icon_name_#{screen_scale}x")

    return nil if icon_name.blank?
    asset_name = "categories/#{icon_name}"
    asset_host = Rails.application.config.action_controller.asset_host
    asset_prefix = Rails.application.config.assets.prefix
    asset_digest_path = Rails.application.assets[asset_name].digest_path
    [asset_host, asset_prefix, '/', asset_digest_path].join('')
  end

  def icon_name
    icon_name  = iconable_object.read_attribute("icon_name_#{screen_scale}")
  end

end