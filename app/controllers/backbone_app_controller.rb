class BackboneAppController < ApplicationController
  protect_from_forgery with: :exception
  skip_before_action :doorkeeper_authorize!
  skip_before_action :confirm_phone!

  def app
    render text: "", layout: 'backbone_client'
  end

end
