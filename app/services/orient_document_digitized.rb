class OrientDocumentDigitized

  # aka orient JPG only, this is pretty memory intensive, but oh well, it's a crutch
  def self.call(binary_data)
    # this is a util, and we could insert it into the input converstion pipeline for saving future things
    # and the output pipeline for correcting past mistakes, without raking through them all, which we should
    # perhaps do if we're more certain about this
    # if we have no orientation data, pass it through
    begin
      exif = EXIFR::JPEG.new(StringIO.new(binary_data)).exif
      if exif && exif.orientation && ([3,6,8].include? exif.orientation.to_i)
        # avoid hitting it unless we know it's a crappy rotation
        # this is probably, but not proven to be more memory intensive, so avoid if we can
        rotated = Magick::Image.from_blob(binary_data).first.auto_orient!
        #  If the image does not have an orientation tag, or the image is already properly oriented,
        # then auto_orient! returns nil.
        if rotated
          binary_data = rotated.to_blob { self.format = 'JPG' }
        end
      end
    rescue
    end
    binary_data
  end

end