require 'stripe'

class CreditCardService
  # Encapsulates Stripe:: inside this class, and avoid interacting with any other domain objects if possible
  # decided to accept customer_id vs customer objects, again to keep management inside this class

  def self.charge(customer_id, amount, description, metadata)
    begin
      # we simply to not support putting the source into here, because we will ALWAYS have a customer
      charge = Stripe::Charge.create(
        :customer => customer_id,
        :amount => amount,
        :description => description,
        :currency => 'usd',
        :metadata => metadata
      )
      return {
        :success => true,
        :charge => charge
      }
    rescue Stripe::CardError => e
      return {
        :success => false,
        :error => e.message
      }
    end
  end

  def self.update_charge(charge, props)
    ch = Stripe::Charge.retrieve(charge.id)
    # map the props dict into the stuffs
    ch.metadata['coverage_id'] = coverage.coverage_id
    ch.save
  end

  def self.create_subscription(customer_id, plan_id, quantity=1, metadata)
    # TODO: create or update, in the case of adding additional members?
    # one time pumpers
    begin
      subscription = Stripe::Subscription.create(
        :customer => customer_id,
        :plan => plan_id,
        :quantity => quantity,
        :metadata => metadata
      )
      return {
        :success => true,
        :subscription => subscription
      }
    rescue Stripe::CardError => e
      return {
        :success => false,
        :error => e.message
      }
    end


    # 2014 code
    # subscription = customer.subscriptions.create(:plan => subscription_id)
    # # this isn't super important to save on our side... because our payment has a reference to the customer, and we can look up the subscription
    # # TODO: look up that charge for first invoice in order to save our stuffs over here

    # invoices = Stripe::Invoice.all(
    #   :customer => customer.id,
    #   :limit => 3
    # )
    # """
    # line_item = Stripe::InvoiceItem.retrieve(invoices.data[0].lines.data[0].id)
    # """
    # # OR THIS IS CRAP, and get the last Charge on the customer, whatever
    # charges = Stripe::Charge.all(
    #   :customer => customer.id,
    #   :limit => 3
    # )

    # if invoices.data[0].charge == charges.data[0].id
    #   # something went wrong, maybe
    #   charge = charges.data[0]
    # end
  end

  def self.cancel_subscription(customer_id, subscription_id)
    begin
      subscription = Stripe::Subscription.retrieve(subscription_id)
      if subscription.delete
        return true
      end
    rescue
    end
    return false
    # exception handle this one son
    #subscription = customer.subscriptions.retrieve(subscription_id)
    #subscription.delete
    #return true
  end

  def self.create_or_update_customer(customer_id, email, source, metadata)
    # OR create customer
    if customer_id == nil

      # TODO: handle error validation fail times like, for example if Stripe already has this customer, but our db doesn't for some stupid reason
      begin
        customer = Stripe::Customer.create(
          :email => email,
          :source => source, # on creation this is always going to be a token for a card
          :description => "Customer for #{email}",
          :metadata => {
            :account_id => metadata[:account_id],
            :account_email => email,
            :first_name => metadata[:first_name],
            :last_name => metadata[:last_name]
          }
        )
      rescue Stripe::CardError, Stripe::InvalidRequestError, Stripe::AuthenticationError, Stripe::APIConnectionError, Stripe::StripeError => e
        return {
          :success => false,
          :error => e.message
        }
      rescue => e
        return {
          :success => false,
          :error => "Unkown Stripe Error"
        }
      end 
    else
      # what if this fails, but why would it, we had just checked the API in the previous controller line that calls this method
      begin
        customer = self.get_customer(customer_id)
        customer.description = "Customer for #{email}"
        customer.email = email
        customer.source = source # write it back, aka existing customer, new token, blablabla, blabla
        # merge the metadata over son
        customer.metadata = {
          :account_id => metadata[:account_id],
          :account_email => email,
          :first_name => metadata[:first_name],
          :last_name => metadata[:last_name]
        }
        customer.save
      rescue Stripe::CardError, Stripe::InvalidRequestError, Stripe::AuthenticationError, Stripe::APIConnectionError, Stripe::StripeError => e
        return {
          :success => false,
          :error => e.message
        }
      rescue => e
        return {
          :success => false,
          :error => "Unkown Stripe Error"
        }
      end
    end

    {
      :success => true,
      :customer => customer
    }
  end

  def self.get_customer(id)
    begin
      return Stripe::Customer.retrieve(id)
    rescue
      nil
    end
  end

  def self.get_plan(id)
    begin
      return Stripe::Plan.retrieve(id)
    rescue
      nil
    end
  end

  def self.get_plans
    return Stripe::Plan.list(:limit => 100)
  end

  def self.tokenize_card(card)
    # A UTIL FOR TESTING ONLY
    # IN PROD we use the js stripe tokenizer!!!!
    #
    #Stripe::Customer.create(
    #  :source => stripe_helper.generate_card_token({ :number => '4242424242424242', :brand => 'Visa' })
    #)

    #Stripe::Token.create({
    #  :customer => cus.id,
    #  :source => cus.sources.first.id
    #}, ENV['STRIPE_TEST_OAUTH_ACCESS_TOKEN'])
    token = Stripe::Token.create(:card => card)
    token.id
  end

end
