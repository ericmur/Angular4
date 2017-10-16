class PageSerializer < ActiveModel::Serializer
  attributes :id, :page_num, :name, :document_id, :state, 
    :s3_object_key, :original_s3_object_key, :version, 
    :final_file_md5, :original_file_md5, :latitude, :longitude

  def location
    @location ||= self.object.locations.order(id: :asc).last
  end

  def latitude
    location.latitude if location
  end

  def longitude
    location.longitude if location
  end
end
