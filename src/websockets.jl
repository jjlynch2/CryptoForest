##open websocket
function open_coinbase_websocket(url, payload, coinbasetrade, coinbaseorderbook, restart, depth)
    coinbase_orderbook = Dict() #LOB maintained
    book_depth = Dict()
    snapshot_time = Dict()
    WebSockets.open(url) do ws
        if isopen(ws)
            write(ws, JSON3.write(payload))
        end
        while isopen(ws)
            data, success = readguarded(ws)
            if success
                data = JSON3.read(String(data))
                which_data = identify_data_coinbase(data)
                if which_data == 1
                    parse_coinbase_ticker(data, coinbasetrade)
                    local_ticker = ticker_key(data)
                    #used for LOB
                    best_bid_depth = parse(Float64, get(data, "best_bid", "NaN")) - parse(Float64, get(data, "best_bid", "NaN")) * depth #1% depth from best bid
                    best_ask_depth = parse(Float64, get(data, "best_ask", "NaN")) + parse(Float64, get(data, "best_ask", "NaN")) * depth #1% depth from best ask
                    book_depth["$local_ticker"] = [best_bid_depth, best_ask_depth]
                elseif which_data == 2 #check if depth has been updated first
                    local_ticker = ticker_key(data)
                    OB = parse_coinbase_snapshot(data, coinbaseorderbook, depth)
                    coinbase_orderbook["$local_ticker"] = OB #save full orderbook to parent dictionary
                    save_coinbase_snapshot(coinbase_orderbook["$local_ticker"], local_ticker, db_info) #save snapshot to separate table
                    snapshot_time["$local_ticker"] = now()
                elseif which_data == 3
                    #create outside loop since it never changes per update
                    tk = ticker_key(data)
                    tik = time_key(data)
                    for c in 1:length(data[:changes])
                        #local variables to avoid accessing data again
                        pk = tryparse(Float64, price_key(data, c))
                        sik = side_key(data, c)
                        if pk >= book_depth["$tk"][1] && sik == "buy" ||  pk <= book_depth["$tk"][2] && sik == "sell" #book depth to save
                            sk = tryparse(Float64, size_key(data, c))
                            sks = side_key_swap(data, c)
                            if sk == 0 #coinbase returns 0 for size when removed from limit order book
                                put!(coinbaseorderbook, CoinbaseOrderBook(tk, tik, pk, sk, sik)) #put an entry with the 0 size so I can detect later on when pulling data from the database
                                delete!(coinbase_orderbook[tk][sks], "$pk") #delete from maintained dictionaries
                            else
                                coinbase_orderbook[tk][sks]["$pk"] = CoinbaseOrderBook(tk, tik, pk, sk, sik) #add new if key (price) isn't present or overwrite the existing dictionary
                                put!(coinbaseorderbook, coinbase_orderbook[tk][sks]["$pk"]) #store updated portion of the book in QuestDB
                            end
                        end
                        if now() - snapshot_time["$tk"] >= Millisecond(300000) #5 minutes
                            save_coinbase_snapshot(coinbase_orderbook["$tk"], tk, db_info) #save snapshot to separate table
                            snapshot_time["$tk"] = now()
                        end
                    end
                end
            end
            #restart if closed
            if restart && !isopen(ws)
                open_coinbase_websocket(payload, coinbasetrade, coinbaseorderbook, restart, depth)
            end
        end
    end
end
