class UserStatisticService
  def initialize(user)
    @user = user
  end

  def set_last_logged_in_web_app
    user_statistic = get_user_statistic
    user_statistic.last_logged_in_web_app = Time.zone.now
    user_statistic.save
  end

  def set_last_logged_in_iphone_app
    user_statistic = get_user_statistic
    user_statistic.last_logged_in_iphone_app = Time.zone.now
    user_statistic.save
  end

  def set_last_logged_in_alexa
    user_statistic = get_user_statistic
    user_statistic.last_logged_in_alexa = Time.zone.now
    user_statistic.save
  end

  private

  def get_user_statistic
    user_statistic = @user.user_statistic
    if user_statistic.blank?
      user_statistic = @user.build_user_statistic
    end
    user_statistic
  end
end
