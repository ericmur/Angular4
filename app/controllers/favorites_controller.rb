class FavoritesController < ApplicationController
  before_action :load_favorite, :only => [:destroy]
  before_action :load_user_password_hash, :only => [:index, :create, :bulk_create]
  
  def create
    @favorite = self.current_user.favorites.build(favorite_params)
    respond_to do |format|
      if @favorite.save
        format.json { render :json => @favorite }
      else
        format.json { render :json => { :errors => @favorite.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  def index
    respond_to do |format|
      format.json { render :json => self.current_user.favorites }
    end
  end

  def destroy
    @favorite.destroy
    respond_to do |format|
      format.json { render :nothing => true }
    end
  end

  def bulk_create
    errors = []
    @favorites = []
    ActiveRecord::Base.transaction do
      begin
        self.current_user.favorites.destroy_all
        if params[:favorite]
          favorite_params.each do |ps|
            favorite = self.current_user.favorites.build(each_favorite_params(ps))
            favorite.save!
            @favorites << favorite
          end
        end
      rescue Exception => e
        errors << e.message
        raise ActiveRecord::Rollback
      end
    end

    respond_to do |format|
      if errors.empty?
        format.json { render :json => @favorites }
      else
        format.json { render :json => { :errors => errors }, :status => :not_acceptable }
      end
    end
  end
  
  private

  def each_favorite_params(params)
    params.permit(:document_id, :rank)
  end

  def favorite_params
    if params[:action] == 'bulk_create'
      params.require(:favorite)
    else
      params.require(:favorite).permit(:document_id)
    end
  end

  def load_favorite
    @favorite = self.current_user.favorites.where(:id => params[:id]).first
  end
end
