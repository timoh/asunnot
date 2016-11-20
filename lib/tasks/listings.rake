namespace :listings do
  desc "Get all listings"
  task get_all: :environment do
    puts "Getting all from Oikotie"

    Listing.oikotie_get_all
    # add others here, if needed

    puts "All listings populated!"
  end

  desc "Get all listings only part of the time to make API access random"
  task get_all_sometimes: :environment do

    randomn = SecureRandom.random_number(100)
    puts "Random number: #{randomn}."

    threshold = 85 # 0-100 the higher threshold..
    # ..the less likely the job will be run

    if randomn > threshold
      puts "Threshold was #{threshold}, so proceeding to get."
      puts "Getting all from Oikotie"

      Listing.oikotie_get_all
      # add others here, if needed

      puts "All listings populated!"
    else
      puts "Skipping this time.."
    end
  end

end
