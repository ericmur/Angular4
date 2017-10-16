class Api::Web::V1::ConsumerAccountTypesController < Api::Web::V1::ApiController

  def index
    render status: 200, json: ConsumerAccountType.all
  end

end
