class DocumentExtensionService
  def initialize(mime_type, filename = nil)
    @filename  = filename
    @mime_type = mime_type
  end

  def pdf_file?
    MIME::Types.type_for('pdf').map(&:content_type).include?(@mime_type) or (@mime_type == 'application/octet-stream' and file_extension == "pdf")
  end

  def image_file?
    image_exts = ['jpg', 'jpeg', 'gif', 'png']
    image_exts.each do |ext|
      if @mime_type == "application/octet-stream"
        return true if image_exts.include?(file_extension)
      else
        return true if MIME::Types.type_for(ext).map(&:content_type).include?(@mime_type)
      end
    end
    false
  end

  def microsoft_file?
    microsoft_exts = ['doc', 'docx', 'ppt', 'pptm', 'pptx', 'ppsx', 'xlt', 'xls', 'xlsx']
    microsoft_exts.each do |ext|
      if @mime_type == "application/octet-stream"
        return true if microsoft_exts.include?(file_extension)
      else
        return true if MIME::Types.type_for(ext).map(&:content_type).include?(@mime_type)
      end
    end
    false
  end

  private
  def file_extension
    File.extname(@filename).delete('.').downcase
  end
end
