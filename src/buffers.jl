##database buffers
const coinbaseorderbook = RemoteChannel(()->Channel{CoinbaseOrderBook}(1000)); #every 1,000 entries
const coinbasetrade = RemoteChannel(()->Channel{CoinbaseTrade}(1000)); #every 1,000 entries
