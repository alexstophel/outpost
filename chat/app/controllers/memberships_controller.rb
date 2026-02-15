class MembershipsController < ApplicationController
  before_action :set_room
  before_action :set_membership, only: [:destroy]
  before_action :require_editable_membership

  # POST /rooms/:room_id/memberships - Add a member (admin only, or join public room)
  def create
    if @room.visibility_public_room?
      # Anyone can join a public room
      join_room
    elsif Current.user.admin_of?(@room)
      # Admin adding a member to private room
      add_member
    else
      redirect_to room_path(@room), alert: "You don't have permission to add members."
    end
  end

  # DELETE /rooms/:room_id/memberships/:id - Remove member or leave room
  def destroy
    if @membership.user == Current.user
      # User leaving the room
      leave_room
    elsif Current.user.admin_of?(@room)
      # Admin removing a member
      remove_member
    else
      redirect_to room_path(@room), alert: "You don't have permission to remove members."
    end
  end

  private

  def set_room
    @room = Room.find(params[:room_id])
  end

  def set_membership
    @membership = @room.memberships.find(params[:id])
  end

  def require_editable_membership
    unless @room.membership_editable?
      redirect_to room_path(@room), alert: "Membership cannot be changed for the General room."
    end
  end

  def join_room
    if Current.user.member_of?(@room)
      redirect_to room_path(@room), notice: "You're already a member of this room."
    else
      @room.memberships.create!(user: Current.user, role: :member)
      redirect_to room_path(@room), notice: "You've joined #{@room.name}."
    end
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
    # Don't let the last admin leave
    if @membership.admin? && @room.memberships.admins.count == 1
      redirect_to room_path(@room), alert: "You can't leave as the only admin. Delete the room or promote another admin first."
    else
      @membership.destroy!
      redirect_to root_path, notice: "You've left #{@room.name}."
    end
  end

  def remove_member
    # Can't remove yourself via this path (use leave instead)
    if @membership.user == Current.user
      redirect_to room_path(@room), alert: "Use 'Leave Room' to remove yourself."
    else
      @membership.destroy!
      head :ok
    end
  end
end
