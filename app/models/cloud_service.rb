class CloudService < ActiveRecord::Base
  DROPBOX = "Dropbox"
  GOOGLE_DRIVE = "Drive"
  ONE_DRIVE = "OneDrive"
  EVERNOTE = "Evernote"
  BOX = "Box"

  validates :name, presence: true, :inclusion => { :in => [DROPBOX, GOOGLE_DRIVE, ONE_DRIVE, EVERNOTE, BOX] }
  validates :name, uniqueness: true

  has_many :cloud_service_authorizations, :dependent => :destroy

  def google_drive?
    self.name == GOOGLE_DRIVE
  end

  def dropbox?
    self.name == DROPBOX
  end

  def one_drive?
    self.name == ONE_DRIVE
  end

  def evernote?
    self.name == EVERNOTE
  end

  def box?
    name == BOX
  end

  def self.google_drive
    CloudService.find_by_name(GOOGLE_DRIVE)
  end

  def self.dropbox
    CloudService.find_by_name(DROPBOX)
  end

  def self.one_drive
    CloudService.find_by_name(ONE_DRIVE)
  end

  def self.evernote
    CloudService.find_by_name(EVERNOTE)
  end

  def self.box
    CloudService.find_by_name(BOX)
  end
end
