class UserSearchesController < ApplicationController
  before_action :require_authentication

  def index
    @users = Current.user.account_peers
      .search_by_name(params[:q])
      .limit(10)

    render json: @users.map { |user|
      {
        id: user.id,
        name: user.name,
        avatar_url: user.avatar.attached? ? url_for(user.avatar.variant(resize_to_fill: [40, 40])) : nil
      }
    }
  end
end
