class Skeet < ApplicationRecord
  enum :status, { draft: "draft", scheduled: "scheduled", posted: "posted" }, default: :draft
  belongs_to :user
end
