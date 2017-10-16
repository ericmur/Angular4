namespace :user_document_cache do
  task :reset_cache => :environment do |t, args|
    UserDocumentJson.all.each do |j|
      j.destroy
    end
  end
end
