##helper function to identify data type received
function identify_data_coinbase(data)
    if get(data, "type", "") == "heartbeat"
        @info("Coinbase heartbeat received at $(get(data, "time", ""))...")
        return nothing
    elseif get(data, "type", "") == "ticker"
        return 1
    elseif get(data, "type", "") == "snapshot"
        return 2
    elseif get(data, "type", "") == "l2update"
        return 3
    end
end

##helper function to pull price
function price_key(data, c)
    data[:changes][c][2]
end

##helper function to pull size
function size_key(data, c)
    data[:changes][c][3]
end

##helper function to pull side
function side_key(data, c)
    data[:changes][c][1]
end

##helper function to ticker/pairs
function ticker_key(data)
    data[:product_id]
end

##helper function to time
function time_key(data)
    data[:time]
end

##helper function to change side to bid/ask
function side_key_swap(data, c)
    if side_key(data, c) == "buy"
        return "bids"
    else
        return "asks"
    end
end

##parsing function for coinbase trades
function parse_coinbase_ticker(data, coinbasetrade)
    ticker = get(data, "product_id", "")
    price = parse(Float64, get(data, "price", "NaN"))
    open_24h = parse(Float64, get(data, "open_24h", "NaN"))
    volume_24h = parse(Float64, get(data, "volume_24h", "NaN"))
    low_24h = parse(Float64, get(data, "low_24h", "NaN"))
    high_24h = parse(Float64, get(data, "high_24h", "NaN"))
    volume_30d = parse(Float64, get(data, "volume_30d", "NaN"))
    best_bid = parse(Float64, get(data, "best_bid", "NaN"))
    best_ask = parse(Float64, get(data, "best_ask", "NaN"))
    side = get(data, "side", "")
    ts = get(data, "time", "")
    id = get(data, "trade_id", "")
    size = parse(Float64, get(data, "last_size", "NaN"))
    clean_data = CoinbaseTrade(ticker, ts, string(id), price, open_24h, volume_24h, low_24h, high_24h, volume_30d, best_bid, best_ask, size, side)
    if !isempty(clean_data)
        put!(coinbasetrade, clean_data)
    end
end

##parsing function for coinbase limit order book snapshot
function parse_coinbase_snapshot(data, coinbaseorderbook, depth)
    ticker = data[:product_id]
    bids = data[:bids]
    asks = data[:asks]
    ts = string(now(Dates.UTC)) #UTC time for received full snapshot (API doesn't provide a time for this for some reason?!)
    buy = Dict()
    best_bid_depth = parse(Float64, bids[1][1]) - parse(Float64, bids[1][1]) * depth #1% depth from best bid from first/best entry in orderbook
    best_ask_depth = parse(Float64, asks[1][1]) + parse(Float64, asks[1][1]) * depth #1% depth from best ask from first/best entry in orderbook
    for i in 1:length(bids)
        price = tryparse(Float64, bids[i][1])
        if price >= best_bid_depth #book depth to save
            size = tryparse(Float64, bids[i][2])
            side = "buy"
            buy["$price"] = CoinbaseOrderBook(ticker, ts, price, size, side)
            put!(coinbaseorderbook, buy["$price"]) #put initial orderbook into buffer; Since this is only done once, it is not too much of a time crunch
        end
    end
    sell= Dict()
    for i in 1:length(asks)
        price = tryparse(Float64, asks[i][1])
        if price <= best_ask_depth #book depth to save
            size = tryparse(Float64, asks[i][2])
            side = "sell"
            sell["$price"] = CoinbaseOrderBook(ticker, ts, price, size, side)
            put!(coinbaseorderbook, sell["$price"]) #put initial orderbook into buffer; Since this is only done once, it is not too much of a time crunch
        end
    end
    OB = Dict()
    OB["bids"] = buy
    OB["asks"] = sell
    return OB
end
