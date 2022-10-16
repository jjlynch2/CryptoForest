function CryptoForest(url, payload, coinbasetrade, coinbaseorderbook, restart, depth)

end

function get_coinbase_snapshot(db_info, ticker)
    conn = LibPQ.Connection("""dbname=qdb host=$(db_info.address) port=8812 password=quest user=admin""")
    execute(conn)
    close(conn)
end

