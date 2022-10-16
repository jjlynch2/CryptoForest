module CryptoForest
    using Distributed

    #export open_coinbase_websocket, save_coinbase_ticker, save_coinbase_orderbook

    @everywhere using JSON3, Dates, WebSockets, Sockets, Printf, LibPQ


#for dev
cd("C:\\Users\\jeffr\\Desktop\\personal\\TradingCode\\CryptoForest\\src")

    #API URLs
    coinbase_rest_url = "https://api.pro.coinbase.com/products/"
    coinbase_websocket_url = "wss://ws-feed.exchange.coinbase.com"
    binance_rest_url = "https://api.binance.us/api/v3/"
    binance_websocket_url = "wss://stream.binance.us:9443"
    binance_streams = []
    coinbase_streams = ["heartbeat", "ticker", "level2_batch"]

    crypto_pairs = [["BTC","USD"], ["ETH","USD"]]#, ["ETH","BTC"]]
    depth = 0.01 #limit order book depth

    include("websockets_helpers.jl")
    include("websockets.jl")
    include("structures.jl")
    include("buffers.jl")
    include("misc.jl")
    #include("metrics.jl")
    include("database.jl")

    db_info = database_info("192.168.0.1", 9009) #QuestDB details
    crypto = crypto_info(crypto_pairs, coinbase_streams, binance_streams)

    payload = build_coinbase_payload(crypto)
    @async open_coinbase_websocket(coinbase_websocket_url, payload, coinbasetrade, coinbaseorderbook, false, depth)
    @async save_coinbase_ticker(coinbasetrade, db_info)
    @async save_coinbase_orderbook(coinbaseorderbook, db_info)


end
