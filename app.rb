require 'bundler/setup'
require 'sinatra'
require 'line/bot'
require 'pg'
require_relative 'button'
require_relative 'db_operation'

id = ""     # LINEuserID

# Information for connecting to postgresql
connect = PG::connect(
    host: ENV["PSQL_HOST"],
    user: ENV["PSQL_USER"],
    password: ENV["PSQL_PASS"],
    dbname: ENV["PSQL_DBNAME"],
    port: "5432"
)

# Book new registration form or List page of all books of the user
get '/' do
    if @env["QUERY_STRING"].empty?  # new registration
        erb :booknew
    else
        # List page of all books
        @id = id
        @results = connect.exec("SELECT * FROM books where userid=#{@id};")
        erb :index
    end
end

# Page where the book registration completion message is displayed
post '/book' do
    @title = params[:title]
    @author = params[:author]
    @publisher = params[:publisher]
    @error = true unless connect.exec("INSERT INTO books (userid, title, author, publisher) VALUES (#{id.to_i}, '#{@title}', '#{@author}', '#{@publisher}');")
    erb :book
end


# Messaging API
def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
end
  
post '/callback' do
    body = request.body.read
  
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      halt 400, {'Content-Type' => 'text/plain'}, 'Bad Request'
    end
  
    events = client.parse_events_from(body)
  
    events.each do |event|
        userid = event['source']['userId']
        id = find_id(connect, userid)
        case event
        when Line::Bot::Event::Message
            case event.type
            when Line::Bot::Event::MessageType::Text
                if event.message['text'] == "new"   # New registration of books
                    client.reply_message(event['replyToken'], form)
                elsif event.message['text'] == "how to use"  # How to use
                    message1 = {
                        type: 'text',
                        text: "まずは「Add a new book」で本を登録しましょう！"
                    }
                    message2 = {
                        type: 'text',
                        text: "登録した本は「View all books」で見ることができます"
                    }
                    message3 = {
                        type: 'text',
                        text: "本を削除する場合は、本のタイトルの一部を入力するか、「Delete a book」をタップしてください"
                    }
                    client.reply_message(event['replyToken'], [message1, message2, message3])
                else
                    # Message when the book is not found
                    no_book = {
                        type: 'text',
                        text: "まだ本が登録されていないか、該当する本がありません"
                    }
                    # View all books or Delete books
                    books = find_books(connect, id)  # Find books information
                    if books.empty?                  # If the book is not found
                        client.reply_message(event['replyToken'], no_book)
                    end
                    if event.message['text'] == "index"  # View the list of registered books
                        book_title = []
                        count = 0          # How many books
                        # Get book's title and how many books user has
                        books.each do |x|
                            count += 1
                            book_title << "・#{x['title']}"
                        end
                        message = {
                            type: 'text',
                            text: "#{count}冊の本が見つかりました"
                        }
                        book_text = {
                            type: 'text',
                            text: book_title.join("\n")
                        }
                        client.reply_message(event['replyToken'], [message, book_text, show_books])
                    elsif event.message['text'] =~ /\A[0-9]+\z/  # if a number is entered, delete the book
                        book_id = ""
                        title = ""
                        # Get the information of the book whose ID matches the entered number
                        books.each do |x|
                            if x['id'] == event.message['text']
                                book_id = x['id']
                                title = x['title']
                            end
                        end
                        if book_id.empty?  # if the book is not found
                            client.reply_message(event['replyToken'], no_book)
                        else    # delete confirmation bottun
                            client.reply_message(event['replyToken'], delete_book(title, book_id))
                        end
                    else   # if strings are entered, search book's title
                        inp_title = event.message['text']
                        book_info = []   # Information about id and title of the books
                        book_title = []
                        book_id = []
                        count = 0        # How many books
                        # Get information about books
                        books.each do |x|
                            if inp_title == "delete"     # if 「delete」is entered, find user's all books
                                book_title << x['title']
                                book_id << x['id']
                                book_info << "・ID #{x['id']}：#{x['title']}"
                                count += 1
                            else                         # search book's title
                                if x['title'] =~ /#{inp_title}/
                                    book_title << x['title']
                                    book_id << x['id']
                                    book_info << "・ID #{x['id']}：#{x['title']}"
                                    count += 1
                                end
                            end
                        end
                        # Reply massage
                        if count == 0    # If books are not found
                            message = {
                                type: 'text',
                                text: "「#{inp_title}」という本は見つかりませんでした"
                            }
                            client.reply_message(event['replyToken'], message)
                        elsif count == 1  # If only one book is found, ask if user wants to delete it
                            client.reply_message(event['replyToken'], delete_book(book_title[0], book_id[0]))
                        else  # If some books are found, display the list
                            message = {
                                type: 'text',
                                text: "#{count}冊の本がヒットしました。\n\n削除する本のIDを半角で入力してください"
                            }
                            book_text = {
                                type: 'text',
                                text: book_info.join("\n")
                            }
                            client.reply_message(event['replyToken'], [message, book_text])
                        end
                    end
                end
            end
        when Line::Bot::Event::Postback
            # When user taps the button, delete the book from booksDB
            ar = event['postback']['data'].split(",")
            if ar[0] == "delete"
                delete(connect, ar[1])
                message = {
                    type: 'text',
                    text: "削除しました"
                }
                client.reply_message(event['replyToken'], message)
            end
        end
    end
  
    "OK"
end