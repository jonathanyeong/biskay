class BskyUser < ApplicationRecord
  encrypts :app_password
  has_many :skeets
end
