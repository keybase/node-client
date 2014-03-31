TwitterScraper = require './src/twitter_scraper.iced'

# -------------------------------------------------------------------------------------------------

scraper = new TwitterScraper()

# -------------------------------------------------------------------------------------------------

console.log "Testing direct lookup."
await scraper.check_status "malgorithms", "400699000954699777", "bitcoin", defer err
if err?
  console.log "Error: #{err}"

# -------------------------------------------------------------------------------------------------

console.log "Testing hunt method."
await scraper.hunt "malgorithms", "Beer", defer err, tweet_id
if err?
  console.log "Error: #{err}"
else
  console.log " -- Testing found post."
  await scraper.check_status "malgorithms", tweet_id, "Beer", defer err
  if err?
    console.log "Error: #{err}"

# -------------------------------------------------------------------------------------------------

console.log "Testing bad case on username."
await scraper.hunt "MALGORITHMS", "Beer", defer err, tweet_id
if err?
  console.log "Error: #{err}"
else
  console.log " -- Testing found post."
  await scraper.check_status "MALGORITHMS", tweet_id, "Beer", defer err  
  if err?
    console.log "Error: #{err}"

console.log "Testing protected user."
await scraper.hunt "foo", "Beer", defer err, tweet_id
console.log "Response: #{err}, #{tweet_id}"


# -------------------------------------------------------------------------------------------------

console.log "Testing hunting for shit which doesn't exist."
await scraper.hunt "malgorithms", "BOOYEAH WHOO HAH.", defer err, tweet_id
console.log "Response: #{err}, #{tweet_id}"


