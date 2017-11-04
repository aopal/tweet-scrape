require 'nokogiri'
require 'json'
require 'uri'
require 'net/http'
require 'net_http_ssl_fix'

class TweetScraper
  def initialize(options)
    @limit = options[:limit]
    @pretty_print = options[:pretty_print]
    @filename = options[:file]
    @continuous = options[:continuous]
    @verbose = options[:verbose]
    @query = options[:query]
    @tweets = []
    @started_at = nil
  end

  def scrape
    STDERR.sync = true

    base = "https://twitter.com/search?q="
    @started_at = Time.now

    page = Net::HTTP.get(URI(base + URI.escape(@query)))
    min_position = page.scan(/data-min-position=\"([^\"]*)\"/).last.first
    @tweets = extract_tweets_from_html(page)

    interrupted = false
    trap("INT") { interrupted = true }
    STDERR.puts 'Scraping, press Ctrl-C to exit' if @verbose

    print_update if @verbose

    while(!interrupted && (!@limit || @tweets.count <= @limit))
      STDERR.print "\r" if @verbose

      uri = URI("https://twitter.com/i/search/timeline?vertical=default&q=#{URI.escape(@query)}&include_available_features=1&include_entities=1&max_position=#{min_position}&reset_error_state=false")
      page = Net::HTTP.get(uri)
      html = JSON.parse(page)["items_html"]
      min_position = JSON.parse(page)["min_position"]

      new_tweets = extract_tweets_from_html(html)
      break if new_tweets.empty?
      @tweets += new_tweets
      @tweets = @tweets.uniq

      File.write(@filename, tweet_text) if @continuous && @filename

      print_update if @verbose
    end

    @tweets = @tweets.first(@limit) if @limit

    if @filename
      File.write(@filename, tweet_text)
    else
      puts tweet_text
    end

    STDERR.puts "\nAll tweets scraped" if @verbose
  end

  private

  def extract_tweets_from_html(html)
    res = Nokogiri::HTML(html)
    res.css("div[class~='tweet']").map do |tweet|
      {
        fullname: tweet.css("strong[class~='fullname']").text.strip,
        username: tweet.css("span[class~='username']").text.strip,
        posted_time: tweet.css("span[class~='_timestamp']").first['data-time'].to_i,
        body: tweet.css("div[class='js-tweet-text-container']").text.strip,
        reply_count: tweet.at_css("div[class~='ProfileTweet-actionList']").css("div[class~='ProfileTweet-action--reply']").text.scan(/([0-9]+)/).flatten[0].to_i,
        retweet_count: tweet.at_css("div[class~='ProfileTweet-actionList']").css("div[class~='ProfileTweet-action--retweet']").text.scan(/([0-9]+)/).flatten[0].to_i,
        favorite_count: tweet.at_css("div[class~='ProfileTweet-actionList']").css("div[class~='ProfileTweet-action--favorite']").text.scan(/([0-9]+)/).flatten[0].to_i
      }
    end
  end

  def tweet_text
    return @pretty_print ? JSON.pretty_generate(@tweets) : @tweets.to_json
  end

  def print_update
    delta = Time.now - @started_at
    STDERR.print "Tweets scraped: #{@tweets.count}\tTime elapsed: #{Time.at(delta.to_i.abs).utc.strftime "%H:%M:%S"}"
  end
end
