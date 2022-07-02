require 'bundler/setup'
require 'sinatra'
require 'line/bot'
require 'pg'
require_relative 'button'

get '^/?liff.state=%2F' do
    # @userid=params[:id]
    erb :index
end

post '/book' do
    @title = params[:title]
    @author = params[:author]
    @body = params[:body]
    erb :book
end

def find_id(userid)
    connect = PG::connect(
        host: ENV["PSQL_HOST"],
        user: ENV["PSQL_USER"],
        password: ENV["PSQL_PASS"],
        dbname: ENV["PSQL_DBNAME"],
        port: "5432"
    )
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
    return find_id(userid)
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
        id = find_id(userid)
        case event
        when Line::Bot::Event::Message
            case event.type
            when Line::Bot::Event::MessageType::Text
                if event.message['text'] == "新規登録"
                    client.reply_message(event['replyToken'], form(id.to_s))
                end
            end
        end
    end
  
    "OK"
end