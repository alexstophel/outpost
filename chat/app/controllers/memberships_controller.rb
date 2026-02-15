class MembershipsController < ApplicationController
  before_action :set_room
  before_action :set_policy
  before_action :set_membership, only: [ :destroy ]
  before_action :require_editable_membership

  # POST /rooms/:room_id/memberships - Add a member (admin only, or join public room)
  def create
    if @policy.can_join?
      join_room
    elsif @policy.admin?
      add_member
    else
      redirect_to room_path(@room), alert: "You don't have permission to add members."
    end
  end

  # DELETE /rooms/:room_id/memberships/:id - Remove member or leave room
  def destroy
    if @membership.user == Current.user
      leave_room
    elsif @policy.can_remove_member?(@membership)
      remove_member
    else
      redirect_to room_path(@room), alert: "You don't have permission to remove members."
    end
  end

  private

  def set_room
    @room = Current.user.account.rooms.find(params[:room_id])
  end

  def set_policy
    @policy = RoomPolicy.new(Current.user, @room)
  end

  def set_membership
    @membership = @room.memberships.find(params[:id])
  end

  def require_editable_membership
    unless @policy.can_edit_membership?
      redirect_to room_path(@room), alert: "Membership cannot be changed for the General room."
    end
  end

  def join_room
    @room.memberships.create!(user: Current.user, role: :member)
    redirect_to room_path(@room), notice: "You've joined #{@room.name}."
  end

  def add_member
    user = Current.user.account_peers.find(params[:user_id])

    if user.member_of?(@room)
      head :unprocessable_entity
    else
      @room.memberships.create!(user: user, role: :member)
      head :ok
    end
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end

  def leave_room
    if @policy.can_leave?
      @membership.destroy!
      redirect_to root_path, notice: "You've left #{@room.name}."
    else
      redirect_to room_path(@room), alert: "You can't leave as the only admin. Delete the room or promote another admin first."
    end
  end

  def remove_member
    @membership.destroy!
    head :ok
  end
end
