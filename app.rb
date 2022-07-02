require 'bundler/setup'
require 'sinatra'
require 'line/bot'
require 'pg'
require_relative 'button'

id = ""
connect = PG::connect(
    host: ENV["PSQL_HOST"],
    user: ENV["PSQL_USER"],
    password: ENV["PSQL_PASS"],
    dbname: ENV["PSQL_DBNAME"],
    port: "5432"
)

get '/' do   # 登録form
    p @env["QUERY_STRING"]
    if @env["QUERY_STRING"].empty?
        erb :booknew
    else
        @id = id
        @results = connect.exec("SELECT * FROM books where userid=#{@id};")
        erb :index
    end
end

post '/book' do   # 登録完了ページ
    @title = params[:title]
    @author = params[:author]
    @publisher = params[:publisher]
    @error = true unless connect.exec("INSERT INTO books (userid, title, author, publisher) VALUES (#{id.to_i}, '#{@title}', '#{@author}', '#{@publisher}');")
    erb :book
end

def find_id(connect, userid)
    results = connect.exec("SELECT * FROM userindex;")
    return reply_id(connect, results, userid)
end

def reply_id(connect, results, userid)   # useridに対応するidを返す.なければ作る
    results.each do |result|
        if result['userid'] == userid
            return result['id']
        end
    end
    connect.exec("INSERT INTO userindex (userid) VALUES ('#{userid}');")
    return find_id(connect, userid)
end

def find_books(connect, id)
    results = connect.exec("SELECT * FROM books where userid=#{id};")
    books = []
    results.each do |result|
        books << {"id"=>result['id'], "title"=>result['title']}
    end
    return books
end

def delete(connect, book_id)
    results = connect.exec("delete from books where id=#{book_id.to_i};")
end

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
                no_book = {
                    type: 'text',
                    text: "まだ本が登録されていないか、該当する本がありません"
                }
                if event.message['text'] == "new"   # 新規登録
                    client.reply_message(event['replyToken'], form)
                else
                    books = find_books(connect, id)
                    if books.empty?    # 本棚が空のとき
                        client.reply_message(event['replyToken'], no_book)
                    end
                    if event.message['text'] == "index"  # 蔵書一覧
                        book_title = []
                        books.each do |x|
                            book_title << "・#{x['title']}"
                        end
                        message = {
                            type: 'text',
                            text: book_title.join("\n")
                        }
                        client.reply_message(event['replyToken'], [message, show_books])
                    elsif event.message['text'] =~ /^[0-9]$/  # 削除ID
                        book_id = ""
                        title = ""
                        books.each do |x|
                            if x['id'] == event.message['text']
                                book_id = x['id']
                                title = x['title']
                            end
                        end
                        if book_id.empty?  # idが見つからなかった場合
                            client.reply_message(event['replyToken'], no_book)
                        else    # 削除ボタン
                            client.reply_message(event['replyToken'], delete_book(title, book_id))
                        end
                    else   # 文字列(タイトルとして検索)
                        inp_title = event.message['text']
                        book_info = []
                        book_title = []
                        book_id = []
                        count = 0
                        books.each do |x|
                            p [x['title'].ord, inp_title.ord]
                            if x['title'] =~ /#{inp_title}/
                                book_title << x['title']
                                book_id << x['id']
                                book_info << "・ID #{x['id']}：#{x['title']}"
                                count += 1
                            end
                        end
                        if count == 0
                            message = {
                                type: 'text',
                                text: "「#{inp_title}」という本は見つかりませんでした"
                            }
                            client.reply_message(event['replyToken'], message)
                        elsif count == 1
                            client.reply_message(event['replyToken'], delete(book_id[0]))
                        else
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