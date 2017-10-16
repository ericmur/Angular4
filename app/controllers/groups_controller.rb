class GroupsController < ApplicationController
  def create
    @group = self.current_user.groups_as_owner.build(group_params)
    if @group.save
      respond_to do |format|
        format.json { render :json => @group, :status => :ok }
      end
    else
      respond_to do |format|
        format.json { render :json => { :errors => @group.errors.full_messages }, :status => :not_acceptable }
      end
    end
  end

  private
  def group_params
    params.require(:group).permit(:standard_group_id)
  end
end
