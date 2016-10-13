class TelegramBotWrapper
  require 'telegram/bot'
  require 'net/http'
  require 'open-uri'
  require 'json'

  Thread.abort_on_exception = true

  attr_accessor :bot, :callbacks, :message, :thread, :token, :skip_users

  def initialize(token)
    self.bot = nil
    self.callbacks = []
    self.message = nil
    self.token = token
    self.thread = nil
    self.skip_users = []
  end

  def exit
    Thread.kill(thread)
  end

  def on_receive(&block)
    callbacks << block
  end

  def start_thread
    self.thread = Thread.new do
      Telegram::Bot::Client.run(token) do |bot|
        self.bot = bot
        self.bot.listen do |message|
          ::LOGGER.debug("#{message.from.username}: #{message.text}")
          self.message = message
          callbacks.each do |callback|
            begin
              callback.call message
            rescue Exception => e
              ::LOGGER.error(e)
            end
          end
        end
      end
    end
  end

  def status
    thread.status
  end

  def get_file(file_id: nil)
    5.times do |i|
      begin
        uri = URI("https://api.telegram.org/bot#{token}/getFile")
        LOGGER.debug("uri: #{uri}")
        res = Net::HTTP.post_form(uri, file_id: file_id)
        LOGGER.debug("response: #{res.body}")
        path = JSON.parse(res.body)['result']['file_path']

        File.open('/tmp/temp.png', 'wb') do |fo|
          LOGGER.debug("download path: https://api.telegram.org/file/bot#{token}/#{path}")
          fo.write open("https://api.telegram.org/file/bot#{token}/#{path}").read
        end
        break '/tmp/temp.png'
      rescue
        LOGGER.debug("Something went wrong. I'll try again.[#{i}/5]")
      end
    end
  end

  def send(text: nil, chat_id: message.chat.id, mode: 'HTML')
    text = text.encode(Encoding::UTF_8)
    bot.api.send_message(chat_id: chat_id, text: text, parse_mode: mode)
  end
end
