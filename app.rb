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
                if event.message['text'] == "new"
                    client.reply_message(event['replyToken'], form)
                elsif event.message['text'] == "index"
                    books = find_books(connect, id)
                    if books.empty?
                        text = "登録された本はありません"
                    else
                        text = []
                        books.each do |x|
                            text << x['title']
                        end
                        text.join("\n")
                    end
                    p text
                    message = {
                        type: "text",
                        text: text
                    }
                    client.reply_message(event['replyToken'], [message, show_books])
                else
                    inp_title = event.message['text']
                    books = find_books(connect, id)
                end
            end
        end
    end
  
    "OK"
end