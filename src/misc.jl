##build coinbase websocket subscribe payload
function build_coinbase_payload(crypto)
    Dict(
        :type => "subscribe",
        :product_ids => join.(crypto.ticker, "-"),
        :channels => crypto.coinbase_streams
    )
end
