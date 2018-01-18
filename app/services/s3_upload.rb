# basic jw so we don't have to maintain a client instance all the time
class S3Upload
    
    def self.call(key, contents, metadata)
        begin
            s3 = Aws::S3::Client.new(
              access_key_id: Rails.application.config.aws_s3[:access_key_id],
              secret_access_key: Rails.application.config.aws_s3[:secret_access_key],
              region: Rails.application.config.aws_s3[:region]
            )
            if s3.put_object(
                bucket: Rails.application.config.aws_s3[:bucket_name],
                key: key,
                body: contents
                )
                return true
                # TODO: handle metadata son, yea son
            else
                # log, but yea, clean it up oh man, ruby town is bad these days
            end
        rescue
            # log
        end
        false
    end
end