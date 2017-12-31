class Book < ApplicationRecord
  include SearchCop

  search_scope :search do
    attributes :name, :description
  end

  search_scope :title_search do
    attributes :name
  end
end
