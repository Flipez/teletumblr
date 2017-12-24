require 'logger'
require 'rubygems'
require 'yaml'
require 'tumblr_client'

LOGGER = Logger.new('log/foodporn.log')

CONFIG = YAML.load_file('config.yml')

require_relative 'lib/bot.rb'

Tumblr.configure do |config|
  config.consumer_key       = CONFIG['tumblr']['consumer']['key']
  config.consumer_secret    = CONFIG['tumblr']['consumer']['secret']
  config.oauth_token        = CONFIG['tumblr']['oauth']['token']
  config.oauth_token_secret = CONFIG['tumblr']['oauth']['secret']
end

client = Tumblr::Client.new

::FoodpornBot = TelegramBotWrapper.new CONFIG['telegram']['token']

bot = FoodpornBot
bot.start_thread

bot.on_receive do |message|
  user = message.from.username
  if message.photo.any?
    if bot.skip_users.include? user
      bot.send text: "Skipped image from #{user}"
      bot.skip_users.delete(user)
      return false
    else
      LOGGER.debug("received file with id: #{message.photo.last.file_id}")
      file = bot.get_file file_id: message.photo.last.file_id
      LOGGER.debug("file path: #{file}")
      p client.photo('archfoodporn.tumblr.com', data: [file])
   end
  end
end

bot.on_receive do |message|
  case message.text
  when '/about'
    bot.send text: 'Yes, this is bot!'
  when '/skip_next'
    user = message.from.username
    bot.skip_users.push(user) unless bot.skip_users.include? user
    bot.send text: "Will skip the next image from #{user}"
  when '/skip_users'
    if bot.skip_users.to_a.any?
      msg = "Will skip the next image from: #{bot.skip_users.join(',')}"
      bot.send text: msg
    else
      bot.send text: 'All images will be forwarded'
    end
  end
end

bot.thread.join
