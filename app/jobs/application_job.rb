class ApplicationJob < ActiveJob::Base
    #https://inopinatus.org/2015/09/08/using-url-helpers-in-rails-activejob-background-jobs/
    #include Rails.application.routes.url_helpers

    #protected
    #def default_url_options
    #    Rails.application.config.active_job.default_url_options
    #end
end
