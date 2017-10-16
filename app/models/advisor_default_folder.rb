#For an Advisor's clients, there are some default set of folders that we show
#on the client page on Advisor's web app. These folders depend on the category
#of that advisor. For e.g. A "Tax Accountant" Advisor would have default folders
#for his clients set as "Individual Tax", "Identity" etc. as those are the ones
#he needs to see no matter what. Even if there are no documents in that folder
#shared with him, he will still see these folders.
class AdvisorDefaultFolder < ActiveRecord::Base
  belongs_to :standard_category
  belongs_to :standard_folder
end
