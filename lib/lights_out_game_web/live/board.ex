defmodule LightsOutGameWeb.Board do
  use LightsOutGameWeb, :live_view

  @game_length 10

  def mount(_params, _session, socket) do
    {:ok, assign(socket, grid: %{}, win: "playing", turns: 0, chosen: [], active_tiles: 15)}
  end

  def handle_params(params, _uri, socket) do
    grid = reset_grid()

    case params["game_id"] do
      game when not is_nil(game) ->
        game_id = String.to_integer(game)
        {:noreply, assign(socket, game: game_id, grid: load_game(grid), win: "playing")}

      _ ->
        {:noreply, push_patch(socket, to: "/1")}
    end
  end

  def handle_event("toggle", %{"x" => strX, "y" => strY}, socket) do
    # Check if the turn limit has been reached or exceeded, or if the location clicked is in the chosen list.
    if socket.assigns.turns >= @game_length or Enum.any?(socket.assigns.chosen, fn coord -> coord == {String.to_integer(strX), String.to_integer(strY)} end) do
      # If so, do not process the click and return the socket unchanged.
      {:noreply, socket}
    else
      # Existing logic for handling the click.
      grid = socket.assigns.grid
      turns = socket.assigns.turns
      grid_x = String.to_integer(strX)
      grid_y = String.to_integer(strY)
      chosen = [{grid_x, grid_y}] ++ socket.assigns.chosen
      direction = rem(turns, 3)

      updated_grid =
        find_knight_moves(grid_x, grid_y, direction)
        |> Enum.reduce(%{}, fn point, acc ->
          Map.put(acc, point, !grid[point])
        end)
        |> then(fn toggled_grid -> Map.merge(grid, toggled_grid) end)

      # Calculate the win condition and the number of active tiles.
      win = check_win(updated_grid, turns + 1)
      active_count = Enum.count(updated_grid, fn {_key, value} -> value end) # Count how many tiles are true (active).

      # Assign the updated grid, win condition, turn count, chosen tiles, and active tile count to the socket.
      socket =
        assign(socket, grid: updated_grid, win: win, turns: turns + 1, chosen: chosen, active_tiles: active_count)

      case win do
        "red" -> {:noreply, push_event(socket, "gameover", %{win: win})}
        "blue" -> {:noreply, push_event(socket, "gameover", %{win: win})}
        _ -> {:noreply, socket}
      end
    end
  end

  def handle_event("bot_move", _params, socket) do
    # Only proceed if the game is still ongoing and the turn limit hasn't been exceeded.
    if socket.assigns.turns < @game_length do
      direction = rem(socket.assigns.turns, 3)
      {optimal_x, optimal_y} = find_optimal_move(socket.assigns.grid, socket.assigns.chosen, direction)

      # Now proceed as if "optimal_x, optimal_y" were clicked by the bot.
      chosen = [{optimal_x, optimal_y}] ++ socket.assigns.chosen

      updated_grid =
        find_knight_moves(optimal_x, optimal_y, direction)
        |> Enum.reduce(%{}, fn point, acc ->
          Map.put(acc, point, !socket.assigns.grid[point])
        end)
        |> then(fn toggled_grid -> Map.merge(socket.assigns.grid, toggled_grid) end)

      # Update win condition, active tiles count, etc., similarly to the "toggle" event.
      win = check_win(updated_grid, socket.assigns.turns + 1)
      active_count = Enum.count(updated_grid, fn {_key, value} -> value end)

      new_assigns = [
        grid: updated_grid,
        win: win,
        turns: socket.assigns.turns + 1,
        chosen: chosen,
        active_tiles: active_count
      ]

      socket = assign(socket, new_assigns)

      # Check if the game has ended and push the "gameover" event if so.
      if win == "red" do
        {:noreply, push_event(socket, "gameover", %{win: win})}
      else
        {:noreply, socket}
      end
    else
      # If the turn limit has been reached, don't allow the bot to make a move.
      {:noreply, socket}
    end
  end



  def find_optimal_move(grid, chosen, direction) do
    # Generate all possible positions on the grid (assuming a 5x5 grid for simplicity)
    all_positions = for x <- 0..4, y <- 0..4, do: {x, y}

    # Filter out the positions that have already been chosen
    unchosen_positions = Enum.filter(all_positions, fn position -> not Enum.member?(chosen, position) end)

    # Iterate over each unchosen position, simulating its selection and calculating the effect
    unchosen_positions
    |> Enum.map(fn position -> {position, simulate_toggle(position, grid, direction)} end)
    |> Enum.max_by(fn {_position, deactivation_count} -> deactivation_count end)
    |> elem(0)
  end

  defp simulate_toggle({x, y}, grid, direction) do
    # Find the tiles that would be toggled by this move given the direction
    toggled_tiles = find_knight_moves(x, y, direction)

    # Calculate how many of these tiles are currently "on" and would be turned "off" by this move
    Enum.count(toggled_tiles, fn {tx, ty} ->
      Map.get(grid, {tx, ty}, false)
    end)
  end

  defp find_knight_moves(x, y, dir) do
    moves = [
      {x + 2, y + 1},
      {x + 2, y - 1},
      {x - 2, y + 1},
      {x - 2, y - 1},
      {x + 1, y + 2},
      {x + 1, y - 2},
      {x - 1, y + 2},
      {x - 1, y - 2},
      {x, y}
    ]

    moves
    |> Enum.filter(fn {nx, ny} ->
      case dir do
        0 -> nx <= x
        1 -> ny >= y
        2 -> nx >= x
        _ -> true
      end
    end)
    |> Enum.filter(fn {nx, ny} ->
      nx >= 0 and nx <= 4 and ny >= 0 and ny <= 4
    end)
  end

  defp reset_grid do
    for x <- 0..4, y <- 0..4, into: %{}, do: {{x, y}, false}
  end

  defp load_game(grid) do
    all_positions = Map.keys(grid)
    selected_positions = Enum.shuffle(all_positions) |> Enum.take(15)

    Enum.reduce(selected_positions, grid, fn position, acc ->
      Map.put(acc, position, true)
    end)
  end



  defp check_win(grid, turns) do
    if turns < @game_length do
      "playing"
    else
      activated_count = Enum.count(Map.values(grid), &(&1 == true))
      total_count = Kernel.map_size(grid)
      half_count = total_count / 2

      case activated_count do
        _ when activated_count > half_count -> "red"
        _ when activated_count < half_count -> "blue"
        _ -> "tie"
      end
    end
  end

end
