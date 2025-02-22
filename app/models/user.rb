class User < ApplicationRecord
  has_many :sessions, dependent: :destroy
end
