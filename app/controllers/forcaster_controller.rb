class ForcasterController < ApplicationController
    def index
    end

    def search
        query = search_params[:query]
        @result = Geocoder.search(query)

        render :index
    end

    def forecast
        selection = forecast_params[:address_selection].split(",")
        lat = selection[0].to_f
        lon = selection[1].to_f
        @city = selection[2]
        postcode = selection[3]

        data = get_forecast(lat, lon, postcode)

        @cur_temp = data[:cur_temp]
        @high = data[:high]
        @low = data[:low]
        @weather = data[:weather]

        render :index
    end

    def search_params
        params.permit(:query)
    end

    def forecast_params
        params.permit(:address_selection)
    end

    def get_forecast(lat, lon, postcode)
        cached_forecast = Rails.cache.fetch("forecast_#{postcode}")

        if cached_forecast
            forecast_data = {
                cur_temp: cached_forecast[:cur_temp],
                high: cached_forecast[:high],
                low: cached_forecast[:low],
                weather: cached_forecast[:weather],
            }
        else
            client = OpenWeather::Client.new(api_key: Rails.application.credentials.open_weather_map_key)
            data = client.current_weather(lat: lat, lon: lon)

            forecast_data = {
                cur_temp: data.main.temp_f,
                high: data.main.temp_max_f,
                low: data.main.temp_min_f,
                weather: data.weather.first.description.titleize,
            }

            Rails.cache.fetch("forecast_#{postcode}", expires_in: 30.minutes) do
                forecast_data
            end
        end
        forecast_data
    end
end
