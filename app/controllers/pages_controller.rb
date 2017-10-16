require 'slack_helper'

class PagesController < ApplicationController
  skip_before_action :doorkeeper_authorize!, only: [:sns_notification]
  skip_before_action :confirm_phone!, only: [:sns_notification]
  skip_before_action :confirm_device_uuid!, only: [:sns_notification]
  before_action :load_page, only: [:show, :start_upload, :complete_upload, :reupload, :destroy, :object_keys, :check_pending_upload]
  before_action :load_document, except: [:complete_upload, :sns_notification]
  before_action :load_user_password_hash, only: [:show, :reorder, :destroy, :complete_upload]
  before_action :verify_editing_perms_for_document, except: [:show, :complete_upload, :check_pending_upload, :sns_notification]
  before_action :verify_version, only: [:reupload]
  before_action :verify_files_md5, only: [:complete_upload, :check_pending_upload]
  before_action :verify_aws_notification, only: [:sns_notification]
  after_action :recalculate_storage_counter, only: [:create, :reupload, :destroy]

  def create
    @page = @document.pages.build(page_params)

    if params[:location].present?
      @page.locations.build(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    end

    respond_to do |format|
      if @page.save
        DocumentCacheService.update_cache([:document], @page.document.consumer_ids_for_owners)
        format.json { render json: @page }
      else
        format.json { render json: { errors: @page.errors.full_messages },
                             status: :unprocessable_entity
                    }
      end
    end
  end

  def reupload
    @page.version += 1
    @page.original_file_md5 = params[:original_file_md5]
    @page.final_file_md5 = params[:final_file_md5]

    @page.reupload!

    if params[:location].present?
      @page.locations.build(latitude: params[:location][:latitude], longitude: params[:location][:longitude])
    end

    if @page.save #We make s3 keys nil on reupload and they need to be saved too
      PageUploadCompletionJob.set(wait_until: 5.minutes.from_now).perform_later(@page.id, current_user.id)
      DocumentCacheService.update_cache([:document], @page.document.consumer_ids_for_owners)
      respond_to do |format|
        format.json { render json: @page }
      end
    else
      respond_to do |format|
        format.json { render json: { errors: @page.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def show
    respond_to do |format|
      format.json { render json: @page }
    end
  end

  def object_keys
    respond_to do |format|
      format.json { render json: @page, serializer: PageObjectKeysSerializer, root: 'page' }
    end
  end

  def destroy
    @page.destroy

    if @page.document.pages.count > 0
      # recreate pdf, because document's pages have changed
      @page.document.share_with(:with_user_id => nil, :by_user_id => current_user.id)
      
      @page.recreate_document_pdf

      DocumentCacheService.update_cache([:document], @page.document.consumer_ids_for_owners)
    end

    @page.document.generate_notification_for_deleted_page(current_user)

    respond_to do |format|
      format.json { render :json => { }, status: :no_content }
    end
  end

  def start_upload
    errors = []
    begin
      @page.original_file_md5 = params[:original_file_md5]
      @page.final_file_md5 = params[:final_file_md5]

      unless @page.start_upload!
        errors << @page.errors.full_messages
      end

    rescue AASM::InvalidTransition
      errors << 'S3 Object does not exist'
    end

    if errors.empty?
      PageUploadCompletionJob.set(wait_until: 5.minutes.from_now).perform_later(@page.id, current_user.id)
      DocumentCacheService.update_cache([:document], @page.document.consumer_ids_for_owners)
    end

    respond_to do |format|
      if errors.empty?
        format.json { render json: @page }
      else
        format.json { render json: { errors: errors.flatten },
                             status: :unprocessable_entity
                    }
      end
    end
  end

  #This will be triggered for documents uploaded via Service Provider web portal. For those documents when they are split into images for each page (for the iPhone app), the images are still uploaded using traditional complete_upload action which works better for them. SNS notification is only best for background upload in iPhone
  def complete_upload
    @page.s3_object_key = params[:s3_object_key]
    @page.original_s3_object_key = params[:original_s3_object_key]
    @page.original_file_md5 = params[:original_file_md5]
    @page.final_file_md5 = params[:final_file_md5]

    errors = []
    begin
      if @page.complete_upload!
        @page.document.enqueue_create_notification_for_completed_page(current_user, @page)
        @page.update_document_initial_pages_completion

        # recreate pdf, because document's page have changed. 
        @page.document.share_with(:with_user_id => nil, :by_user_id => current_user.id)
        @page.recreate_document_pdf

        #When document is initially uploaded, there are a lot of pages uploaded together, we don't want to recreate cache upon every page upload (to get new set of s3 keys). We will just recreate it once the entire set of pages is uploaded
        if @page.document.initial_pages_completed?
          DocumentCacheService.update_cache([:document], @page.document.consumer_ids_for_owners)
        end
      else
        errors << @page.errors.full_messages
      end

    rescue AASM::InvalidTransition
      errors << 'S3 Object does not exist'
    end

    respond_to do |format|
      if errors.empty?
        format.json { render json: @page }
      else
        format.json { render json: { errors: errors.flatten },
                             status: :unprocessable_entity
                    }
      end
    end
  end

  def reorder
    params[:pages].each do |page_hash|
      page = Page.find(page_hash['id'])
      page.page_num = page_hash['n']
      page.save

      DocumentCacheService.update_cache([:document], page.document.consumer_ids_for_owners)
      
      # recreate pdf, because document's page have changed
      page.document.share_with(:with_user_id => nil, :by_user_id => current_user.id)
      page.recreate_document_pdf
    end

    respond_to do |format|
      format.json { render json: { status: true } }
    end
  end

  def check_pending_upload
    respond_to do |format|
      if @page.uploaded?
        format.json { render json: { status: false }, status: :unprocessable_entity }
      else
        if Rails.env.production? || Rails.env.staging?
          SlackHelper.ping({channel: "#errors", username: "PageUploadBot", message: "Detached Page found: #{@page.id}"})
        end
        format.json { render json: { status: true } }
      end
    end
  end

  def sns_notification
    with_sns_notification("PageUploadBot") do |message|
      message["Records"].each do |record_hash|
        next if record_hash["s3"].blank?
        process_page_completion_from_sns_notification(record_hash)
      end if message["Records"].present?
    end
    render nothing: true
  end

  private

  def recalculate_storage_counter
    return unless response.code == '200' || response.code == '201' || response.code == '204'
    Rails.logger.info "Calculating storage size counter"
    # Add rescue block to unsure page created successfully
    # We can always recalculate later
    begin
      # This will only do local calculation. Will not fetch the actuall size on S3
      @page.document.recalculate_storage_counter
    rescue => e
      SlackHelper.ping({ channel: "#errors", username: "PageUploadBot", message: e.message }) if (Rails.env.production? or Rails.env.staging?)
    end
  end

  def process_page_completion_from_sns_notification(record_hash)
    object_key = record_hash["s3"]["object"]["key"]
    return unless object_key.match('Page-')

    numbers = object_key.scan(/\d+/)
    if numbers.count < 2
      #This will be triggered for documents uploaded via Service Provider web portal. For those documents when they are split into images for each page (for the iPhone app), the images are still uploaded using traditional complete_upload action which works better for them. SNS notification is only best for background upload in iPhone
=begin      
      msg = "SNS: Page complete_upload event triggered for old s3_object_key scheme"
      Rails.logger.info msg
      SlackHelper.ping({ channel: "#errors", username: "PageUploadBot", message: msg }) if (Rails.env.production? or Rails.env.staging?)
=end
      return
    end
    page_version = numbers.last

    page_id = numbers.first
    page = Page.find_by_id(page_id)

    if page.present? && page.version == page_version.to_i
      page.proccess_completion_from_sns_notification(object_key)
    end
=begin      
    #It is now safe to comment out this else case as with too many users this seems to happen often.   
    else
      if page.present? #If user adds a page on the phone and then immediately edits it too. There will be 2 quick uploads that will be done to s3. And it is possible that server will get SNS notifications for an older version while page.version is newer
        msg = "SNS: Page complete_upload event triggered for Page #{page_id}, version invalid #{page.version} != #{page_version}"
      else #If user deletes the page before SNS notification is received
        msg = "SNS: Page complete_upload event triggered. Page not found #{page_id}"
      end
      Rails.logger.info msg
      SlackHelper.ping({ channel: "#errors", username: "PageUploadBot", message: msg })
=end
  end

  def verify_files_md5
    unless @page.files_md5_matched?(params[:original_file_md5], params[:final_file_md5])
      respond_to do |format|
        format.json { render :json => { :errors => ["Only owner of the document is allowed to make this change"]}, :status => :forbidden }
      end
    end
  end

  def page_params
    params.require(:page).permit(:name, :page_num, :storage_size, :source)
  end

  def verify_editing_perms_for_document
    unless @document.editable_by?(current_user)
      respond_to do |format|
        format.json { render status: 403, json: ['Only owner of the document is allowed to make this change'] }
      end
    end
  end

  def load_document
    if params[:action] == 'create'
      @document = Document.find_by_id(params[:document_id])
    elsif params[:action] == 'reorder'
      @document = Page.find(params[:pages].first['id']).document
      params[:pages].each do |page_hash|
        if @document.id != Page.find(page_hash['id']).document_id
          respond_to do |format|
            format.json { render :json => { :errors => ["You don't have permissions to make this change"] }, :status => :forbidden }
          end
        end
      end
    else
      @document = @page.document
    end
  end

  def load_page
    @page = Page.find_by_id(params[:id])
    #Handle the case of nil since complete_upload could be called in async mode with a deleted page's id
    if @page.nil?
      respond_to do |format|
        format.json { render json: { errors: ['Invalid Page']}, status: :unprocessable_entity }
      end
    end
  end

  def load_symmetric_key
    document = @page.document
    @symmetric_key = document.symmetric_keys.for_user_access(current_user.id).first

    unless @symmetric_key.present?
      respond_to do |format|
        format.json { render json: { errors: ['You may not have the permission to access the file'] },
                             status: :unprocessable_entity
                    }
      end
    end
  end

  def verify_version
    if @page.version >= params[:version].to_i + 1
      respond_to do |format|
        format.json { render json: { errors: ["Your local page is outdated. Your page is getting restored back to old image."] }, status: :unprocessable_entity }
      end
    end
  end

end
