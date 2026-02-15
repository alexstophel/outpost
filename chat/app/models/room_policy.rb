class RoomPolicy
  include ActiveModel::Model

  attr_reader :user, :room

  def initialize(user, room)
    @user = user
    @room = room
  end

  def admin?
    @user.admin_of?(@room)
  end

  def member?
    @user.member_of?(@room)
  end

  def can_join?
    !member? && @room.visibility_public_room?
  end

  def can_add_member?
    @room.visibility_public_room? || admin?
  end

  def can_remove_member?(membership)
    return false unless admin?
    return false if membership.user == @user # Use leave instead
    true
  end

  def can_leave?
    return false unless member?
    return false unless @room.membership_editable?

    membership = @user.membership_for(@room)
    # Can't leave as the only admin
    !(membership.admin? && @room.memberships.admins.count == 1)
  end

  def can_edit_membership?
    @room.membership_editable?
  end

  def can_delete?
    admin? && @room.deletable?
  end

  def can_view_settings?
    member? && @room.channel?
  end
end
