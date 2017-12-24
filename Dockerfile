from ruby:2.4
RUN mkdir /app
ADD . /app/
WORKDIR /app
RUN bundle install
CMD ["ruby", "foodporn_bot.rb"]
