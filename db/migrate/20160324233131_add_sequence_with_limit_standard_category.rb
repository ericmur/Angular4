class AddSequenceWithLimitStandardCategory < ActiveRecord::Migration
  def change
    execute(%q{
      ALTER SEQUENCE standard_categories_id_seq RESTART WITH 10001
    }) #Assuming we will have a maximum of 10000 standard_categories to manage in the entire Future of Docyt. Beyond that will be consumer provided standard_categories. This is done because we might recreate categories (due to configuration change in config/standard_categories.json) and we don't want to lose the id associated with a standard_category, otherwise relationships will break
  end
end
