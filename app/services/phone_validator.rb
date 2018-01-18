# number validator
class PhoneValidator
    def self.call(value)
        # for now, accept only with +, responsibility up the chain to format the +
        begin
            @client = Twilio::REST::LookupsClient.new(
              Rails.configuration.twilio[:account_sid],
              Rails.configuration.twilio[:auth_token]
            )
            number = @client.phone_numbers.get(value, type: 'carrier')
            if number.phone_number != nil
                return number
            end
            return nil
        rescue Twilio::REST::RequestError => e
            # pass
            # TODO: log somewhere
            return nil
        end
    end

    def self.call_callerid(value)
        begin
            lookups_client = Twilio::REST::LookupsClient.new(
              Rails.configuration.twilio[:account_sid],
              Rails.configuration.twilio[:auth_token]
            )
            query = lookups_client.phone_numbers.get(value, type: 'caller-name')
            if query.caller_name && query.caller_name['caller_name']
              return query.caller_name['caller_name']
            end
            return nil
        rescue Twilio::REST::RequestError => e
            # pass
            # TODO: log somewhere
            return nil
        end
    end
end