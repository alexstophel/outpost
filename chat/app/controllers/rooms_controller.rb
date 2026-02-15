class RoomsController < ApplicationController
  before_action :set_room, only: [:show, :destroy]
  before_action :require_room_admin, only: [:destroy]

  # GET /rooms - List joinable public rooms (JSON for browse modal)
  def index
    @rooms = Room.joinable_by(Current.user).order(:name)

    render json: @rooms.map { |room|
      {
        id: room.id,
        name: room.name,
        member_count: room.users.count
      }
    }
  end

  def show
    @messages = @room.messages.includes(:user).order(:created_at)
    @message = Message.new

    # Prepare sidebar data
    @channels = Current.user.channel_rooms
    @direct_messages = Current.user.direct_message_rooms.includes(:users)

    # Room members for settings
    @members = @room.memberships.includes(:user).order(:created_at)
    @is_admin = Current.user.admin_of?(@room)

    # Mark room as read
    Current.user.mark_room_as_read!(@room)
  end

  # POST /rooms - Create a new room
  def create
    @room = Room.new(room_params)
    @room.account = Current.user.account

    Room.transaction do
      @room.save!

      # Add creator as admin
      @room.memberships.create!(user: Current.user, role: :admin)

      # Add invited members
      if params[:member_ids].present?
        member_ids = Array(params[:member_ids]).map(&:to_i)
        Current.user.account_peers.where(id: member_ids).find_each do |user|
          @room.memberships.create!(user: user, role: :member)
        end
      end
    end

    redirect_to room_path(@room)
  rescue ActiveRecord::RecordInvalid => e
    redirect_back fallback_location: root_path, alert: e.record.errors.full_messages.join(", ")
  end

  # DELETE /rooms/:id - Delete a room (admin only)
  def destroy
    unless @room.deletable?
      redirect_to room_path(@room), alert: "The General room cannot be deleted."
      return
    end

    @room.destroy!
    redirect_to root_path, notice: "Room deleted."
  end

  private

  def set_room
    @room = Current.user.rooms.find(params[:id])
  end

  def require_room_admin
    unless Current.user.admin_of?(@room)
      redirect_to room_path(@room), alert: "You must be an admin to do that."
    end
  end

  def room_params
    params.require(:room).permit(:name, :visibility)
  end
end
