require 'rails_helper'
require "ostruct"

RSpec.describe ForcasterController, type: :controller do
    describe "GET search" do
        before(:each) do
            Geocoder.configure(:lookup => :test)
        end

        it "calls Geocoder" do
            query = "Test address"
            expect(Geocoder).to receive(:search).with(query)

            get :search, params: { query: query }
        end
    end

    describe "GET forecast" do
        let(:client) { double("client") }
        let(:data) do
            OpenStruct.new( {
                main: OpenStruct.new( {
                    temp_f: 50,
                    temp_max_f: 60,
                    temp_min_f: 40,
                }),
                weather: [ OpenStruct.new({ description: "Sunny" }) ],
            })
        end

        before do
            allow(OpenWeather::Client).to receive(:new).and_return(client)
            allow(client).to receive(:current_weather).and_return(data)
        end

        context "when search is not cached" do
            it "gets forecast from open weather" do
                expect(client).to receive(:current_weather).and_return(data)

                get :forecast, params: { address_selection: "0, 1, SF, 94608" }
            end

            it "caches the search" do
                expect(Rails).to receive(:cache).twice.and_call_original

                get :forecast, params: { address_selection: "0, 1, SF, 94608" }
            end
        end

        context "when search is cached" do
            let(:cached_data) do
                {
                    cur_temp: 55,
                    high: 65,
                    low: 45,
                    weather: "Cloudy",
                }
            end

            before { allow_any_instance_of(ActiveSupport::Cache::NullStore).to receive(:fetch).and_return(cached_data) }

            it "gets forecast from cached data" do
                expect(Rails).to receive(:cache).once.and_call_original

                get :forecast, params: { address_selection: "0, 1, SF, 94608" }
            end
        end
    end
end