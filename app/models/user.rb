class User < ApplicationRecord
  encrypts :app_password
  has_many :sessions, dependent: :destroy
end
