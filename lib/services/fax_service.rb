class FaxService

  def initialize(fax_id)
    @fax = Fax.find(fax_id)
  end

  def download_document_and_send_fax
    tmp_file = download_document
    send_fax(tmp_file) if tmp_file
  end

  def self.search_sending_faxes_and_update_status
    faxes = Fax.where(status: 'sending')

    return unless faxes.any?

    faxes.find_each do |fax|
      phaxio = Phaxio.get_fax_status(id: fax.phaxio_id)

      if phaxio.parsed_response['success']
        fax.complete_sent
        fax.update(status_message: phaxio.parsed_response['message'])
      end
    end

  end

  private

  def download_document
    if @fax
      file_location = "#{Rails.root}/tmp/#{@fax.document.original_file_key}"
      encrypt_key = @fax.document.symmetric_keys.for_user_access(nil).first.decrypt_key

      S3::DataEncryption.new(encrypt_key).download(@fax.document.original_file_key, file_location)

      File.new(file_location)
    end
  end

  def send_fax(tmp_file)
    @fax.start_sending

    phaxio = Phaxio.send_fax(to: @fax.fax_number, filename: tmp_file)

    if phaxio.parsed_response['success']
      @fax.update(phaxio_id: phaxio['faxId'], status_message: phaxio.parsed_response['message'])
    else
      @fax.failure_sent
      @fax.update(status_message: phaxio.parsed_response['message'])
      raise StandardError, phaxio.parsed_response['message']
    end

    File.delete(tmp_file)
  end

end
