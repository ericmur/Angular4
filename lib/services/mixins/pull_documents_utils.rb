module Mixins::PullDocumentsUtils

  def is_allowed_content_type?(mime_type)
    mime_type == 'application/pdf' || (mime_type.start_with?('image/') && mime_type != 'image/gif')
  end

end
