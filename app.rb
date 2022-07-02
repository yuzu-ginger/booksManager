require 'bundler/setup'
require 'sinatra'
require 'line/bot'
require 'pg'
require_relative 'button'

userid = ""
connect = PG::connect(
    host: ENV["PSQL_HOST"],
    user: ENV["PSQL_USER"],
    password: ENV["PSQL_PASS"],
    dbname: ENV["PSQL_DBNAME"],
    port: "5432"
)

get '/' do   # 登録form
    params[:id] = @env["QUERY_STRING"].match(/2F/).post_match.to_i
    userid = params[:id]
    erb :booknew
end

post '/book' do   # 登録完了ページ
    @title = params[:title]
    @author = params[:author]
    @publisher = params[:publisher]
    @error = true unless connect.exec("INSERT INTO books (userid, title, author, publisher) VALUES (#{userid.to_i}, '#{@title}', '#{@author}', '#{@publisher}');")
    erb :book
end

def find_id(connect, userid)
    results = connect.exec("SELECT * FROM userindex")
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

def find_books(connect, userid)
    results = connect.exec("SELECT * FROM books")
    books = []
    results.each do |result|
        if result['userid'] == userid
            books << "・#{result['title']}"
        end
    end
    return books == [] ? "登録された本はありません" : books
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
                if event.message['text'] == "新規登録"
                    client.reply_message(event['replyToken'], form(id))
                elsif event.message['text'] == "一覧"
                    books = find_books(connect, userid)
                    message = {
                        type: "text",
                        text: books.join("\n")
                    }
                    client.reply_message(event['replyToken'], message)
                end
            end
        end
    end
  
    "OK"
end