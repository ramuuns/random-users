# RandomUsers

A job-application exercise for an $EMPLOYER

## Requirements 

This is more of a "this is what I have on my machine in case of any errors/warnings that might arise from environmental differences"
- elixir 1.14
- postgres

## Setup

- clone the repo
- run `mix deps.get && mix ecto.setup && mix phx.server` and you should have an application

## Where is anything?

The _interesting_ files are [lib/random_users/min_number.ex](lib/random_users/min_number.ex) which has all the logic, and, I suppose, [lib/random_users_web/controllers/index_controller.ex](lib/random_users_web/controllers/index_controller.ex)
which contains the json conversion and calls the code defined in the former.

## So can you describe what you did here, and what approaches did you take and why and which you didn't?

Right, so most things should be fairly self-explanatory – there's a GenServer (A thing that holds state and is a process),
that repeatedly tells itself to update the database every minute, and also to fetch a new random integer. I suppose the _interesting_ 
part here is how do we update the database. There were several options that could be taken:
1) Query all the data using ecto, then use changesets on each row and push that row back into the db. "The naive approach", as I'd call it.  
  pros: I guess that this would let you make use of those timestamps() macros that ecto helpfully provides  
  cons: awkward code to write, slow (what with updating one row at a time and we have at least a million of them)
2) Issue one big-old update statement (essentially an `"UPDATE users SET points = floor(random()*101), updated_at = NOW()"`)  
  This is better than the 1st approach, but only marginally so - what looks like a simple and trivial statement from our application side is
  a full table scan that just moves the awful `for (int i = 0; i < 1000000; i++) { do awful update work }` into the database and, well,
  database primary servers are precious and one should take great care to not overwhelm them with work.
3) So what we do instead is nr 2, but in batches (I picked an arbitrary nr of 5K, but realistically you can probably go up to 10 - 20 K, testing
should would be advised to find the optimal number) and in a transaction (which, makes it compatible with option 2 from the point of view of a user of
the DB).  
  So why this? Each individual update query is such that the work that we make the DB do is rather small (while still relatively convenient to
  write), thus while the database gets to do the same amount of work, it's somewhat smeared out in time, and allows it to do other things while we run our 
  awful update, this also allows us to trivially add a bit of jittered sleep after each query, that would make it ok to run even if the table was a 100 times larger, especially if we dropped the transaction and ran them as individual update queries (which, depending on our requirements might or might not be ok).


## other notes

I initially wanted to completely drop the timestamp columns, since they don't add much benefit in this exercise (except for making the DB work more), however I found that with the implementation that I ended up having it was fairly irrelevant if they were there or not, and since the spec was asking for them, I decided to add them back in :)
