require 'optparse'
require './api.rb'

options = {}
usage = nil
OptionParser.new do |parser|
  parser.banner = "Usage: tweet-scrape.rb [options] SEARCH_TERM"

  parser.on("-l", "--limit LIMIT", "Maximum number of tweets to scrape") do |lim|
    options[:limit] = lim.to_i
  end

  parser.on("-p", "--pretty", "Pretty print JSON") do |pretty|
    options[:pretty_print] = pretty
  end

  parser.on("-f", "--file FILE", "Write to file") do |filename|
    options[:file] = filename.gsub(/[^0-9A-Za-z.\-_]/, '')
  end

  parser.on("-c", "--continuous", "Continously write to file after every batch of tweets") do |c|
    options[:continuous] = c
  end

  parser.on("-v", "--verbose", "Print informational messages to STDERR") do |v|
    options[:verbose] = v
  end

  parser.on("-h", "--help", "Prints help") do
    puts parser
    exit
  end
  usage = parser
end.parse!

if ARGV.empty?
  puts usage
  exit
end

options[:query] = ARGV[0]

TweetScraper.new(options).scrape()
