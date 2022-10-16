##basic crypto information
mutable struct crypto_info
    ticker::Vector
    coinbase_streams::Vector
    binance_streams::Vector
end

##QuestDB information
mutable struct database_info
    address::String
    port::Int64
end

##Coinbase trade entry
struct CoinbaseTrade
    ticker::String
    time::String
    id::String
    price::Float64
    open_24h::Float64
    volume_24h::Float64
    low_24h::Float64
    high_24h::Float64
    volume_30d::Float64
    best_bid::Float64
    best_ask::Float64
    size::Float64
    side::String
end

CoinbaseTrade() = CoinbaseTrade("", "", "", NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, "")
Base.isempty(x::CoinbaseTrade) = x.ticker == ""

##Coinbase orderbook entry
struct CoinbaseOrderBook
    ticker::String
    time::String
    price::Float64
    size::Float64
    side::String
end

CoinbaseOrderBook() = CoinbaseOrderBook("", "",  NaN, NaN, "")
Base.isempty(x::CoinbaseOrderBook) = x.ticker == ""
