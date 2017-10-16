class AccountLimitSerializer < ActiveModel::Serializer
  attributes :total_storage_size, :total_pages_count, :limit_storage_size, :limit_pages_count, :errors
end
