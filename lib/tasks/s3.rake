require 's3'

namespace :s3 do
  task :upload, [:upload_file_path] => :environment do |t, args|
    s3 = S3::DataEncryption.new
    s3.upload(args[:upload_file_path])

    puts "Symmetric Key: #{Base64.encode64(s3.encryption_key)}"
    
    puts "Object: #{File.basename(args[:upload_file_path])}"
  end

  task :download, [:encryption_key, :object_key, :download_file_path] => :environment do |t, args|
    s3 = S3::DataEncryption.new(Base64.decode64(args[:encryption_key]))
    s3.download(args[:object_key], args[:download_file_path])
  end

  task :delete, [:object_name] => :environment do |t, args|
    S3::DataEncryption.delete(args[:object_name])
  end

  task :download_page_using_docytbot_access, [:page_id, :location] => :environment do |t, args|
    Rails.set_user_password_hash(Rails.startup_password_hash)
    page = Page.find_by_id(args[:page_id])
    d = page.document
    key = d.symmetric_keys.where(:created_for_user_id => nil).first
    key = key.decrypt_key
    
    s3 = S3::DataEncryption.new(key)
    s3.download(page.s3_object_key, args[:location])
  end

  task :download_doc_using_docytbot_access, [:doc_id, :location] => :environment do |t, args|
    location = args[:location]
    if location.nil?
      location = "tmp/#{args[:doc_id]}"
    end
    
    unless File.directory?(location)
      FileUtils.mkdir_p(location)
    end

    Rails.set_user_password_hash(Rails.startup_password_hash)
    d = Document.find_by_id(args[:doc_id])
    if (d.standard_document and d.standard_document.with_pages == false)
      puts "This document cannot have pages: #{d.standard_document.standard_folder.name} / #{d.standard_document.name}"
      next
    end

    if d.pages.empty?
      puts "No pages uploaded for document: #{d.standard_document.standard_folder.name} / #{d.standard_document.name}"
      next
    end

    puts "Document: #{d.standard_document.standard_folder.name} / #{d.standard_document.name}"

    key = d.symmetric_keys.where(:created_for_user_id => nil).first
    if key.nil?
      puts "DocytBot does not have access to this document"
      next
    end
    key = key.decrypt_key
    if d.final_file_key
      s3 = S3::DataEncryption.new(key)
      s3.download(d.final_file_key, File.join(location, "document-final.pdf"))
      puts "Downloaded final pdf"
    end

    if d.original_file_key
      s3 = S3::DataEncryption.new(key)
      s3.download(d.original_file_key, File.join(location, "document-original.pdf"))
      puts "Downloaded original pdf"
    end

    path = File.join(location, "pages")
    FileUtils.mkdir_p(path)
    d.pages.each do |page|
      if page.state != 'uploaded'
        puts "Page: #{page.page_num} not uploaded yet"
        next
      end
      next unless page.s3_object_key
      
      s3 = S3::DataEncryption.new(key)
      page_path = File.join(path, page.s3_object_key)
      s3.download(page.s3_object_key, page_path)
      puts "Downloaded page: #{page.page_num}"
    end
    
  end

  task :download_thumbnail, [:user_id, :pin, :document_id, :location] => :environment do |t, args|
    u=User.where(:id => args[:user_id]).first
    p_hash = u.password_hash(args[:pin])
    Rails.set_user_password_hash(p_hash)
    Rails.set_app_type(User::MOBILE_APP)
    d = Document.find_by_id(args[:document_id])
    key = d.symmetric_keys.where(:created_for_user_id => args[:user_id]).first
    key = key.decrypt_key
    s3 = S3::DataEncryption.new(key)
    s3.download(d.first_page_thumbnail, args[:location])
  end

  task :upload_thumbnail, [:user_id, :pin, :document_id, :upload_file_path] => :environment do |t, args|
    u=User.where(:id => args[:user_id]).first
    p_hash = u.password_hash(args[:pin])
    Rails.set_user_password_hash(p_hash)
    Rails.set_app_type(User::MOBILE_APP)
    d = Document.find_by_id(args[:document_id])
    key = d.symmetric_keys.where(:created_for_user_id => args[:user_id]).first
    key = key.decrypt_key
    s3 = S3::DataEncryption.new(key)
    s3.upload(args[:upload_file_path])
  end

  task :download_page, [:user_id, :pin, :page_id, :location] => :environment do |t, args|
    u=User.where(:id => args[:user_id]).first
    p_hash = u.password_hash(args[:pin])
    Rails.set_user_password_hash(p_hash)
    Rails.set_app_type(User::MOBILE_APP)
    page = Page.where(:id => args[:page_id]).first
    key = page.document.symmetric_keys.where(:created_for_user_id => args[:user_id]).first
    key = key.decrypt_key
    s3 = S3::DataEncryption.new(key)
    s3.download(page.s3_object_key, args[:location])
  end

  task :upload_page, [:user_id, :pin, :page_id, :upload_file_path] => :environment do |t, args|
    u=User.where(:id => args[:user_id]).first
    p_hash = u.password_hash(args[:pin])
    Rails.set_user_password_hash(p_hash)
    Rails.set_app_type(User::MOBILE_APP)
    page = Page.where(:id => args[:page_id]).first
    key = page.document.symmetric_keys.where(:created_for_user_id => args[:user_id]).first
    key = key.decrypt_key
    s3 = S3::DataEncryption.new(key)
    s3.upload(args[:upload_file_path])
  end
end
