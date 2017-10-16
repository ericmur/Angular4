namespace :workflows do
  task :create, [:user_id, :name, :end_date] => :environment do |t, args|
    WorkflowService.new(args).create_workflow
  end

  task :add_participant, [:workflow_id, :user_id] => :environment do |t, args|
    WorkflowService.new(args).add_participant
  end

  task :add_standard_document, [:workflow_id, :standard_document_id]  => :environment do |t, args|
    WorkflowService.new(args).add_standard_document
  end

  task :require_participant_to_upload, [:workflow_id, :standard_document_id, :participant_id] => :environment do |t, args|
    WorkflowService.new(args).require_participant_to_upload
  end
end
