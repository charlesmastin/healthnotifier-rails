class AdminUser < ApplicationRecord

  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
##at need timeoutable, lockable and some kind of password strength checker for sure for admins
##at really should make this accessible only from inside the firewall (or at least from a limited set of IP's/hosts)
##at also should think about using some role-based auth for crud users
##at don't want rememerable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable,
         :authentication_keys => [:email]

  # Setup accessible (or protected) attributes for your model
  # attr_accessible :email, :password, :password_confirmation, :remember_me,
  #   :as => [:default, :admin]
end
