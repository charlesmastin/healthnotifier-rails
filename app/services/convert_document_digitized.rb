class ConvertDocumentDigitized

  def self.call(original_document_digitized)
    # add high level fault tolerance
    return unless original_document_digitized
    document_digitized = nil
    if original_document_digitized
      document_digitized = DocumentDigitized.new
      document_digitized.update_attributes(
        category:     original_document_digitized.category,
        title:        original_document_digitized.title,
        description:  original_document_digitized.description)
      document_digitized.save!
      part_number = 1
      original_document_digitized.document_digitized_files.each do |oddf|
        part_number += process_jpg(oddf, document_digitized, part_number) if 'JPG'.eql?(oddf.file_format)
        part_number += process_png(oddf, document_digitized, part_number) if 'PNG'.eql?(oddf.file_format)
        part_number += process_pdf(oddf, document_digitized, part_number) if 'PDF'.eql?(oddf.file_format)
      end
    end
    return document_digitized
  end

  def self.split_filename(filepath)
    filename = File.basename(filepath)
    ext = File.extname(filename)
    base = File.basename(filename, ext)
    return [filename, base, ext]
  end

  def self.process_jpg(original_document_digitized_file, document_digitized, next_part_number)
    document_digitized_file = document_digitized.document_digitized_files.new
    document_digitized_file.part_number = next_part_number
    document_digitized_file.file_format = 'JPG'
    document_digitized_file.file_spec = original_document_digitized_file.file_spec

    # get something
    data = S3Download.call(original_document_digitized_file.digitized_file_uid)
    # write it back
    key = document_digitized_file.generate_remote_path  
    S3Upload.call(key, data, {})
    document_digitized_file.digitized_file_uid = key
    # document_digitized_file.digitized_file = original_document_digitized_file.digitized_file.data
    document_digitized_file.save!
    # WTF mate, integer returns?
    return 1
  end

  def self.process_png(original_document_digitized_file, document_digitized, next_part_number)
    # WHY THE HECK ARE WE CONVERTING PNG to JPG??????
    original_file_spec = original_document_digitized_file.file_spec
    original_filename, basename, ext = split_filename(original_file_spec)
    jpg_filename = "#{basename}.jpg"

    data = S3Download.call(original_document_digitized_file.digitized_file_uid)
    png = Magick::Image.from_blob(data).first
    png.format = "PNG"
    jpg = png.to_blob { self.format = 'JPG' }
    document_digitized_file = document_digitized.document_digitized_files.new
    document_digitized_file.part_number = next_part_number
    document_digitized_file.file_format = 'JPG'
    document_digitized_file.file_spec = jpg_filename
    key = document_digitized_file.generate_remote_path  
    S3Upload.call(key, jpg, {})
    document_digitized_file.digitized_file_uid = key
    document_digitized_file.save!
    return 1
  end

  def self.process_pdf(original_document_digitized_file, document_digitized, next_part_number)
    original_file_spec = original_document_digitized_file.file_spec
    original_filename, basename, ext = split_filename(original_file_spec)
    pdf_pages = Magick::ImageList.new

    data = S3Download.call(original_document_digitized_file.digitized_file_uid)
    pdf_pages.from_blob(data) do
      self.quality = 100
      self.density = 300
    end
    i = 0
    pdf_pages.each do |pdf_page|
      jpg_filename = "#{basename}_#{i}.jpg"
      jpg = pdf_page.to_blob {
        self.format = 'JPG'
      }
      document_digitized_file = document_digitized.document_digitized_files.new
      document_digitized_file.part_number = (next_part_number + i)
      document_digitized_file.file_format = 'JPG'
      document_digitized_file.file_spec = jpg_filename

      key = document_digitized_file.generate_remote_path
      S3Upload.call(key, jpg, {})
      document_digitized_file.digitized_file_uid = key
      document_digitized_file.save!
      i += 1
    end
    return i
  end

end