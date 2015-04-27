class SettingsController < ApplicationController
  before_filter :authenticateUser, :only => [:edit, :save, :index]

  def edit
    if (params[:id] != nil)
      @configs = EngineConfiguration.find_by_key(params[:id])
      render partial: "edit"
    else
      render text: "<h1>No configuration parameter specified</h1> <a class=\"close-reveal-modal\">&#215;</a>"
    end
  end

  def save
    if (params[:key] != nil)
      config = EngineConfiguration.find_by_key(params[:key])
      if config.editable
        config.value = params[:value]
        config.save
        result = {:error => false, :newValue => config.value, :key => params[:key]}
      else
        result = {:error => true, :errorText => "Field is not editable."}
      end
    else
      result ={:error => true, :errorText => "Some error occured."}
    end
    render :json => ActiveSupport::JSON.encode(result)
  end

  def index
    configs = EngineConfiguration.all.order(key: :desc)
    @configs = configs.paginate(:page => params[:page], :per_page => 20)
  end

end