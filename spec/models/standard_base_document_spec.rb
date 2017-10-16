require 'rails_helper'
require 'spec_helper'
require 'custom_spec_helper'

RSpec.describe StandardBaseDocument, :type => :model do
  before(:each) do
    load_standard_documents('standard_base_documents_structure1.json')
    load_docyt_support('standard_base_documents_structure1.json')
  end

  after(:each) do
    StandardBaseDocument.delete_all
  end

  it 'should not repeat folders even when load is run multiple times' do
    n = StandardBaseDocument.count
    load_standard_documents('standard_base_documents_structure1.json')
    expect(StandardBaseDocument.count).to eq(n)
  end

  it 'should not repeat folders and add new document, remove old document when load is run with a different yml file' do
    n = StandardBaseDocument.count
    load_standard_documents('standard_base_documents_structure2.json')
    expect(StandardBaseDocument.count).to eq(68)
    expect(StandardBaseDocument.where(:name => 'Title').first).to eq(nil)
    expect(StandardBaseDocument.where(:name => 'Drivers License').first).to_not eq(nil)
  end

  it 'should not delete custom standard folder when reload structure' do
    n = StandardFolder.count

    FactoryGirl.create(:standard_folder, :with_consumer)
    expect(StandardFolder.count).to eq(n + 1)

    load_standard_documents('standard_base_documents_structure1.json')

    expect(StandardFolder.where(consumer_id: nil).count).to eq(n)
    expect(StandardFolder.where.not(consumer_id: nil).count).to eq(1)
    expect(StandardFolder.count).to eq(n + 1)
  end

=begin
  it 'should load standard_base_documents3.yml correctly' do
    load_standard_documents('standard_base_documents3.yml')
    expect(StandardBaseDocument.count).to eq(30)
  end
=end

  it 'should create folders and documents correctly using standard_base_documents1.yml' do
    expect(StandardFolder.where(:category => true).count).to eq(12)
    expect(StandardDocument.where(:category => true).count).to eq(0)
    categories = StandardFolder.where(:category => true).order(rank: :asc)
    expect(categories.map { |cat| cat.name }).to eq(["Invoices & Receipts", "Operations", "Certificates", "Contracts", "Financials", "Passwords", "Taxes", "Insurance/Claims", "Personal", "Travel", "Car", "Consumer"])

    [['Personal', ['Drivers License', 'Social Security Card', 'Birth Certificate']], ['Travel', ["Drivers License", "EAD Card", "Visas"]]].each do |category, docs|
      personal_folder = StandardFolder.where(:category => true, :name => category).first
      sfsds = personal_folder.standard_folder_standard_documents.order(rank: :asc)
      expect(sfsds.map { |sfsd| sfsd.standard_base_document.name }).to eq(docs) #Except all files inside personal folder to have the right names in the right order

      expect(sfsds.map { |sfsd| sfsd.standard_base_document.type }.uniq).to eq(['StandardDocument']) #Except all files inside personal folder are documents
    end

    personal_folder = StandardFolder.where(:category => true, :name => 'Car').first
    sfsds = personal_folder.standard_folder_standard_documents.order(rank: :asc)
    expect(sfsds.map { |sfsd| sfsd.standard_base_document.name }).to eq(['Car Purchase Receipt','Auto Insurance Card', 'Title', 'Loan Agreement']) #Except all files inside personal folder to have the right names in the right order

    expect(sfsds.map { |sfsd| sfsd.standard_base_document.type }).to eq(['StandardDocument', 'StandardDocument', 'StandardDocument', 'StandardDocument']) #Except all files inside personal folder are documents

    loan_folder = sfsds.last.standard_base_document
    sfsds = loan_folder.standard_folder_standard_documents.order(rank: :asc)
    expect(sfsds.map { |sfsd| sfsd.standard_base_document.name }).to eq(['Loan Agreement'])
    expect(sfsds.map { |sfsd| sfsd.standard_base_document.type }.uniq).to eq(['StandardDocument'])
  end

  it 'should have non-nil consumer_id if group_user_id is non-nil'
end
