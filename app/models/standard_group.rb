class StandardGroup < ActiveRecord::Base
  FAMILY = 'Family'

  has_many :groups, :dependent => :destroy 

  validates :name, :presence => true, uniqueness: { case_sensitive: false }

  def self.load
    raise "This will delete all contacts in this group. Please edit code if you really intended to do this. Edit standard_groups.yml to bring in id for the standard_groups before you run this rake task, otherwise this will wipe out standard groups (and hence groups and hence group_users - which means contacts of users will go away)"
    StandardGroup.destroy_all
    groups = YAML.load(ERB.new(File.read("#{Rails.root}/config/standard_groups.yml.erb")).result)["groups"]
    groups['list'].each do |group_name|
      StandardGroup.create(:name => group_name)
    end
  end

  def self.default_label(group_name, account_type_key)
    groups = YAML.load(ERB.new(File.read("#{Rails.root}/config/standard_groups.yml.erb")).result)["groups"]
    groups['content'][group_name]['labels'][account_type_key]
  end
end
