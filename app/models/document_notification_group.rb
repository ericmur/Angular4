class DocumentNotificationGroup
  include Mongoid::Document
  include Mongoid::Timestamps
  field :user_id, type: Integer
  field :document_id, type: Integer
  field :notification_object_id, type: Integer
  field :notification_object_type, type: String
  field :method_name, type: String

  index({ user_id: 1 })
  index({ document_id: 1 })
  index({ notification_object_id: 1, notification_object_type: 1 })

  def user=(v)
    self.user_id = v.id
  end

  def user
    User.find(self.user_id) rescue nil
  end

  def document=(v)
    self.document_id = v.id
  end

  def document
    Document.find(self.document_id) rescue nil
  end

  def notification_object=(v)
    if v.respond_to?('id')
      self.notification_object_id = v.id
      self.notification_object_type = v.class.to_s
    else
      self.notification_object_id = nil
      self.notification_object_type = v
    end
  end

  def notification_object
    if self.notification_object_id
      self.notification_object_type.constantize.find(self.notification_object_id)
    else
      self.notification_object_type
    end
  end

  def invoke_notification_method
    self.document.send(self.method_name, self.user, self.notification_object) if self.document
  end
end
