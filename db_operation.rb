# DB operation file

# Find the booksDB userid that corresponds to the LINE UserID(Operate userindexDB)
def find_id(connect, userid)
    results = connect.exec("SELECT * FROM userindex;")
    return reply_id(connect, results, userid)  # Return the found userid of the booksDB
end

# Return the found userid of the booksDB, or create userid
def reply_id(connect, results, userid)
    results.each do |result|
        if result['userid'] == userid
            return result['id']
        end
    end
    connect.exec("INSERT INTO userindex (userid) VALUES ('#{userid}');")
    return find_id(connect, userid)
end

# Find information(id, title) abount the user's books
def find_books(connect, id)
    results = connect.exec("SELECT * FROM books where userid=#{id};")
    books = []
    results.each do |result|
        books << {"id"=>result['id'], "title"=>result['title']}
    end
    return books
end

# Delete user's book
def delete(connect, book_id)
    results = connect.exec("delete from books where id=#{book_id.to_i};")
end