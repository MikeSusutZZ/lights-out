# LightsOutGame modification: Knight's Quest

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

# How to play
When you click a tile, that tile and all tiles in a knight's move either above, below, or right of where you clicked will be toggled. Direction is specified above the grid, and cycles up, right, down, up...
The goal is to make over half (13) tiles to be your color by the end of 10 turns.

Once a tile has been clicked by either player, it can no longer be clicked by either player.
Because blue is "The hammer" and thus has the advantage, red starts with more tiles.
The board starts as a random position of 15 red and 10 blue tiles

If playing alone, play as red and on blue's turn, hit the bot move button!
