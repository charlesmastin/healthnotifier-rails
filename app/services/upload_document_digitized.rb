require 'base64'
require 'aws-sdk'

class UploadDocumentDigitized

  def self.call(document_info)
    return unless document_info
    document_digitized = DocumentDigitized.new
    document_digitized.update_attributes(
      category:     document_info['category'],
      title:        document_info['title'],
      description:  document_info['description'])
    document_digitized.save!

    document_info['files'].each_with_index do |document_file, i|
      filename, base, ext = split_filename(document_file['name'])
      file_format = ext.delete('.').upcase
      # TODO: rename 'file' to 'contents_base64'
      decoded_contents = Base64.decode64(document_file['file'])
      document_digitized_file = document_digitized.document_digitized_files.new
      document_digitized_file.part_number = i+1
      document_digitized_file.file_format = file_format
      document_digitized_file.file_spec = filename
      # document_digitized_file.digitized_file = decoded_contents
      # upload to s3 now, son, save the path to 
      key = document_digitized_file.generate_remote_path
      # temp file on disk, for temp town times
      S3Upload.call(key, decoded_contents, {})
      document_digitized_file.digitized_file_uid = key
      document_digitized_file.save!
    end
    return document_digitized
  end

  def self.split_filename(filepath)
    filename = File.basename(filepath)
    ext = File.extname(filename)
    base = File.basename(filename, ext)
    return [filename, base, ext]
  end

end
