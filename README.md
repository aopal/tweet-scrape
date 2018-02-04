# tweet-scrape
Command line tool that scrapes tweets by reverse-engineering Twitter's AJAX requests.

Does not require Twitter API access. The only limits are your internet connection and how many tweets exist that match your query.

### Installation
```
git clone https://github.com/aopal/tweet-scrape
gem install bundler
bundle install
```

### Usage
By default tweet-scrape will scrape tweets until it receives an interrupt (Ctrl-C) or scrapes all tweets matching the given query, then outputs the JSON-formatted tweets to standard out.
```
Usage: tweet-scrape.rb [options] SEARCH_TERM
    -l, --limit LIMIT                Maximum number of tweets to scrape
    -p, --pretty                     Pretty print JSON
    -f, --file FILE                  Write data to a file
    -c, --continuous                 Continously write/print results in CSV format after every batch of tweets
    -v, --verbose                    Print informational messages to STDERR
    -h, --help                       Prints help
```

Verbose mode is recommended when first using tweet-scrape. Continuous mode is recommended for large scraping jobs in case the script is killed or encounters an error. Continuous mode works best when writing directly to a file instead of standard output.

### Sample Data
[sample.json](sample.json)
[sample_pretty.json](sample_pretty.json)
[sample.csv](sample.csv)
