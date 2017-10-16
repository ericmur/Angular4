require 'rails_helper'
require 'custom_spec_helper'

RSpec.describe Api::Web::V1::DocumentAssignmentService do
  before do
    load_standard_documents('standard_base_documents_structure3.json')
    load_docyt_support('standard_base_documents_structure3.json')
    Rails.set_app_type(User::WEB_APP)
  end

  let!(:service)  { Api::Web::V1::DocumentAssignmentService }

  let!(:client)  { create(:client, advisor: advisor) }
  let!(:advisor) { create(:advisor, :with_fullname, :confirmed_email) }

  let!(:invalid_client)  { create(:client) }
  let!(:consumer_client) { create(:client, :connected, advisor: advisor) }

  let!(:invalid_document)        { create(:document, :with_uploader_and_owner) }
  let!(:invalid_consumer_client) { create(:client, :connected) }

  let!(:email_attached_document) {
    create(:document, :attached_to_email,
      uploader: advisor,
      document_owners: [DocumentOwner.new(owner: advisor)]
    )
  }

  context 'assign_to' do
    let!(:assignment_params) {
      {
        :ids => [email_attached_document.id]
      }
    }

    describe '#client' do
      let!(:invalid_document_assignment_params) {
        {
          :ids => [invalid_document.id]
        }
      }

      it 'should assign document to a client' do
        service_instance = service.new(advisor, client.id, assignment_params, { client_id: client.id })

        expect {
          service_instance.assign_to_client
        }.to change(DocumentOwner, :count).by(1)

        expect(service_instance.instance_variable_get(:@documents).first.document_owners.last.owner)
              .to eq(client)

        expect(service_instance.errors).to eq({})
      end

      it 'should not assign wrong document to a client' do
        service_instance = service.new(advisor, client.id, invalid_document_assignment_params, { client_id: client.id })

        expect {
          service_instance.assign_to_client
        }.not_to change(DocumentOwner, :count)
      end

      it 'should not assign to wrong client' do
        service_instance = service.new(advisor, invalid_client.id, assignment_params, { client_id: invalid_client.id })

        expect {
          service_instance.assign_to_client
        }.not_to change(DocumentOwner, :count)

        expect(service_instance.errors).not_to eq({})
      end

      it 'should not assign to nil client' do
        service_instance = service.new(advisor, nil, assignment_params, { client_id: nil })

        expect {
          service_instance.assign_to_client
        }.not_to change(DocumentOwner, :count)

        expect(service_instance.errors).not_to eq({})
      end
    end

    describe '#consumer' do
      it 'should assign document to a consumer' do
        service_instance = service.new(advisor, consumer_client.id, assignment_params, { client_id: consumer_client.id })

        expect {
          service_instance.assign_to_client
        }.to change(DocumentOwner, :count).by(1)

        expect(service_instance.instance_variable_get(:@documents).first.document_owners.last.owner)
              .to eq(consumer_client.consumer)

        expect(service_instance.errors).to eq({})
      end

      it 'should create symmetric key then assigning to a consumer' do
        service_instance = service.new(advisor, consumer_client.id, assignment_params, { client_id: consumer_client.id })

        expect {
          service_instance.assign_to_client
        }.to change(SymmetricKey, :count).by(1)

        expect(service_instance.errors).to eq({})
      end

      it 'should not assign to wrong consumer' do
        service_instance = service.new(advisor, invalid_consumer_client.id, assignment_params, { client_id: invalid_consumer_client.id })

        expect {
          service_instance.assign_to_client
        }.not_to change(DocumentOwner, :count)

        expect(service_instance.errors).not_to eq({})
      end
    end

    describe "#group user" do
      context "#connected" do
        let!(:standard_group) { create(:standard_group) }

        let!(:group)                { create(:group, owner: consumer_client.consumer, standard_group: standard_group) }
        let!(:connected_group_user) { create(:group_user_custom_consumer, user: create(:consumer), group_id: group.id) }

        let!(:another_group)       { create(:group, owner: client_group_owner.consumer, standard_group: standard_group) }
        let!(:client_group_owner)  { create(:client, :connected, advisor: advisor) }

        let!(:invalid_connected_group_user) { create(:group_user_custom_consumer, user: create(:consumer), group: another_group) }

        it "should assign document to a group_user" do
          service_instance = service.new(advisor, consumer_client.id, assignment_params, { contact_id: connected_group_user.id, contact_type: "GroupUser" })

          expect {
            service_instance.assign_to_client
          }.to change(DocumentOwner, :count).by(1)

          expect(service_instance.instance_variable_get(:@documents).first.document_owners.last.owner)
                .to eq(connected_group_user.user)

          expect(service_instance.errors).to eq({})
        end

        it "should create symmetric key then assign to a group_user" do
          service_instance = service.new(advisor, consumer_client.id, assignment_params, { contact_id: connected_group_user.id, contact_type: "GroupUser" })

          expect {
            service_instance.assign_to_client
          }.to change(SymmetricKey, :count).by(2)

          expect(service_instance.errors).to eq({})
        end

        it "should not assign to wrong group_user" do
          service_instance = service.new(advisor, invalid_consumer_client.id, assignment_params, { contact_id: invalid_connected_group_user.id, contact_type: "GroupUser" })

          expect {
            service_instance.assign_to_client
          }.not_to change(DocumentOwner, :count)

          expect(service_instance.errors).not_to eq({})
        end
      end

      context "#unconnected" do
        let!(:standard_group) { create(:standard_group) }

        let!(:group) { create(:group, owner: consumer_client.consumer, standard_group: standard_group) }
        let!(:unconnected_group_user) { create(:unconnected_group_user, group_id: group.id) }

        let!(:client_group_owner) { create(:client, :connected, advisor: advisor) }
        let!(:another_group)      { create(:group, owner: client_group_owner.consumer, standard_group: standard_group) }
        let!(:invalid_unconnected_group_user) { create(:unconnected_group_user, group_id: another_group.id) }

        it "should assign document to a group_user" do
          service_instance = service.new(advisor, consumer_client.id, assignment_params, { contact_id: unconnected_group_user.id, contact_type: "GroupUser" })

          expect {
            service_instance.assign_to_client
          }.to change(DocumentOwner, :count).by(1)

          expect(service_instance.instance_variable_get(:@documents).first.document_owners.last.owner)
                .to eq(unconnected_group_user)

          expect(service_instance.errors).to eq({})
        end

        it "should not assign to wrong group_user" do
          service_instance = service.new(advisor, invalid_consumer_client.id, assignment_params, { contact_id: invalid_unconnected_group_user.id, contact_type: "GroupUser" })

          expect {
            service_instance.assign_to_client
          }.not_to change(DocumentOwner, :count)

          expect(service_instance.errors).not_to eq({})
        end
      end
    end
  end
end
