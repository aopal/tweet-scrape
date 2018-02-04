require 'nokogiri'
require 'json'
require 'uri'
require 'csv'
require 'net/http'
require 'net_http_ssl_fix'

class TweetScraper
  def initialize(options)
    @limit = options[:limit]
    @pretty_print = options[:pretty_print]
    @csv = options[:csv]
    @filename = options[:file]
    @continuous = options[:continuous]
    @verbose = options[:verbose]
    @query = options[:query]
    @tweets = []
    @tweet_count = 0
    @started_at = nil
  end

  def scrape
    STDERR.sync = true
    STDOUT.sync = true

    base = "https://twitter.com/search?q="
    @started_at = Time.now

    page = Net::HTTP.get(URI(base + URI.escape(@query)))
    min_position = page.scan(/data-min-position=\"([^\"]*)\"/).last.first
    new_tweets = extract_tweets_from_html(page)
    @tweets = new_tweets
    @tweet_count = @tweets.count

    interrupted = false
    trap("INT") { interrupted = true }
    STDERR.puts 'Scraping, press Ctrl-C to exit' if @verbose

    print_update if @verbose

    if @continuous
      if @filename
        CSV.open(@filename, "wb") do |csv|
          csv << @tweets[0].keys
        end
      else
        puts @tweets[0].keys.join(',')
      end
    end

    write_tweets(new_tweets) if @continuous

    while(!interrupted && (!@limit || @tweet_count <= @limit))
      STDERR.print "\r" if @verbose

      uri = URI("https://twitter.com/i/search/timeline?q=#{URI.escape(@query)}&max_position=#{min_position}")
      stop = false
      while(!stop)
        begin
          page = Net::HTTP.get(uri)
          stop = true
        rescue StandardError => e
          STDERR.puts "Encountered error. retrying...", e.class, e.inspect if @verbose
          stop = false
          sleep 0.5
        end
      end

      begin
        html = JSON.parse(page)["items_html"]
      rescue JSON::ParserError => e
        STDERR.puts "Received error response from twitter. Exiting." if @verbose
        break
      end
      min_position = JSON.parse(page)["min_position"]

      new_tweets = extract_tweets_from_html(html)
      break if new_tweets.empty?
      @tweets += new_tweets if !@continuous
      @tweet_count += new_tweets.count

      write_tweets(new_tweets) if @continuous

      print_update if @verbose
    end

    @tweets = @tweets.first(@limit) if @limit

    write_tweets(@tweets) if !@continuous

    STDERR.puts "\nAll tweets scraped" if @verbose
  end

  private

  def extract_tweets_from_html(html)
    res = Nokogiri::HTML(html)
    res.css("div[class~='tweet']").map do |tweet|
      {
        permalink:      "https://twitter.com" + tweet["data-permalink-path"].to_s,
        tweet_nonce:    tweet["data-tweet-nonce"],
        tweet_id:       tweet["data-tweet-id"],
        user_id:        tweet["data-user-id"],
        username:       tweet.css("span[class~='username']").text.strip,
        fullname:       tweet.css("strong[class~='fullname']").text.strip,
        posted_time:    tweet.css("span[class~='_timestamp']").first['data-time'].to_i,
        reply_count:    tweet.at_css("div[class~='ProfileTweet-actionList']").css("div[class~='ProfileTweet-action--reply']").text.scan(/([0-9]+)/).flatten[0].to_i,
        retweet_count:  tweet.at_css("div[class~='ProfileTweet-actionList']").css("div[class~='ProfileTweet-action--retweet']").text.scan(/([0-9]+)/).flatten[0].to_i,
        favorite_count: tweet.at_css("div[class~='ProfileTweet-actionList']").css("div[class~='ProfileTweet-action--favorite']").text.scan(/([0-9]+)/).flatten[0].to_i,
        body:           tweet.css("div[class='js-tweet-text-container']").text.strip.gsub("\n","")
      }
    end
  end

  def write_tweets(tweets)
    text = @continuous ? csv_text(tweets) : json_text(tweets)
    if @filename
      File.open(@filename, "a") do |file|
        file.write(text)
      end
    else
      puts text
    end
  end

  def json_text(tweets)
    return @pretty_print ? JSON.pretty_generate(tweets) : tweets.to_json
  end

  def csv_text(tweets)
    return CSV.generate do |csv|
      tweets.each do |tweet|
        csv << tweet.values
      end
    end
  end

  def print_update
    delta = Time.now - @started_at
    STDERR.print "Tweets scraped: #{@tweet_count}\tTime elapsed: #{Time.at(delta.to_i.abs).utc.strftime "%H:%M:%S"}"
  end
end
