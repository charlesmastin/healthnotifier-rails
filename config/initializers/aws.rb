aws_s3_creds = YAML::load_file(Rails.root.join('config/credentials-local.yml'))['s3_picp']

Rails.configuration.aws_s3 = {
  :access_key_id => aws_s3_creds['access_key_id'],
  :secret_access_key => aws_s3_creds['secret_access_key'],
  :bucket_name => aws_s3_creds['bucket_name'],
  :region => aws_s3_creds['region']
}