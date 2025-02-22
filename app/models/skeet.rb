class Skeet < ApplicationRecord
  enum :status, { draft: "draft", scheduled: "scheduled", published: "published" }, default: :draft
end
