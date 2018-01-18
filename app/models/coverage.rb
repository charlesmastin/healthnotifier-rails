class Coverage < ApplicationRecord
  # attr_accessible :title, :body
  
  # Associations
  belongs_to :patient
  belongs_to :payment
  # http://stackoverflow.com/questions/4021322/belongs-to-through-associations
  delegate :lifesquare, :to => :patient, :allow_nil => false

  # TODO: enum on status
  # for transactional use, set to PENDING

  def coverage_reminder_required?(lead_time_in_days)
    today = Date.today
    date_to_start_reminders = self.coverage_end - lead_time_in_days.day
    cur_status = (self.coverage_status == 'ACTIVE')
    if cur_status
      return ((date_to_start_reminders <=> today) >= 0)
    end
    # Only get here if status is not active for whatever reason.  In the future, may want to use this
    # to trigger a "want to reactive your Lifesquare?" marketing email
    return cur_status
  end

end
