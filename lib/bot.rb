class TelegramBotWrapper

  require 'telegram/bot'
  require 'net/http'
  require 'open-uri'
  require 'json'

  Thread::abort_on_exception = true

  attr_accessor :bot, :callbacks, :message, :thread, :token, :action, :done, :action

  def initialize(token)
    self.bot = nil
    self.callbacks = Array.new
    self.message = nil
    self.token = token 
    self.thread = nil
    self.action = nil
    self.done
  end

  def exit
    Thread.kill(self.thread)
  end

  def on_receive &block
    self.callbacks << block
  end

  def start_thread
    self.thread = Thread.new do
                    Telegram::Bot::Client.run(token) do |bot|
                      self.bot = bot
                      self.bot.listen do |message|
                        ::LOGGER.debug("#{message.from.username}: #{message.text}")
                        self.message = message
                        self.done = false
                        self.callbacks.each do |callback|
                          begin
                            callback.call message unless self.done
                          rescue Exception => e
                           ::LOGGER.error(e)
                          end
                        end
                      end
                    end
                  end
  end

  def status
    self.thread.status
  end

  def get_file file_id: nil
    5.times do |i|
      begin
        uri = URI("https://api.telegram.org/bot#{self.token}/getFile")
        LOGGER.debug("uri: #{uri}")
        res = Net::HTTP.post_form(uri, file_id: file_id)
        LOGGER.debug("response: #{res.body}")
        path = JSON.parse(res.body)['result']['file_path']

        File.open('/tmp/temp.png', 'wb') do |fo|
          LOGGER.debug("download path: https://api.telegram.org/file/bot#{self.token}/#{path}")
          fo.write open("https://api.telegram.org/file/bot#{self.token}/#{path}").read
        end
        break '/tmp/temp.png'
      rescue
        LOGGER.debug("Something went wrong. I'll try again.[#{i}/5]")
      end
    end
  end

  def send text: nil, chat_id: message.chat.id, mode: 'HTML'
    text = text.encode(Encoding::UTF_8)
    self.bot.api.send_message(chat_id: chat_id, text: text, parse_mode: mode)
    self.done = true
  end
end