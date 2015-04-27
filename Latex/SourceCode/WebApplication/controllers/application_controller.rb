class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  protected
  def authenticateUser
    if session[:operatorId]
      @current_operator = Operator.find(session[:operatorId])
      return true
    else
      flash[:alert] = "You are not authorised to access this page!"
      redirect_to(:controller => 'main', :action => 'index')
      return false
    end
  end

  def saveLoginState
    if session[:operatorId]
      redirect_to(:controller => 'main', :action => 'index')
      return false
    else
      return true
    end
  end

end
