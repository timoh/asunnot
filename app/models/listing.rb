# require 'selenium-webdriver'
# require 'phantomjs'
# require 'watir'
require 'uri'
require 'rest_client'
require 'json'

class Listing
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String
  field :oikotie_payload, type: Hash
  field :oikotie_id, type: String

  validates :oikotie_id, uniqueness: true

  before_save :construct_title

  def construct_title
    oikotie = true if self.oikotie_payload

    if oikotie
      constructed_title = self.oikotie_payload['buildingData']['city'].to_s + ": " + self.oikotie_payload['buildingData']['address'].to_s + " - "+  self.oikotie_payload['description'].to_s
      self.title = constructed_title
    end
  end

  def Listing.oikotie_get_cards(limit=24, offset=0)

    cardType=100
    locations=[[64,6,"Helsinki"],[39,6,"Espoo"]]
    price_max=1000000
    price_min=50000
    size_min=25

    room_count_params="roomCount[]=3&roomCount[]=4&roomCount[]=5&roomCount[]=6&roomCount[]=7&roomCount[]=2"

    sort_by="published_desc"

    api_url = "http://asunnot.oikotie.fi/api/cards?cardType=#{cardType}&limit=#{limit}&locations=#{locations}&offset=#{offset}&price[max]=#{price_max}&price[min]=#{price_min}&#{room_count_params}&size[min]=#{size_min}&sortBy=#{sort_by}"
    escaped_url = URI.escape(api_url)

    do_this_on_each_retry = Proc.new do |exception, try, elapsed_time, next_interval|
      log "#{exception.class}: '#{exception.message}' - #{try} tries in #{elapsed_time} seconds and #{next_interval} seconds until the next try."
    end

    response = nil

    Retriable.retriable on_retry: do_this_on_each_retry, tries: 15, base_interval: 3 do
      response = JSON.parse RestClient.get escaped_url
    end

    raise "GET request failed!" unless response

    # [
    #   "id",
    #   "url",
    #   "description",
    #   "rooms",
    #   "roomConfiguration",
    #   "price",
    #   "nextViewing",
    #   "images",
    #   "newDevelopment",
    #   "published",
    #   "size",
    #   "sizeLot",
    #   "cardType",
    #   "contractType",
    #   "onlineOffer",
    #   "extraVisibility",
    #   "extraVisibilityString",
    #   "buildingData",
    #   "coordinates",
    #   "brand",
    #   "priceChanged",
    #   "visits",
    #   "visits_weekly"
    # ]

    response['cards'].each do |card|
      listing = Listing.find_or_initialize_by(:oikotie_id => card['id'])
      listing.oikotie_payload = card
      listing.save
    end

    return response['found']
  end

  def Listing.oikotie_get_all
    limit = 50 # how many cards to try to get at once
    counter = 0 # counter for how many cards have been processed
    responses = 99999 # amount of cards to get, initialize to a high no.
    while counter <= responses # continue until all processed
      begin
        responses = Listing.oikotie_get_cards(limit, counter)
        # updates the responses based on the latest data
      rescue Interrupt => e
        break
      rescue SignalException => e
        break
      rescue IRB::Abort => e
        break
      rescue StandardError => detail
        puts "Batch failed!"
        puts detail
      else
        puts "Getting #{counter} out of #{responses} succeeded!"
        counter += limit # add the amount of cards successfully got to counter
      end
    end

    return counter
  end


end
