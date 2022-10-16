##save trade entries to database; call as async or on separate proc
function save_coinbase_ticker(coinbasetrade, db_info)
    cs = connect(db_info.address, db_info.port)
    while true
        if !isopen(cs)
            cs = connect(db_info.address, db_info.port)
        end
        payload = build_payload_coinbasetrade(take!(coinbasetrade))
        write(cs, (payload))
    end
    close(cs)
end

##save orderbook entries to database; call as async or on separate proc
function save_coinbase_orderbook(coinbaseorderbook, db_info)
    cs = connect(db_info.address, db_info.port)
    while true
        if !isopen(cs)
            cs = connect(db_info.address, db_info.port)
        end
        payload = build_payload_coinbaseorderbook(take!(coinbaseorderbook))
        write(cs, (payload))
    end
    close(cs)
end

##drop existing table and save snapshot
function save_coinbase_snapshot(coinbase_orderbook, ticker, db_info)
    conn = LibPQ.Connection("""dbname=qdb host=$(db_info.address) port=8812 password=quest user=admin""")
    execute(conn, """DROP TABLE IF EXISTS 'coinbase_orderbook_snapshot_$ticker';""")
    close(conn)

    cs = connect(db_info.address, db_info.port)
    for side in keys(coinbase_orderbook)
        for price in keys(coinbase_orderbook["$side"])
            payload = build_payload_coinbaseorderbook_snapshot(coinbase_orderbook["$side"]["$price"])
            write(cs, (payload))
        end
    end
    close(cs)
end

##parse time to unix
function parse_timestamp(ts::String)
    p1, p2 = split(ts, ".")
    ut = datetime2unix(DateTime(p1)) * 1e9
    ns = Nanosecond(rpad(chop(String(p2), tail=1), 9, "0"))
    @sprintf "%.0f" ut + ns.value
end

##parse time to unix
function parse_timestamp2(ts::Int64)
    unix2datetime(ts / 1e9) #convert nanoseconds back to normal ISO 8602 UTC time
end

##QuestDB Payload for coinbase trade entry
function build_payload_coinbasetrade(x::CoinbaseTrade)
    buff = IOBuffer()
    write(buff, "coinbase_trades_$(getfield(x, :ticker)),") #append ticker to make it a new table
    write(buff, "ticker=$(getfield(x, :ticker)),")
    write(buff, "id=$(getfield(x, :id)),")
    write(buff, "price=$(getfield(x, :price)),")
    write(buff, "open_24h=$(getfield(x, :open_24h)),")
    write(buff, "volume_24h=$(getfield(x, :volume_24h)),")
    write(buff, "low_24h=$(getfield(x, :low_24h)),")
    write(buff, "high_24h=$(getfield(x, :high_24h)),")
    write(buff, "volume_30d=$(getfield(x, :volume_30d)),")
    write(buff, "best_bid=$(getfield(x, :best_bid)),")
    write(buff, "best_ask=$(getfield(x, :best_ask)),")
    write(buff, "size=$(getfield(x, :size)),")
    write(buff, "side=$(getfield(x, :side)),")
    write(buff, "low_24h=$(getfield(x, :low_24h)) ")
    tspretty = parse_timestamp(getfield(x, :time))
    write(buff, tspretty)
    write(buff, "\n")
    String(take!(buff))
end

##QuestDB Payload for coinbase orderbook entry
function build_payload_coinbaseorderbook(x::CoinbaseOrderBook)
    buff = IOBuffer()
    write(buff, "coinbase_orderbook_$(getfield(x, :ticker)),") #append ticker to make it a new table
    write(buff, "ticker=$(getfield(x, :ticker)),")
    write(buff, "price=$(getfield(x, :price)),")
    write(buff, "size=$(getfield(x, :size)),")
    write(buff, "side=$(getfield(x, :side)) ")
    tspretty = parse_timestamp(getfield(x, :time))
    write(buff, tspretty)
    write(buff, "\n")
    String(take!(buff))
end

##QuestDB Payload for coinbase orderbook entry
function build_payload_coinbaseorderbook_snapshot(x::CoinbaseOrderBook)
    buff = IOBuffer()
    write(buff, "coinbase_orderbook_snapshot_$(getfield(x, :ticker)),") #append ticker to make it a new table
    write(buff, "ticker=$(getfield(x, :ticker)),")
    write(buff, "price=$(getfield(x, :price)),")
    write(buff, "size=$(getfield(x, :size)),")
    write(buff, "side=$(getfield(x, :side)) ")
    tspretty = parse_timestamp(getfield(x, :time))
    write(buff, tspretty)
    write(buff, "\n")
    String(take!(buff))
end
