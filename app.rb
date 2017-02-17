require 'sinatra'
require 'sinatra/base'
require 'json'

class App < Sinatra::Base
  set escape_html: true

  before do
    content_type 'application/json'
  end

  get '/units/si' do
    begin
      {
        'unit_name'             => converter.unit_name,
        'multiplication_factor' => converter.mult_factor.round(14)
      }.to_json

    rescue MalformedParenthesesError
      status 400
      body 'Bad Request: Malformed Parentheses'
    rescue MalformedUnitError
      status 400
      body 'Bad Request: Malformed units query param'
    rescue => e
      status 400
    end
  end

  private

  def converter
    @_converter ||= Converter.new units
  end

  def units
    @_units ||= params[:units] || ''
  end
end
