class MainController < ApplicationController
  before_filter :saveLoginState, :only => [:login]

  SPEED_PAUSED = 0
  SPEED_SLOW = 1
  SPEED_NORMAL = 2
  SPEED_FAST = 3
  SPEED_VERY_FAST = 4

  def login
    operator = Operator.authenticate(params[:username], params[:password])
    if operator
      session[:operatorId] = operator.id
      session[:operatorUsername] = operator.username
      session[:operatorAdmin] = operator.admin
      flash[:success] = "Welcome again, you are logged in as #{operator.username}."
    else
      flash[:alert] = "Invalid Username or Password!"
    end
    redirect_to disruption_index_url, status: 301
  end

  def logout
    session[:operatorId] = nil
    session[:operatorUsername] = nil
    session[:operatorAdmin] = false
    flash[:success] = "You logged out successfully."
    redirect_to disruption_index_url, status: 301
  end

  def index
    redirect_to disruption_index_url, status: 301
  end

  def about
  end

  #Used for changing the speed for the thread responsible for simulations - TODO: Remove before putting into production
  def speed
    feedThreadPaused = EngineConfiguration.find("feedThreadPaused")
    feedThreadPaused.value = "false"
    feedThreadSpeedInMilliSeconds = EngineConfiguration.find("feedThreadSpeedInMilliSeconds")
    speed = Integer(params[:speed])
    if (speed == SPEED_SLOW)
      feedThreadSpeedInMilliSeconds.value = 10000
    elsif (speed == SPEED_FAST)
      feedThreadSpeedInMilliSeconds.value = 2500
    elsif (speed == SPEED_NORMAL)
      feedThreadSpeedInMilliSeconds.value = 5000
    elsif (speed == SPEED_VERY_FAST)
      feedThreadSpeedInMilliSeconds.value = 1000
    else
      feedThreadPaused.value = "true"
      feedThreadSpeedInMilliSeconds.value = 5000
    end
    feedThreadPaused.save
    feedThreadSpeedInMilliSeconds.save
    @return = {:success => true}
    render :json => ActiveSupport::JSON.encode(@return)
  end

end
