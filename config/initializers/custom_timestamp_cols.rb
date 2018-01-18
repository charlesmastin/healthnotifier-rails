# Hack to override the default create/update auto timestamp cols

module ActiveRecord
  module Timestamp      
    private
    def timestamp_attributes_for_update #:nodoc:
      [:updated_at, :updated_on, :last_update]
    end
    def timestamp_attributes_for_create #:nodoc:
      [:created_at, :created_on, :create_date]
    end      
  end
end
