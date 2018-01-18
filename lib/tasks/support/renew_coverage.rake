require 'optparse'

namespace :support do
  desc 'Utils for customer support tasks'
  task renew_coverage: :environment do

    options = {}
    opts = OptionParser.new
    opts.banner = "Usage: rake support:renew_coverage -- --campaign_id 1010101 --expiration '01-10-2018'"
    opts.on("-c", "--campaign_id ARG", Integer) { |a| options[:campaign_id] = a }
    opts.on("-e", "--expiration ARG", String) { |a| options[:expiration] = a }
    args = opts.order!(ARGV) {}
    opts.parse!(args)

    coverages = []

    # Ensure any claimed lifesquares in the campaign that don't have a connetion are wired up at that given level
    # This is kinda sketchy in terms of privacy, but it works.
    # perf not important for this particular op, for now, only claimed squares yup
    lifesquares = Lifesquare.where(:campaign_id => options[:campaign_id]).where.not(patient_id: nil)
    # go through each and check for an existing connection
    
    campaign = Campaign.where(:campaign_id => options[:campaign_id]).first

    coverage_end = Date.today + 365

    # attempt to pull it in son
    if options[:expiration] != nil
      begin
        coverage_end = Date.strptime(options[:expiration], '%d-%m-%Y')
      rescue
        puts "Invalid Coverage Format - Task Canceled"
        exit
      end
    end
    
    # ensure we have an active organization, or else things might get sticky

    lifesquares.each do |lsq|
      coverage = Coverage.new
      coverage.patient_id = lsq.patient_id
      coverage.coverage_start = Date.today
      coverage.coverage_end = coverage_end
      coverage.payment = nil # this is a one to many, aka many coverages have the same payment, yea son also, it's nullable
      coverage.recurring = false
      coverage.coverage_status = 'ACTIVE'
      if coverage.save
        coverages.push(coverage)
        puts "#{lsq.lifesquare_uid}"
      end
    end
    puts "-------"
    puts "We created #{coverages.length} coverages"
    exit
  end
end