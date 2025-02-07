class User < ApplicationRecord
  # We don't need to add validations here because the validation will be done
  # on the BSKY api call
  has_secure_password :app_password, validations: false
  has_many :sessions, dependent: :destroy
end
