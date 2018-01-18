module AdminHelper
  def get_provider_credentials_new_count
    # basic query on AR class
    return ProviderCredential.where(:status => 'PENDING').count 
  end

  def get_print_queue_new_count
    # basic query on AR class
    return CodeSheetPrintRequest.where(:status => 0).count
  end

  

end