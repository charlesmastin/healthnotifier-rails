module PatientHelper

  def automaskDate(date, mask)
    result = date.strftime('%m/%d/%Y')

    if mask.present?
      if mask.index('MM').nil?
        result = date.strftime('%Y')
      elsif mask.index('DD').nil?
        result = date.strftime('%m/%Y')
      end
    end

    return result
  end

  def has_view_permission(obj, permission, privacy_attribute='privacy')
    return Patient::obj_has_view_permission(obj, permission, privacy_attribute)
  end

  def format_phone_html( phoneNum )
    # TODO: replace all dashes, spaces, add 1, etc
    # do we need +1, what if we already start with 1, etc
    return 'tel:%s' % [phoneNum]
  end

  def format_phone( phoneNum )
    extSplit = phoneNum.split(/x/)
    digits = extSplit[0].gsub(/[^\d]/, '')
    formatted = "";

    if(digits.length > 11)
          # User did something unexpected. BAIL!
      formatted = phoneNum;
     elsif digits.length > 10
      formatted = digits[0, 1] + ' (' + digits[1,3] + ') ' + digits[4, 3] + '-' + digits[7, digits.length];
     elsif digits.length > 7
      formatted = '(' + digits[0,3] + ') ' + digits[3, 3] + '-' + digits[6, digits.length];
     elsif digits.length > 3
      formatted = digits[0, 3] + '-' + digits[3, digits.length];
    end

    formatted += (extSplit.length > 1 ? ' x' + extSplit[1] : '');
  end

  # TODO: put this somewhere in DB? or something so it's classy and available in client too?
  def humanize_dd_category(category)
    Values.call('document').concat(Values.call('directive')).each do |cat|
      if category == cat[:value]
        return cat[:name]
      end
    end
    category
  end

  def privacy_label(privacy)
    Values.call('privacy').each do |p|
      if p[:value] == privacy
        return p[:name]
      end
    end
    return privacy
  end

  def privacy_tag(privacy)
    # returns the entire html snippet son, really a partial, really a js component
  end

end
