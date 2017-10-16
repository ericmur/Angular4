class Api::Mobile::V2::AliasesController < Api::Mobile::V2::ApiController
  def index
    aliases_json = DocumentCacheService.new(current_user, params).get_aliases_json
    render status: 200, json: aliases_json
  end
end