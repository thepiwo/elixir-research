defmodule Aehttpserver.Web.MarketController do
  use Aehttpserver.Web, :controller

  alias Aecore.Chain.Worker, as: Chain
  alias Aecore.Keys.Worker, as: Keys
  alias Aecore.Txs.Pool.Worker, as: Pool
  alias Aeutil.Serialization
  alias Aecore.Structures.TravelMarketTx

  def market(conn, params) do
    chain = Chain.longest_blocks_chain()
    chain_txs = chain |> Enum.flat_map(fn block -> block.txs end)
    market_txs = chain_txs |> Enum.filter(fn tx ->
      case tx.data do
        %TravelMarketTx{} ->
         true
        _ ->
          false
      end
    end)
    market_txs_json = market_txs |> Enum.map(fn tx -> Serialization.tx(tx, :serialize) end)
    json conn, market_txs_json
  end

  def offer(conn, _params) do
    {:ok, pubkey} = Keys.pubkey()
    chain_state = Chain.chain_state()
    next_nonce = if Map.has_key?(chain_state, pubkey) do
      chain_state[pubkey].nonce + 1
    else
      1
    end

    request = Poison.decode!(Poison.encode!(conn.body_params), [keys: :atoms])
    ttl = if Map.has_key?(request, :ttl) do
      request.ttl
    else
      Chain.top_height() + 1000
    end

    market_tx = %TravelMarketTx{
      from_acc: pubkey,
      nonce: next_nonce,
      fee: 5,
      price: request.price,
      type: :offer,
      date: request.date,
      capacity: request.capacity,
      travel_time: request.travel_time,
      ttl: ttl,
      from: request.from,
      to: request.to}

    {:ok, signed_tx} = Keys.sign_tx(market_tx)
    Pool.add_transaction(signed_tx)
    json conn, %{ok: "added offer to pool"}
  end

  def demand(conn, _params) do
    {:ok, pubkey} = Keys.pubkey()
    chain_state = Chain.chain_state()
    next_nonce = if Map.has_key?(chain_state, pubkey) do
      chain_state[pubkey].nonce + 1
    else
      1
    end

    request = Poison.decode!(Poison.encode!(conn.body_params), [keys: :atoms])
    ttl = if Map.has_key?(request, :ttl) do
      request.ttl
    else
      Chain.top_height() + 1000
    end

    market_tx = %TravelMarketTx{
      from_acc: pubkey,
      nonce: next_nonce,
      fee: 5,
      price: request.price,
      type: :demand,
      date: request.date,
      capacity: request.capacity,
      travel_time: request.travel_time,
      ttl: ttl,
      from: request.from,
      to: request.to}

    {:ok, signed_tx} = Keys.sign_tx(market_tx)
    Pool.add_transaction(signed_tx)
    json conn, %{ok: "added demand to pool"}
  end

end