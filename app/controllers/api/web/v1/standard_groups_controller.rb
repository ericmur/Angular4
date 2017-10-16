class Api::Web::V1::StandardGroupsController < Api::Web::V1::ApiController

  def index
    render status: 200, json: StandardGroup.all
  end

end
