class Operator < ActiveRecord::Base
  self.table_name = "Operators"
  has_many :disruption_comments, :class_name => "DisruptionComment", :foreign_key => "operatorId", :primary_key => "id"

  def self.authenticate(user="", logingPassword="")
    user = Operator.find_by(username: user)
    if user && user.match_password(logingPassword)
      return user
    else
      return false
    end
  end

  def match_password(logingPassword="")
    return logingPassword == self.password
    #TODO:Add encryption before putting into production
    # encrypted_password == BCrypt::Engine.hash_secret(password, salt)
  end

end