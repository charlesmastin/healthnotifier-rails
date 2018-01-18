require 'optparse'

namespace :support do
  desc 'Utils for customer support tasks'
  task force_connections: :environment do

    options = {}
    opts = OptionParser.new
    opts.banner = "Usage: rake support/force_connections -- --campaign_id 1010101 --patient_id 1010202 --privacy provider"
    opts.on("-c", "--campaign_id ARG", Integer) { |a| options[:campaign_id] = a }
    opts.on("-p", "--patient_id ARG", Integer) { |a| options[:patient_id] = a }
    opts.on("-l", "--privacy ARG", String) { |a| options[:privacy] = a }
    args = opts.order!(ARGV) {}
    opts.parse!(args)

    # Ensure any claimed lifesquares in the campaign that don't have a connetion are wired up at that given level
    # This is kinda sketchy in terms of privacy, but it works.
    # perf not important for this particular op, for now, only claimed squares yup
    lifesquares = Lifesquare.where(:campaign_id => options[:campaign_id]).where.not(patient_id: nil)
    # go through each and check for an existing connection
    connections = []
    campaign = Campaign.where(:campaign_id => options[:campaign_id]).first

    auditor_patient = Patient.where(:patient_id => options[:patient_id]).first
    # ensure we have an active organization, or else things might get sticky

    lifesquares.each do |lsq|
      raw_connection = PatientNetwork.where(:auditor_patient_id => options[:patient_id], :granter_patient_id => lsq.patient_id).first
      connection = nil
      if raw_connection == nil
        new_connection = PatientNetwork.create(
          :auditor_patient_id => options[:patient_id],
          :granter_patient_id => lsq.patient_id,
          :privacy => options[:privacy],
          :asked_at => Time.now,
          :joined_at => Time.now,
          :request_reason => 'Campaign TOS'
        )
        connection = new_connection
        puts "#{lsq.lifesquare_uid}"
        connections.push(connection)
      elsif raw_connection.joined_at == nil
        raw_connection.joined_at = Time.now
        raw_connection.request_reason = 'Campaign TOS'
        raw_connection.save
        puts "#{lsq.lifesquare_uid}"
        connection = raw_connection
        connections.push(connection)
      end

      # invoke mailers
      # patient_network/mailer/granter_auto_connection
      if connection != nil

        AccountMailer.send_email(
          connection.granter_patient.account.email,
          "Lifesquare patient network connection auto-created",
          'patient_network/mailer/granter_auto_connection',
          {:connection => connection, :organization => campaign.organization }
        ).deliver_now

      end      

    end

    # summary mailer to auditor
    if connections.length > 0
      AccountMailer.send_email(
        auditor_patient.account.email,
        "Lifesquare patient network connection auto-created",
        'patient_network/mailer/auditor_auto_connections',
        {:connections => connections}
      ).deliver_now
    end


    puts "We created/updated #{connections.length} connections"
    exit
  end
end