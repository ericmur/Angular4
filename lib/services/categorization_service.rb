require 'net/http'

class CategorizationService
  def initialize(document)
    @document = document
    @encryption_key = get_decrypted_key
  end

  def call
    unless ENV['WORK_OFFLINE']
      http = Net::HTTP.new(AutoCategorization.host, AutoCategorization.port)
      http.read_timeout = 300 #seconds
      req = Net::HTTP::Post.new(AutoCategorization.path)
      req.set_form_data({
                          "s3_object_name" => @document.original_file_key,
                          "encryption_key" => Base64.encode64(@encryption_key).chomp,
                          "document_id" => @document.id
                        })
      resp = http.request(req)
      
      unless resp.kind_of? Net::HTTPSuccess
        raise "AutoCategorization call failed with response: #{resp.inspect}"
        #Failed - raise exceptional error
        ##Do not cleanup here. We might want to run autocategorization job again
      end
    end
  end

  private
  
  def get_decrypted_key
    @document.symmetric_keys.for_user_access(nil).first.decrypt_key #Get Symmetric key shared with the system to access this document
  end
end
