# README

This is a rails project that exposes an endpoint for the weather in a given place searches for existing locations in the city, and returns the list of expected weather.

The developed rails version is:

* Rails version: 7.1.3.2

# Configuration

You might need to run `rails db:migrate` to migrate the database.

# Running 

Run: `WEATHER_KEY="<key>" rails server` 

To start the server.

To test an endpoint, make a GET request to `http://127.0.0.1:3000/climate/<city>`