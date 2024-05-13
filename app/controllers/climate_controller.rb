require 'net/http'
require 'uri'
require 'json'

class WeatherData
    attr_accessor :max_temp, :min_temp, :date

    def initialize(max_temp, min_temp, date)
        @max_temp = max_temp
        @min_temp = min_temp
        @date = date
    end

    def to_h
        { max_temp: @max_temp, min_temp: @min_temp, date: @date }
    end
end

class CityData
    attr_accessor :id, :slug, :state, :lat, :long, :weather

    def initialize(id, slug, state, lat, long)
        @id = id
        @slug = slug
        @state = state
        @lat = lat
        @long = long
        @weather = []
    end

    def to_h
        { id: @id, slug: @slug, state: @state, lat: @lat, long: @long, weather: @weather }
    end
end

class ClimateController < ApplicationController
    def show
        begin
            location = params[:location]
            
            if location.nil? or location.empty? or location.length < 3
                render json: { error: 'Location data must be 3 characters or longer' }, status: :bad_request
                return
            end
        rescue
            render json: { error: 'No location provided' }, status: :bad_request
            return
        end

        api_key = ENV['WEATHER_KEY']

        if api_key.nil?
            print ('No API key provided')
            render json: { error: 'Bad server configuration' }, status: :internal_server_error
            return
        end

        # get city data
        begin
            uri = URI("https://search.reservamos.mx/api/v2/places?q=#{location}")
            city_response = Net::HTTP.get(uri)
            location_data = JSON.parse(city_response)
        rescue
            render json: { error: 'Error fetching city data' }, status: :internal_server_error
            return
        end

        toReturn = []

        begin
            for city in location_data
                if city['result_type'] == 'city' and city['country'] == 'México'
                    data = CityData.new(city['id'], city['slug'], city['state'], city['lat'], city['long'])

                    # collect weather data
                    begin
                        weather_uri = URI("https://api.openweathermap.org/data/2.5/onecall?lat=#{data.lat}&lon=#{data.long}&exclude=current,minutely,hourly&units=metric&appid=#{api_key}")
                        weather_response = Net::HTTP.get(weather_uri)
                        weather_data = JSON.parse(weather_response)
                    rescue
                        render json: { error: 'Error fetching weather data' }, status: :internal_server_error
                        return
                    end

                    for day in weather_data['daily'] # note: this is a 7-day forecast, including today as day 0. If needed, we can exclude today by starting at 1.
                        data.weather << WeatherData.new(day['temp']['max'], day['temp']['min'], Time.at(day['dt']).strftime('%Y-%m-%d'))
                    end
                    
                    toReturn << data.to_h
                end
            end
        rescue
            render json: { error: 'Error parsing city data' }, status: :internal_server_error
            return
        end

        render json: toReturn, status: :ok
    end
end
