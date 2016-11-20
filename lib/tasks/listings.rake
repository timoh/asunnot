namespace :listings do
  desc "Get all listings"
  task get_all: :environment do
    puts "Getting all from Oikotie"

    Listing.oikotie_get_all
    # add others here, if needed 

    puts "All listings populated!"
  end

end
