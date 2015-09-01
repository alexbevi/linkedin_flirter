#!/usr/bin/env ruby
require 'rubygems'
require 'bundler/setup'

Bundler.require

class Settings < Settingslogic
  source File.expand_path("../settings.yml", __FILE__)

  namespace "development"
  load!
end

@browser = Selenium::WebDriver.for :firefox
@browser.get 'https://linkedin.com'
@wait = Selenium::WebDriver::Wait.new(timeout: 10)

def find_field(selector, value)
  field = @wait.until do
    element = @browser.find_element(selector, value)
    element if element.displayed?
  end
  field
end

def find_fields(selector, value)
  fields = @wait.until do
    element = @browser.find_elements(selector, value)
    element if element.first.displayed?
  end
  fields
end

user = find_field(:id, "login-email")
user.send_keys Settings.username

pass = find_field(:id, "login-password")
pass.send_keys Settings.password

sleep 2

signin = find_field(:name, "submit")
signin.click

sleep 2

advanced_search = find_field(:id, "advanced-search")
advanced_search.click

sleep 2

# fill in search box
keywords = find_field(:id, "advs-keywords")
keywords.send_keys Settings.query.keywords

title = find_field(:id, "advs-title")
title.send_keys Settings.query.title

location = find_field(:id, "advs-locationType")
dropdown = Selenium::WebDriver::Support::Select.new(location)
dropdown.select_by(:text, 'Located in or near:')

postal_code = find_field(:id, "advs-postalCode")
postal_code.send_keys Settings.query.postcode

sleep 2

search = find_field(:class, "submit-advs")
search.click

sleep 2

# collect urls of all people on each page
profile_urls = []

profile_links = @browser.find_elements(:css, "ol#results a.title")
profile_links.each { |link| profile_urls << link.attribute("href") }

# puts profile_urls
# do the same for the rest of the pages
pagination_urls = @browser
  .find_elements(:css, ".pagination a")
  .map { |link| link.attribute("href") }

pagination_urls.each do |url|
  @browser.get url
  sleep 1

  profile_links = find_fields(:css, "ol#results a.title")
  profile_links.each { |link| profile_urls << link.attribute("href") }
end

profile_urls.each_with_index do |url,idx|
  puts "scraping #{idx + 1} of #{profile_urls.length}: #{url}"
  @browser.get url
  sleep 2
end
