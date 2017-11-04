# tweet-scrape
Command line tool that scrapes tweets by reverse-engineering Twitter's AJAX requests.

Does not require Twitter API access. The only limits are your internet connection and how many tweets exist that match your query.

### Usage
By default tweet-scrape will scrape tweets until it receives an interrupt or scrapes all tweets matching the given query, then outputs the JSON-formatted tweets to standard out.
```
Usage: tweet-scrape.rb [options] SEARCH_TERM
    -l, --limit LIMIT                Maximum number of tweets to scrape
    -p, --pretty                     Pretty print JSON
    -f, --file FILE                  Write to file
    -c, --continuous                 Continously write to file after every batch of tweets
    -v, --verbose                    Print informational messages to STDERR
    -h, --help                       Prints help
```

### Installation
```
git clone https://github.com/aopal/tweet-scrape
gem install bundler
bundle install
```
