class Skeet < ApplicationRecord
  enum :status, { draft: "draft", scheduled: "scheduled", published: "published" }, default: :draft
  belongs_to :user
end
