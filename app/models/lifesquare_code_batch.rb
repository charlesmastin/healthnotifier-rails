class LifesquareCodeBatch < ApplicationRecord
  # this currently only for managing bulk creation ahead of time
  # after_create :build_all_the_things we can't use that because we have to pass in a few things, o saucy, perhaps it should be in a service, hahahahaha sucka

  self.sequence_name = :seq_lifesquare_print_batch

  attr_readonly :lifesquare_code_batch_id, :create_date, :batch_size

  # Table relationships

  # Validations
  
  validates :batch_size, :presence => true, :numericality => { :only_integer => true, :less_than => 99999999, :greater_than => 0 }

  validates :notes, :length => {:maximum => 1000}

  # this was controller logic, but it's really model logic IMO which is really a post-save, but we need args
  def provision_lifesquares(account_id, campaign_id=nil, sheets_per_lifesquare=nil, instructions=nil)
      campaign = nil
      if campaign_id != nil
        campaign = Campaign.where(:campaign_id => campaign_id).first
      end

      codes_to_generate = self.batch_size

      # collect things for a print request to be added to the queue son
      # TODO: better way of establishing campaign and org to stick to the LSQ for printing
      # we had been umm, using the campaign as potential way for confirming some redemption pricing bs via promo codes
      # TODO: readdress the underlying business needs
      # balance between attribution and affordance / inclusion / membership bla bla
      printqueue = []

      # this is just unecessarily unecessary, ask Jerry why we would EVER want this, other than it provides some "free for life retries" on collisions
      while codes_to_generate > 0
        lifesquare_uid = Lifesquare.generate_code
        # verify it does not already exist
        # TODO: encapsulate retries into some module somewhere
        if Lifesquare.where(:lifesquare_uid => lifesquare_uid).count == 0
          lifesquare = Lifesquare.new()
          lifesquare.lifesquare_uid = lifesquare_uid
          lifesquare.create_user = account_id
          lifesquare.update_user = account_id
          lifesquare.batch_id = self.lifesquare_code_batch_id
          if campaign != nil
            lifesquare.campaign_id = campaign.campaign_id
          end
          if lifesquare.save
            printqueue.push(lifesquare.lifesquare_uid)
            codes_to_generate -= 1 # yea, without this you might have an infinite loop, at least until you OOM
          end
        end
      end

      # GHETTO PUMP YOUR CSPR into oblivion, disregard any node perf issues
      # TODO: SHARD THAT SHIZ into smaller chunks of trendy bite-sized stickers like 30 a pop or something
      # damn you ruby and .size and .length and all that inconsistencies wtf mate
      if printqueue.length > 0
        print_request = CodeSheetPrintRequest.add_new_request(printqueue.join(','), nil, 0)
        if print_request
          # attach our custom overrides inside the request though, unsure of conditions, so just save if we get anything here
          if sheets_per_lifesquare != nil
            print_request.sheets_per_lifesquare = sheets_per_lifesquare
            print_request.save
          end
          if instructions != nil
            print_request.instructions = instructions
            print_request.save
          end
          return true
        else
          return false
        end
      end

      return false

    end

end
