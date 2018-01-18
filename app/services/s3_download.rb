class S3Download
    
    # default everything, just pass in the key
    # returns data as a blob

    # TODO: return a hash with the data, and the metadata in two keys
    # or nil
    def self.call(key)
        # TODO: hook caching here
        data = nil
        redis = nil
        if Rails.env == "development"
            require 'redis'
            begin
                redis = Redis.new
                data = redis.get(key)
                if data
                    return data
                end
            rescue
                redis = nil
                # meh
            end
        end

        begin
            s3 = Aws::S3::Client.new(
              access_key_id: Rails.application.config.aws_s3[:access_key_id],
              secret_access_key: Rails.application.config.aws_s3[:secret_access_key],
              region: Rails.application.config.aws_s3[:region]
            )

            resp = s3.get_object(
              bucket: Rails.application.config.aws_s3[:bucket_name],
              key: key
            )

            data = resp.body.read
        rescue
            # LOG IT
        end

        if Rails.env == "development"
            # cache da file if we lasted this long son
            unless redis.nil?
                redis.set(key, data)
            end
        end

        data

        #
        #unless redis.nil?
        #  redis.set(key, data)
        #end
    end
end